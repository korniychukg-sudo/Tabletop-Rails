import SwiftUI

enum Dir4: Int, Codable, CaseIterable {
    case n = 0, e = 1, s = 2, w = 3

    var opposite: Dir4 { Dir4(rawValue: (rawValue + 2) % 4) ?? .n }
    var offset: (dx: Int, dy: Int) {
        switch self {
        case .n: return (0, -1)
        case .e: return (1, 0)
        case .s: return (0, 1)
        case .w: return (-1, 0)
        }
    }
    var mid: CGPoint {
        switch self {
        case .n: return CGPoint(x: 0.5, y: 0)
        case .e: return CGPoint(x: 1, y: 0.5)
        case .s: return CGPoint(x: 0.5, y: 1)
        case .w: return CGPoint(x: 0, y: 0.5)
        }
    }
    func rotated(_ by: Int) -> Dir4 { Dir4(rawValue: ((rawValue + by) % 4 + 4) % 4) ?? .n }
}

struct GridPoint: Hashable, Codable {
    var x: Int
    var y: Int
    func neighbor(_ d: Dir4) -> GridPoint { GridPoint(x: x + d.offset.dx, y: y + d.offset.dy) }
}

enum TrackKind: String, Codable, CaseIterable {
    case straight, curve, switchRight, switchLeft, cross, buffer, station, bridge

    var displayName: String {
        switch self {
        case .straight: return "Straight"
        case .curve: return "Curve"
        case .switchRight: return "Switch R"
        case .switchLeft: return "Switch L"
        case .cross: return "Crossing"
        case .buffer: return "Buffer Stop"
        case .station: return "Station"
        case .bridge: return "Bridge"
        }
    }
    var rotations: Int {
        switch self {
        case .straight, .bridge: return 2
        case .cross: return 1
        default: return 4
        }
    }
}

struct PlacedTrack: Codable, Equatable {
    var kind: TrackKind
    var rot: Int
    var toBranch: Bool = false
}

struct TrackGeometry {
    static func connections(_ piece: PlacedTrack) -> [(Dir4, Dir4)] {
        let r = piece.rot
        switch piece.kind {
        case .straight, .bridge:
            return [(Dir4.n.rotated(r), Dir4.s.rotated(r))]
        case .station:
            return [(Dir4.n.rotated(r), Dir4.s.rotated(r))]
        case .curve:
            return [(Dir4.n.rotated(r), Dir4.e.rotated(r))]
        case .switchRight:
            return [(Dir4.s.rotated(r), Dir4.n.rotated(r)), (Dir4.s.rotated(r), Dir4.e.rotated(r))]
        case .switchLeft:
            return [(Dir4.s.rotated(r), Dir4.n.rotated(r)), (Dir4.s.rotated(r), Dir4.w.rotated(r))]
        case .cross:
            return [(.n, .s), (.e, .w)]
        case .buffer:
            return []
        }
    }

    static func bufferOpenEdge(_ piece: PlacedTrack) -> Dir4 { Dir4.s.rotated(piece.rot) }

    static func switchRoot(_ piece: PlacedTrack) -> Dir4? {
        switch piece.kind {
        case .switchRight, .switchLeft: return Dir4.s.rotated(piece.rot)
        default: return nil
        }
    }

    static func exits(from entry: Dir4, piece: PlacedTrack) -> [Dir4] {
        if piece.kind == .buffer {
            return []
        }
        var result: [Dir4] = []
        for (a, b) in connections(piece) {
            if a == entry { result.append(b) }
            if b == entry { result.append(a) }
        }
        return result
    }

    static func exit(from entry: Dir4, piece: PlacedTrack) -> Dir4? {
        let all = exits(from: entry, piece: piece)
        if all.isEmpty { return nil }
        if all.count == 1 { return all[0] }
        if let root = switchRoot(piece), entry == root {
            let r = piece.rot
            let straightExit = Dir4.n.rotated(r)
            let branchExit: Dir4 = piece.kind == .switchRight ? Dir4.e.rotated(r) : Dir4.w.rotated(r)
            return piece.toBranch ? branchExit : straightExit
        }
        return all[0]
    }

    static func hasEdge(_ piece: PlacedTrack, _ edge: Dir4) -> Bool {
        if piece.kind == .buffer { return bufferOpenEdge(piece) == edge }
        for (a, b) in connections(piece) where a == edge || b == edge { return true }
        return false
    }

    static func segmentLength(from: Dir4, to: Dir4?) -> CGFloat {
        guard let to = to else { return 0.5 }
        if to == from.opposite { return 1.0 }
        return .pi / 4
    }

