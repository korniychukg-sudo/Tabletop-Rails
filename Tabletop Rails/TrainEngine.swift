import SwiftUI
import Combine

struct VehiclePos: Equatable {
    var cell: GridPoint
    var from: Dir4
    var to: Dir4?
    var t: CGFloat

    var segLen: CGFloat { TrackGeometry.segmentLength(from: from, to: to) }
    var tablePoint: CGPoint {
        let local = TrackGeometry.point(from: from, to: to, t: t)
        return CGPoint(x: CGFloat(cell.x) + local.x, y: CGFloat(cell.y) + local.y)
    }
    var heading: CGFloat { TrackGeometry.tangent(from: from, to: to, t: t) }
    var reversed: VehiclePos {
        if let to = to {
            return VehiclePos(cell: cell, from: to, to: from, t: 1 - t)
        }
        return VehiclePos(cell: cell, from: from, to: nil, t: t)
    }
}

enum TrainState: Equatable {
    case running
    case dwelling(Double)
    case held
    case buffered
    case blocked
}

struct SmokePuff: Identifiable {
    let id = UUID()
    var pos: CGPoint
    var vel: CGVector
    var age: Double
    var life: Double
    var size: CGFloat
    var dark: Bool
}

struct BumpFlash: Identifiable {
    let id = UUID()
    var pos: CGPoint
    var age: Double
}

struct RouteKey: Hashable {
    var cell: GridPoint
    var entry: Dir4
}

final class RunTrain: Identifiable, ObservableObject {
    let id: UUID
    var setup: TrainSetup
    var vehicles: [VehiclePos]
    var state: TrainState = .running
    var lastStationCell: GridPoint?
    var routeMemory: [RouteKey: Dir4] = [:]
    var smokeAccumulator: Double = 0
    var reversedDirection = false

    init(setup: TrainSetup, vehicles: [VehiclePos]) {
        self.id = setup.id
        self.setup = setup
        self.vehicles = vehicles
    }

    var loco: Locomotive { RailContent.locomotive(setup.locoID) }
    var speed: CGFloat { CGFloat(setup.throttle) * loco.maxSpeed }
}

final class RailRunEngine: ObservableObject {
    @Published var trains: [RunTrain] = []
    @Published var smoke: [SmokePuff] = []
    @Published var bumps: [BumpFlash] = []
    @Published var tableMinutes: Double = 8 * 60
    @Published var isRunning = false
    @Published var totalDistance: CGFloat = 0
    @Published var stationStops: Int = 0
    @Published var runSeconds: Double = 0
    @Published var lapEvents: Int = 0

    var layout: RailLayout = RailLayout(name: "")
    private var timer: AnyCancellable?
    private var lastTick: Date?
    var onStats: ((RunStatsDelta) -> Void)?

    struct RunStatsDelta {
        var distance: CGFloat = 0
        var stops: Int = 0
        var seconds: Double = 0
        var bumps: Int = 0
        var trainsRunning: Int = 0
        var wagonDistance: CGFloat = 0
    }

    func start(layout: RailLayout) {
        self.layout = layout
        spawnTrains()
        isRunning = true
        lastTick = nil
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.tick(now: now)
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        trains = []
        smoke = []
        bumps = []
    }

    func toggleSwitch(at cell: GridPoint) {
        guard var piece = layout.track[cell], piece.kind == .switchRight || piece.kind == .switchLeft else { return }
        piece.toBranch.toggle()
        layout.track[cell] = piece
        RailHaptics.tap()
        objectWillChange.send()
    }

    func resume(_ train: RunTrain) {
        if train.state == .held || train.state == .blocked {
            train.state = .running
            objectWillChange.send()
        }
    }

    func reverse(_ train: RunTrain) {
        train.vehicles = train.vehicles.reversed().map { $0.reversed }
        train.routeMemory.removeAll()
        train.reversedDirection.toggle()
        if train.state == .buffered || train.state == .blocked { train.state = .running }
        objectWillChange.send()
    }

    func setThrottle(_ train: RunTrain, _ value: Double) {
        train.setup.throttle = value
        objectWillChange.send()
    }

    private func spawnTrains() {
        trains = []
        var usedCells: Set<GridPoint> = []
        for setup in layout.trains {
            if let train = spawn(setup: setup, avoiding: usedCells) {
                for v in train.vehicles { usedCells.insert(v.cell) }
                trains.append(train)
            }
        }
    }