    static func point(from: Dir4, to: Dir4?, t: CGFloat) -> CGPoint {
        let a = from.mid
        guard let to = to else {
            let c = CGPoint(x: 0.5, y: 0.5)
            return CGPoint(x: a.x + (c.x - a.x) * t, y: a.y + (c.y - a.y) * t)
        }
        let b = to.mid
        if to == from.opposite {
            return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        let corner = sharedCorner(from, to)
        let a0 = atan2(a.y - corner.y, a.x - corner.x)
        var a1 = atan2(b.y - corner.y, b.x - corner.x)
        while a1 - a0 > .pi { a1 -= 2 * .pi }
        while a0 - a1 > .pi { a1 += 2 * .pi }
        let ang = a0 + (a1 - a0) * t
        return CGPoint(x: corner.x + 0.5 * cos(ang), y: corner.y + 0.5 * sin(ang))
    }

    static func tangent(from: Dir4, to: Dir4?, t: CGFloat) -> CGFloat {
        let a = from.mid
        guard let to = to else {
            let c = CGPoint(x: 0.5, y: 0.5)
            return atan2(c.y - a.y, c.x - a.x)
        }
        let b = to.mid
        if to == from.opposite {
            return atan2(b.y - a.y, b.x - a.x)
        }
        let corner = sharedCorner(from, to)
        let a0 = atan2(a.y - corner.y, a.x - corner.x)
        var a1 = atan2(b.y - corner.y, b.x - corner.x)
        while a1 - a0 > .pi { a1 -= 2 * .pi }
        while a0 - a1 > .pi { a1 += 2 * .pi }
        let ang = a0 + (a1 - a0) * t
        let sign: CGFloat = a1 > a0 ? 1 : -1
        return ang + sign * .pi / 2
    }

    static func sharedCorner(_ a: Dir4, _ b: Dir4) -> CGPoint {
        let set: Set<Dir4> = [a, b]
        if set == [.n, .e] { return CGPoint(x: 1, y: 0) }
        if set == [.e, .s] { return CGPoint(x: 1, y: 1) }
        if set == [.s, .w] { return CGPoint(x: 0, y: 1) }
        if set == [.w, .n] { return CGPoint(x: 0, y: 0) }
        return CGPoint(x: 0.5, y: 0.5)
    }

    static func pathSegments(_ piece: PlacedTrack) -> [(Dir4, Dir4?)] {
        if piece.kind == .buffer { return [(bufferOpenEdge(piece), nil)] }
        return connections(piece).map { ($0.0, Optional($0.1)) }
    }
}

enum SceneryKind: String, Codable, CaseIterable {
    case pine, oakTree, poplar, bush, house, barn, stationHouse, windmill, waterTower, pond, rockOutcrop, fence, lampPost, signalPost, flowerBed, sheepPen, watchtower, cargoShed

    var displayName: String {
        switch self {
        case .pine: return "Pine Tree"
        case .oakTree: return "Oak Tree"
        case .poplar: return "Poplar"
        case .bush: return "Hedge Bush"
        case .house: return "Cottage"
        case .barn: return "Red Barn"
        case .stationHouse: return "Station House"
        case .windmill: return "Windmill"
        case .waterTower: return "Water Tower"
        case .pond: return "Pond"
        case .rockOutcrop: return "Rocks"
        case .fence: return "Fence Run"
        case .lampPost: return "Lamp Post"
        case .signalPost: return "Signal Post"
        case .flowerBed: return "Flower Bed"
        case .sheepPen: return "Sheep Pen"
        case .watchtower: return "Watchtower"
        case .cargoShed: return "Cargo Shed"
        }
    }
    var unlockRank: Int {
        switch self {
        case .pine, .oakTree, .bush, .house, .fence: return 0
        case .poplar, .flowerBed, .lampPost, .pond: return 1
        case .barn, .stationHouse, .signalPost: return 2
        case .waterTower, .sheepPen: return 3
        case .windmill, .rockOutcrop: return 4
        case .cargoShed, .watchtower: return 5
        }
    }
}

struct PlacedScenery: Codable, Equatable {
    var kind: SceneryKind
    var variant: Int
}

struct TrainSetup: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var locoID: String
    var wagonIDs: [String]
    var throttle: Double = 0.55
    var stopsAtStations: Bool = true
}

struct RailLayout: Codable, Equatable {
    var name: String
    var cols: Int
    var rows: Int
    var track: [GridPoint: PlacedTrack]
    var scenery: [GridPoint: PlacedScenery]
    var trains: [TrainSetup]

    init(name: String, cols: Int = 12, rows: Int = 14) {
        self.name = name
        self.cols = cols
        self.rows = rows
        self.track = [:]
        self.scenery = [:]
        self.trains = []
    }

    func inBounds(_ p: GridPoint) -> Bool { p.x >= 0 && p.y >= 0 && p.x < cols && p.y < rows }

    var trackCount: Int { track.count }

    func count(of kind: TrackKind) -> Int { track.values.filter { $0.kind == kind }.count }

    func sceneryCount(of kind: SceneryKind) -> Int { scenery.values.filter { $0.kind == kind }.count }

    var stationCells: [GridPoint] { track.filter { $0.value.kind == .station }.map { $0.key }.sorted { ($0.y, $0.x) < ($1.y, $1.x) } }

    var hasClosedLoop: Bool {
        for (cell, piece) in track {
            guard piece.kind == .straight || piece.kind == .curve || piece.kind == .station || piece.kind == .bridge else { continue }
            guard let firstConn = TrackGeometry.connections(piece).first else { continue }
            var currentCell = cell
            var entry = firstConn.0
            var steps = 0
            while steps < 600 {
                steps += 1
                guard let piece = track[currentCell] else { break }
                var exitDir: Dir4?
                if piece.kind == .switchRight || piece.kind == .switchLeft {
                    var straightPiece = piece
                    straightPiece.toBranch = false
                    exitDir = TrackGeometry.exit(from: entry, piece: straightPiece)
                } else {
                    exitDir = TrackGeometry.exit(from: entry, piece: piece)
                }
                guard let exit = exitDir else { break }
                let next = currentCell.neighbor(exit)
                guard let nextPiece = track[next], TrackGeometry.hasEdge(nextPiece, exit.opposite) else { break }
                currentCell = next
                entry = exit.opposite
                if currentCell == cell && entry == firstConn.0 { return true }
            }
        }
        return false
    }

    var connectedTrackCells: Int {
        guard let start = track.keys.first else { return 0 }
        var seen: Set<GridPoint> = [start]
        var queue: [GridPoint] = [start]
        while let cell = queue.popLast() {
            guard let piece = track[cell] else { continue }
            for d in Dir4.allCases where TrackGeometry.hasEdge(piece, d) {
                let nb = cell.neighbor(d)
                if !seen.contains(nb), let np = track[nb], TrackGeometry.hasEdge(np, d.opposite) {
                    seen.insert(nb)
                    queue.append(nb)
                }
            }
        }
        return seen.count
    }
}

extension RailLayout {
    static func starter() -> RailLayout {
        var l = RailLayout(name: "Maple Junction", cols: 12, rows: 14)
        let left = 2, right = 9, top = 2, bottom = 9
        for x in (left + 1)..<right {
            l.track[GridPoint(x: x, y: top)] = PlacedTrack(kind: .straight, rot: 1)
            l.track[GridPoint(x: x, y: bottom)] = PlacedTrack(kind: x == 5 ? .station : .straight, rot: x == 5 ? 3 : 1)
        }
        for y in (top + 1)..<bottom {
            l.track[GridPoint(x: left, y: y)] = PlacedTrack(kind: .straight, rot: 0)
            l.track[GridPoint(x: right, y: y)] = PlacedTrack(kind: .straight, rot: 0)
        }
        l.track[GridPoint(x: left, y: top)] = PlacedTrack(kind: .curve, rot: 1)
        l.track[GridPoint(x: right, y: top)] = PlacedTrack(kind: .curve, rot: 2)
        l.track[GridPoint(x: right, y: bottom)] = PlacedTrack(kind: .curve, rot: 3)
        l.track[GridPoint(x: left, y: bottom)] = PlacedTrack(kind: .curve, rot: 0)
        l.track[GridPoint(x: 7, y: bottom)] = PlacedTrack(kind: .switchRight, rot: 1)
        l.track[GridPoint(x: 7, y: bottom + 1)] = PlacedTrack(kind: .curve, rot: 0)
        l.track[GridPoint(x: 8, y: bottom + 1)] = PlacedTrack(kind: .straight, rot: 1)
        l.track[GridPoint(x: 9, y: bottom + 1)] = PlacedTrack(kind: .buffer, rot: 3)
        l.scenery[GridPoint(x: 4, y: 4)] = PlacedScenery(kind: .house, variant: 0)
        l.scenery[GridPoint(x: 6, y: 5)] = PlacedScenery(kind: .pine, variant: 1)
        l.scenery[GridPoint(x: 7, y: 4)] = PlacedScenery(kind: .oakTree, variant: 0)
        l.scenery[GridPoint(x: 3, y: 6)] = PlacedScenery(kind: .bush, variant: 0)
        l.scenery[GridPoint(x: 5, y: 10)] = PlacedScenery(kind: .pine, variant: 2)
        l.scenery[GridPoint(x: 1, y: 1)] = PlacedScenery(kind: .pine, variant: 0)
        l.scenery[GridPoint(x: 10, y: 12)] = PlacedScenery(kind: .oakTree, variant: 1)
        l.scenery[GridPoint(x: 2, y: 11)] = PlacedScenery(kind: .fence, variant: 0)
        l.trains = [TrainSetup(locoID: "pip", wagonIDs: ["coach_cherry", "coach_cherry"], throttle: 0.5, stopsAtStations: true)]
        return l
    }
}