    private func spawn(setup: TrainSetup, avoiding: Set<GridPoint>) -> RunTrain? {
        let candidates = spawnCandidates(avoiding: avoiding)
        guard let (cell, piece) = candidates.first else { return nil }
        guard let conn = TrackGeometry.connections(piece).first else { return nil }
        let head = VehiclePos(cell: cell, from: conn.0, to: conn.1, t: 0.55)
        var vehicles: [VehiclePos] = [head]
        let count = 1 + setup.wagonIDs.count
        var walker = head
        for _ in 1..<max(1, count) {
            guard let prev = retreat(walker, by: RailContent.vehicleSpacing) else { break }
            vehicles.append(prev)
            walker = prev
        }
        return RunTrain(setup: setup, vehicles: vehicles)
    }

    private func spawnCandidates(avoiding: Set<GridPoint>) -> [(GridPoint, PlacedTrack)] {
        var stations: [(GridPoint, PlacedTrack)] = []
        var straights: [(GridPoint, PlacedTrack)] = []
        var others: [(GridPoint, PlacedTrack)] = []
        for (cell, piece) in layout.track.sorted(by: { ($0.key.y, $0.key.x) < ($1.key.y, $1.key.x) }) {
            guard !avoiding.contains(cell) else { continue }
            switch piece.kind {
            case .station: stations.append((cell, piece))
            case .straight, .bridge: straights.append((cell, piece))
            case .curve: others.append((cell, piece))
            default: break
            }
        }
        return stations + straights + others
    }

    private func retreat(_ pos: VehiclePos, by distance: CGFloat) -> VehiclePos? {
        var flipped = pos.reversed
        guard advanceRaw(&flipped, by: distance, memory: nil, recordInto: nil) else { return nil }
        return flipped.reversed
    }

    private func advanceRaw(_ pos: inout VehiclePos, by distance: CGFloat, memory: [RouteKey: Dir4]?, recordInto: RunTrain?) -> Bool {
        var remaining = distance
        var guardCount = 0
        while remaining > 0 && guardCount < 64 {
            guardCount += 1
            let len = pos.segLen
            let distLeft = (1 - pos.t) * len
            if remaining < distLeft {
                pos.t += remaining / len
                return true
            }
            remaining -= distLeft
            guard let exitDir = pos.to else { return false }
            let nextCell = pos.cell.neighbor(exitDir)
            let entry = exitDir.opposite
            guard let nextPiece = layout.track[nextCell], TrackGeometry.hasEdge(nextPiece, entry) else { return false }
            var chosen: Dir4?
            if nextPiece.kind == .buffer {
                chosen = nil
            } else if let mem = memory, let remembered = mem[RouteKey(cell: nextCell, entry: entry)] {
                chosen = remembered
            } else {
                chosen = TrackGeometry.exit(from: entry, piece: nextPiece)
            }
            if nextPiece.kind == .buffer {
                pos = VehiclePos(cell: nextCell, from: entry, to: nil, t: 0)
            } else {
                guard let exit = chosen else { return false }
                if let train = recordInto {
                    train.routeMemory[RouteKey(cell: nextCell, entry: entry)] = exit
                    if train.routeMemory.count > 128 { train.routeMemory.removeValue(forKey: train.routeMemory.keys.first!) }
                }
                pos = VehiclePos(cell: nextCell, from: entry, to: exit, t: 0)
            }
        }
        return guardCount < 64
    }

    private func tick(now: Date) {
        let dt: Double
        if let last = lastTick { dt = min(0.1, now.timeIntervalSince(last)) } else { dt = 1.0 / 30.0 }
        lastTick = now
        var delta = RunStatsDelta()
        tableMinutes += dt * 60
        if tableMinutes >= 24 * 60 { tableMinutes -= 24 * 60 }
        delta.seconds = dt
        runSeconds += dt

        for train in trains {
            switch train.state {
            case .dwelling(let remain):
                let left = remain - dt
                if left <= 0 {
                    train.state = .running
                } else {
                    train.state = .dwelling(left)
                }
                continue
            case .held, .buffered, .blocked:
                continue
            case .running:
                break
            }
            let ds = train.speed * CGFloat(dt)
            guard ds > 0 else { continue }
            let beforeCell = train.vehicles.first?.cell
            var moved = true
            for i in train.vehicles.indices {
                var v = train.vehicles[i]
                let useMemory = i > 0 ? train.routeMemory : nil
                let record = i == 0 ? train : nil
                if advanceRaw(&v, by: ds, memory: useMemory, recordInto: record) {
                    train.vehicles[i] = v
                } else {
                    train.vehicles[i] = v
                    if i == 0 {
                        train.state = v.to == nil ? .buffered : .blocked
                        moved = false
                    }
                }
            }
            if moved {
                totalDistance += ds
                delta.distance += ds
                delta.wagonDistance += ds * CGFloat(train.setup.wagonIDs.count)
                delta.trainsRunning += 1
            }
            if let head = train.vehicles.first {
                if head.cell != beforeCell, let lastStation = train.lastStationCell, head.cell != lastStation {
                    train.lastStationCell = nil
                }
                if let piece = layout.track[head.cell], piece.kind == .station, train.setup.stopsAtStations, train.lastStationCell != head.cell, head.t >= 0.45, train.state == .running {
                    train.state = .dwelling(4.0)
                    train.lastStationCell = head.cell
                    stationStops += 1
                    delta.stops += 1
                    RailHaptics.tap()
                }
            }
            emitSmoke(train, dt: dt)
        }

        checkCollisions(&delta)
        updateSmoke(dt: dt)
        updateBumps(dt: dt)
        onStats?(delta)
        objectWillChange.send()
    }

    private func checkCollisions(_ delta: inout RunStatsDelta) {
        guard trains.count > 1 else { return }
        for i in 0..<trains.count {
            let a = trains[i]
            guard a.state == .running, let headA = a.vehicles.first else { continue }
            let pa = headA.tablePoint
            for j in 0..<trains.count where j != i {
                let b = trains[j]
                for v in b.vehicles {
                    let pb = v.tablePoint
                    let dx = pa.x - pb.x
                    let dy = pa.y - pb.y
                    if dx * dx + dy * dy < 0.42 * 0.42 {
                        a.state = .held
                        if b.state == .running { b.state = .held }
                        bumps.append(BumpFlash(pos: CGPoint(x: (pa.x + pb.x) / 2, y: (pa.y + pb.y) / 2), age: 0))
                        delta.bumps += 1
                        RailHaptics.warning()
                        break
                    }
                }
                if a.state != .running { break }
            }
        }
    }

    private func emitSmoke(_ train: RunTrain, dt: Double) {
        let loco = train.loco
        guard loco.smoke != .none, let head = train.vehicles.first else { return }
        let interval = loco.smoke == .steam ? 0.10 : 0.26
        train.smokeAccumulator += dt
        guard train.smokeAccumulator >= interval else { return }
        train.smokeAccumulator = 0
        guard smoke.count < 140 else { return }
        let p = head.tablePoint
        let ang = head.heading
        let chimneyOffset: CGFloat = 0.16
        let pos = CGPoint(x: p.x + cos(ang) * chimneyOffset, y: p.y + sin(ang) * chimneyOffset)
        var rng = SeededRandom(seed: UInt64(abs(pos.x * 1000 + pos.y * 7000)) &+ UInt64(smoke.count))
        smoke.append(SmokePuff(
            pos: pos,
            vel: CGVector(dx: (rng.next() - 0.5) * 0.14, dy: -0.24 - rng.next() * 0.16),
            age: 0,
            life: 1.1 + Double(rng.next()) * 0.8,
            size: 0.06 + rng.next() * 0.05,
            dark: loco.smoke == .diesel))
    }

    private func updateSmoke(dt: Double) {
        for i in smoke.indices {
            smoke[i].age += dt
            smoke[i].pos.x += smoke[i].vel.dx * CGFloat(dt)
            smoke[i].pos.y += smoke[i].vel.dy * CGFloat(dt)
            smoke[i].size += CGFloat(dt) * 0.05
        }
        smoke.removeAll { $0.age >= $0.life }
    }

    private func updateBumps(dt: Double) {
        for i in bumps.indices { bumps[i].age += dt }
        bumps.removeAll { $0.age > 0.8 }
    }

    var tableClockText: String {
        let total = Int(tableMinutes)
        let h = (total / 60) % 24
        let m = total % 60
        return String(format: "%02d:%02d", h, m)
    }

    var runningCount: Int {
        trains.filter { $0.state == .running }.count
    }
}
