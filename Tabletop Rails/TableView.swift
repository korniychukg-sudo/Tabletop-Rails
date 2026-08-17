import SwiftUI

enum BuildTool: Equatable {
    case track(TrackKind)
    case scenery(SceneryKind)
    case erase
}

struct TableView: View {
    @EnvironmentObject var store: RailStore
    @StateObject private var engine = RailRunEngine()
    @State private var running = false
    @State private var tool: BuildTool = .track(.straight)
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var dragStart: CGSize?
    @State private var showTrains = false
    @State private var showBoards = false
    @State private var showSceneryPicker = false
    @State private var selectedTrainID: UUID?
    @State private var phaseStart = Date()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                WoodBackdrop()
                TimelineView(.animation(minimumInterval: store.reduceMotion ? 0.5 : 1.0 / 30.0)) { timeline in
                    let phase = timeline.date.timeIntervalSince(phaseStart)
                    tableCanvas(geo: geo.size, phase: phase)
                }
                .clipped()
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    if running {
                        runControls
                    } else {
                        buildPalette
                    }
                }
                if let text = store.celebration {
                    CelebrationBanner(text: text) {
                        withAnimation { store.celebration = nil }
                    }
                    .zIndex(3)
                }
            }
        }
        .sheet(isPresented: $showTrains) {
            TrainsSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showBoards) {
            BoardsSheet()
                .environmentObject(store)
        }
        .sheet(item: selectedTrainBinding) { box in
            TrainControlSheet(engine: engine, trainID: box.id)
                .environmentObject(store)
        }
        .onDisappear { stopRun() }
    }

    private struct TrainBox: Identifiable {
        let id: UUID
    }

    private var selectedTrainBinding: Binding<TrainBox?> {
        Binding(
            get: { selectedTrainID.map { TrainBox(id: $0) } },
            set: { selectedTrainID = $0?.id })
    }

    private func tableCanvas(geo: CGSize, phase: Double) -> some View {
        let layout = running ? engine.layout : store.layout
        let cs = cellSize(geo: geo, layout: layout)
        let night = store.nightFactor
        return Canvas { ctx, size in
            let origin = tableOrigin(geo: size, layout: layout, cs: cs)
            ctx.translateBy(x: origin.x, y: origin.y)
            let artist = TrackArtist(layout: layout, cellSize: cs, buildMode: !running, selectedCell: nil, phase: phase, night: night)
            artist.drawFrame(&ctx)
            artist.drawTable(&ctx, size: size)
            artist.drawTrack(&ctx)
            artist.drawScenery(&ctx, engineTrains: running ? engine.trains : [])
            if running {
                artist.drawTrains(&ctx, engine: engine)
                artist.drawEffects(&ctx, engine: engine)
            }
            artist.drawNight(&ctx, size: size)
        }
        .gesture(tableGesture(geo: geo, layout: layout, cs: cs))
    }

    private func cellSize(geo: CGSize, layout: RailLayout) -> CGFloat {
        let fitW = geo.width / (CGFloat(layout.cols) + 1.6)
        let fitH = geo.height / (CGFloat(layout.rows) + 3.4)
        return min(fitW, fitH) * scale
    }

    private func tableOrigin(geo: CGSize, layout: RailLayout, cs: CGFloat) -> CGPoint {
        CGPoint(
            x: (geo.width - CGFloat(layout.cols) * cs) / 2 + offset.width,
            y: (geo.height - CGFloat(layout.rows) * cs) / 2 + offset.height)
    }

    private func tableGesture(geo: CGSize, layout: RailLayout, cs: CGFloat) -> some Gesture {
        let drag = DragGesture(minimumDistance: 0)
            .onChanged { value in
                let dist = hypot(value.translation.width, value.translation.height)
                if dist > 10 {
                    if dragStart == nil { dragStart = offset }
                    if let start = dragStart {
                        offset = CGSize(width: start.width + value.translation.width, height: start.height + value.translation.height)
                    }
                }
            }
            .onEnded { value in
                let dist = hypot(value.translation.width, value.translation.height)
                if dragStart == nil && dist <= 10 {
                    handleTap(at: value.location, geo: geo, layout: layout, cs: cs)
                }
                dragStart = nil
            }
        let zoom = MagnificationGesture()
            .onChanged { value in
                scale = (baseScale * value).clamped(0.6, 2.6)
            }
            .onEnded { _ in
                baseScale = scale
            }
        return drag.simultaneously(with: zoom)
    }

    private func handleTap(at point: CGPoint, geo: CGSize, layout: RailLayout, cs: CGFloat) {
        let origin = tableOrigin(geo: geo, layout: layout, cs: cs)
        let local = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        let cell = GridPoint(x: Int(floor(local.x / cs)), y: Int(floor(local.y / cs)))
        guard layout.inBounds(cell) else { return }
        if running {
            handleRunTap(cell: cell, local: local, cs: cs)
        } else {
            handleBuildTap(cell: cell)
        }
    }

    private func handleRunTap(cell: GridPoint, local: CGPoint, cs: CGFloat) {
        for train in engine.trains {
            if let head = train.vehicles.first {
                let p = head.tablePoint
                let d = hypot(p.x * cs - local.x, p.y * cs - local.y)
                if d < cs * 0.55 {
                    selectedTrainID = train.id
                    return
                }
            }
        }
        if let piece = engine.layout.track[cell], piece.kind == .switchRight || piece.kind == .switchLeft {
            engine.toggleSwitch(at: cell)
        }
    }

    private func handleBuildTap(cell: GridPoint) {
        var layout = store.layout
        switch tool {
        case .erase:
            if layout.track[cell] != nil {
                layout.track[cell] = nil
                RailHaptics.tap()
            } else if layout.scenery[cell] != nil {
                layout.scenery[cell] = nil
                RailHaptics.tap()
            }
        case .track(let kind):
            if var existing = layout.track[cell], existing.kind == kind {
                existing.rot = (existing.rot + 1) % kind.rotations
                layout.track[cell] = existing
                RailHaptics.tap()
            } else {
                layout.scenery[cell] = nil
                layout.track[cell] = PlacedTrack(kind: kind, rot: kind == .station ? 1 : (kind == .straight ? 1 : 0))
                store.recordPiecePlaced()
                RailHaptics.place()
            }
        case .scenery(let kind):
            if layout.track[cell] != nil {
                RailHaptics.warning()
                return
            }
            if var existing = layout.scenery[cell], existing.kind == kind {
                existing.variant = (existing.variant + 1) % 4
                layout.scenery[cell] = existing
                RailHaptics.tap()
            } else {
                layout.scenery[cell] = PlacedScenery(kind: kind, variant: 0)
                store.recordSceneryPlaced(kind)
                RailHaptics.place()
            }
        }
        store.layout = layout
        store.checkAwards()
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                guard !running else { return }
                showBoards = true
            } label: {
                HStack(spacing: 6) {
                    RIcon(kind: .table, size: 16, color: RailTheme.cream)
                    Text(store.layout.name)
                        .font(RailTheme.heading(14))
                        .foregroundColor(RailTheme.cream)
                        .lineLimit(1)
                    if !running {
                        RIcon(kind: .chevronDown, size: 11, color: RailTheme.cream.opacity(0.7))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.35)))
            }
            Spacer()
            if running {
                HStack(spacing: 5) {
                    RIcon(kind: .clock, size: 13, color: RailTheme.brassLight)
                    Text(engine.tableClockText)
                        .font(RailTheme.mono(13))
                        .foregroundColor(RailTheme.cream)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.35)))
            }
            Button {
                cycleLamp()
            } label: {
                RIcon(kind: .lamp, size: 17, color: lampColor)
                    .padding(9)
                    .background(Circle().fill(Color.black.opacity(0.35)))
            }
            Button {
                toggleRun()
            } label: {
                HStack(spacing: 6) {
                    RIcon(kind: running ? .pause : .play, size: 14, color: RailTheme.cream)
                    Text(running ? "Stop" : "Run")
                        .font(RailTheme.heading(14))
                        .foregroundColor(RailTheme.cream)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(running ? RailTheme.signalRed : RailTheme.pine))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    private var lampColor: Color {
        switch store.lampMode {
        case "day": return RailTheme.cream
        case "night": return RailTheme.brassLight
        default: return RailTheme.matGrassLight
        }
    }

    private func cycleLamp() {
        switch store.lampMode {
        case "auto": store.lampMode = "day"
        case "day": store.lampMode = "night"
        default: store.lampMode = "auto"
        }
        store.scheduleSave()
        RailHaptics.tap()
    }

    private func toggleRun() {
        if running {
            stopRun()
        } else {
            guard !store.layout.track.isEmpty else {
                store.celebration = "Lay some track before running trains"
                return
            }
            guard !store.layout.trains.isEmpty else {
                store.celebration = "Add a train in the Trains panel first"
                showTrains = true
                return
            }
            engine.onStats = { delta in
                store.absorb(delta, night: store.nightFactor)
            }
            store.recordRunStart()
            engine.start(layout: store.layout)
            running = true
            RailHaptics.success()
        }
    }

    private func stopRun() {
        guard running else { return }
        var saved = store.layout
        saved.track = engine.layout.track
        store.layout = saved
        engine.stop()
        running = false
    }

    private var trackTools: [TrackKind] { [.straight, .curve, .switchRight, .switchLeft, .cross, .station, .bridge, .buffer] }

    private var buildPalette: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    showTrains = true
                } label: {
                    HStack(spacing: 6) {
                        RIcon(kind: .depot, size: 15, color: RailTheme.cream)
                        Text("Trains \(store.layout.trains.count)")
                            .font(RailTheme.heading(13))
                            .foregroundColor(RailTheme.cream)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(RailTheme.pineDeep))
                }
                Button {
                    showSceneryPicker = true
                } label: {
                    HStack(spacing: 6) {
                        RIcon(kind: .leaf, size: 15, color: RailTheme.cream)
                        Text(currentSceneryLabel)
                            .font(RailTheme.heading(13))
                            .foregroundColor(RailTheme.cream)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(isSceneryTool ? RailTheme.brassDark : RailTheme.pineDeep.opacity(0.75)))
                }
                Button {
                    tool = .erase
                    RailHaptics.tap()
                } label: {
                    RIcon(kind: .eraser, size: 16, color: tool == .erase ? RailTheme.ink : RailTheme.cream)
                        .padding(9)
                        .background(Circle().fill(tool == .erase ? RailTheme.brassLight : RailTheme.pineDeep.opacity(0.75)))
                }
                Spacer()
                Text("Tap to place, tap again to rotate")
                    .font(RailTheme.body(10))
                    .foregroundColor(RailTheme.cream.opacity(0.75))
                    .lineLimit(2)
                    .frame(maxWidth: 110)
            }
            .padding(.horizontal, 14)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(trackTools, id: \.self) { kind in
                        trackChip(kind)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.30))
                .ignoresSafeArea(edges: .bottom)
        )
        .sheet(isPresented: $showSceneryPicker) {
            SceneryPickerSheet(current: currentScenery) { kind in
                tool = .scenery(kind)
            }
            .environmentObject(store)
        }
    }

    private var isSceneryTool: Bool {
        if case .scenery = tool { return true }
        return false
    }

    private var currentScenery: SceneryKind? {
        if case .scenery(let k) = tool { return k }
        return nil
    }

    private var currentSceneryLabel: String {
        if case .scenery(let k) = tool { return k.displayName }
        return "Scenery"
    }

    private func trackChip(_ kind: TrackKind) -> some View {
        let isActive: Bool
        if case .track(let k) = tool, k == kind { isActive = true } else { isActive = false }
        return Button {
            tool = .track(kind)
            RailHaptics.tap()
        } label: {
            VStack(spacing: 4) {
                TrackPiecePreview(kind: kind)
                    .frame(width: 44, height: 44)
                Text(kind.displayName)
                    .font(RailTheme.body(9))
                    .foregroundColor(isActive ? RailTheme.ink : RailTheme.cream.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(6)
            .frame(width: 62)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isActive ? RailTheme.brassLight : Color.white.opacity(0.10))
            )
        }
    }

    private var runControls: some View {
        VStack(spacing: 8) {
            if engine.trains.contains(where: { $0.state == .held || $0.state == .blocked || $0.state == .buffered }) {
                Button {
                    for train in engine.trains {
                        if train.state == .buffered || train.state == .blocked {
                            engine.reverse(train)
                        } else {
                            engine.resume(train)
                        }
                    }
                    RailHaptics.tap()
                } label: {
                    Text("All Aboard — resume every train")
                        .font(RailTheme.heading(13))
                        .foregroundColor(RailTheme.cream)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(RailTheme.brassDark))
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(engine.trains) { train in
                        trainChip(train)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.30))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func trainChip(_ train: RunTrain) -> some View {
        Button {
            selectedTrainID = train.id
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(train.loco.body)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(RailTheme.cream.opacity(0.6), lineWidth: 1))
                VStack(alignment: .leading, spacing: 1) {
                    Text(train.loco.name)
                        .font(RailTheme.heading(12))
                        .foregroundColor(RailTheme.cream)
                        .lineLimit(1)
                    Text(stateLabel(train.state))
                        .font(RailTheme.body(10))
                        .foregroundColor(stateColor(train.state))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.12)))
        }
    }

    private func stateLabel(_ state: TrainState) -> String {
        switch state {
        case .running: return "Running"
        case .dwelling: return "At the platform"
        case .held: return "Held — tap to resume"
        case .buffered: return "At the buffers"
        case .blocked: return "End of track"
        }
    }

    private func stateColor(_ state: TrainState) -> Color {
        switch state {
        case .running: return RailTheme.matGrassLight
        case .dwelling: return RailTheme.brassLight
        default: return Color(red: 0.95, green: 0.6, blue: 0.5)
        }
    }
}

struct TrackPiecePreview: View {
    let kind: TrackKind

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(RailTheme.matGrass))
            var piece = PlacedTrack(kind: kind, rot: 0)
            if kind == .straight || kind == .station { piece.rot = 1 }
            var layout = RailLayout(name: "preview", cols: 1, rows: 1)
            layout.track[GridPoint(x: 0, y: 0)] = piece
            let artist = TrackArtist(layout: layout, cellSize: size.width, buildMode: false, selectedCell: nil, phase: 0, night: 0)
            artist.drawTrack(&ctx)
        }
    }
}

struct SceneryPickerSheet: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let current: SceneryKind?
    let onPick: (SceneryKind) -> Void

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 0) {
                HStack {
                    Text("Scenery Shelf")
                        .font(RailTheme.title(20))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        RIcon(kind: .close, size: 15, color: RailTheme.inkSoft)
                            .padding(8)
                            .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(SceneryKind.allCases, id: \.self) { kind in
                            sceneryCell(kind)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func sceneryCell(_ kind: SceneryKind) -> some View {
        let unlocked = store.isSceneryUnlocked(kind)
        let isActive = current == kind
        return Button {
            guard unlocked else {
                RailHaptics.warning()
                return
            }
            onPick(kind)
            RailHaptics.tap()
            presentationMode.wrappedValue.dismiss()
        } label: {
            VStack(spacing: 6) {
                SceneryPreview(kind: kind)
                    .frame(width: 62, height: 62)
                    .opacity(unlocked ? 1 : 0.35)
                Text(kind.displayName)
                    .font(RailTheme.body(11))
                    .foregroundColor(RailTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !unlocked {
                    LockBadge(rankName: RailStore.ranks[kind.unlockRank].name)
                }
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isActive ? RailTheme.brassLight.opacity(0.5) : RailTheme.paper)
                    .shadow(color: RailTheme.cardShadow, radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct SceneryPreview: View {
    let kind: SceneryKind

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(RailTheme.matGrass))
            var inner = ctx
            SceneryKit.draw(&inner, kind: kind, variant: 0, rect: rect, phase: 0.7, night: 0, seed: 5)
        }
    }
}

struct BoardsSheet: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    @State private var renameIndex: Int?
    @State private var renameText = ""

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 0) {
                HStack {
                    Text("Your Boards")
                        .font(RailTheme.title(20))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        RIcon(kind: .close, size: 15, color: RailTheme.inkSoft)
                            .padding(8)
                            .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 6)
                Text("Three baseboards live in the workshop. Each keeps its own track plan, scenery and trains.")
                    .font(RailTheme.body(13))
                    .foregroundColor(RailTheme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(store.layouts.indices, id: \.self) { idx in
                            boardRow(idx)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func boardRow(_ idx: Int) -> some View {
        let layout = store.layouts[idx]
        let isCurrent = idx == store.currentLayout
        return Button {
            store.currentLayout = idx
            store.scheduleSave()
            RailHaptics.tap()
            presentationMode.wrappedValue.dismiss()
        } label: {
            HStack(spacing: 12) {
                BoardThumb(layout: layout)
                    .frame(width: 74, height: 88)
                VStack(alignment: .leading, spacing: 4) {
                    if renameIndex == idx {
                        TextField("Board name", text: $renameText, onCommit: {
                            let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                store.layouts[idx].name = String(trimmed.prefix(24))
                                store.scheduleSave()
                            }
                            renameIndex = nil
                        })
                        .font(RailTheme.heading(15))
                        .foregroundColor(RailTheme.ink)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(layout.name)
                            .font(RailTheme.heading(16))
                            .foregroundColor(RailTheme.ink)
                            .lineLimit(1)
                    }
                    Text("\(layout.trackCount) track · \(layout.scenery.count) scenery · \(layout.trains.count) trains")
                        .font(RailTheme.body(12))
                        .foregroundColor(RailTheme.inkFaint)
                    HStack(spacing: 8) {
                        if isCurrent {
                            Text("On the table")
                                .font(RailTheme.body(11))
                                .foregroundColor(RailTheme.pine)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(RailTheme.pine.opacity(0.12)))
                        }
                        Button {
                            renameText = layout.name
                            renameIndex = idx
                        } label: {
                            Text("Rename")
                                .font(RailTheme.body(11))
                                .foregroundColor(RailTheme.brassDark)
                        }
                    }
                }
                Spacer()
                RIcon(kind: .chevronRight, size: 14, color: RailTheme.inkFaint)
            }
            .railCard(padding: 12)
        }
    }
}

struct BoardThumb: View {
    let layout: RailLayout

    var body: some View {
        Canvas { ctx, size in
            let cs = min(size.width / CGFloat(layout.cols), size.height / CGFloat(layout.rows))
            let ox = (size.width - cs * CGFloat(layout.cols)) / 2
            let oy = (size.height - cs * CGFloat(layout.rows)) / 2
            ctx.translateBy(x: ox, y: oy)
            let mat = CGRect(x: 0, y: 0, width: CGFloat(layout.cols) * cs, height: CGFloat(layout.rows) * cs)
            ctx.fill(Path(roundedRect: mat, cornerRadius: 4), with: .color(RailTheme.matGrass))
            for (cell, piece) in layout.track {
                let rect = CGRect(x: CGFloat(cell.x) * cs, y: CGFloat(cell.y) * cs, width: cs, height: cs)
                for (from, to) in TrackGeometry.pathSegments(piece) {
                    var p = Path()
                    let steps = 6
                    for i in 0...steps {
                        let t = CGFloat(i) / CGFloat(steps)
                        let local = TrackGeometry.point(from: from, to: to, t: t)
                        let pt = CGPoint(x: rect.minX + local.x * cs, y: rect.minY + local.y * cs)
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    ctx.stroke(p, with: .color(RailTheme.railSteel), lineWidth: max(1.4, cs * 0.2))
                }
            }
            for (cell, item) in layout.scenery {
                let rect = CGRect(x: CGFloat(cell.x) * cs, y: CGFloat(cell.y) * cs, width: cs, height: cs)
                let color: Color
                switch item.kind {
                case .pond: color = RailTheme.water
                case .house, .barn, .stationHouse, .cargoShed: color = RailTheme.signalRedDark
                default: color = RailTheme.pineDeep
                }
                ctx.fill(Path(ellipseIn: rect.insetBy(dx: cs * 0.22, dy: cs * 0.22)), with: .color(color.opacity(0.8)))
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(RailTheme.oakLight.opacity(0.4)))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TrainsSheet: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 0) {
                HStack {
                    Text("Trains on this Board")
                        .font(RailTheme.title(20))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        RIcon(kind: .close, size: 15, color: RailTheme.inkSoft)
                            .padding(8)
                            .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(store.layout.trains.indices, id: \.self) { idx in
                            TrainEditorCard(index: idx)
                                .environmentObject(store)
                        }
                        if store.layout.trains.count < 3 {
                            Button {
                                var layout = store.layout
                                let firstLoco = store.unlockedLocos.first ?? RailContent.locomotives[0]
                                layout.trains.append(TrainSetup(locoID: firstLoco.id, wagonIDs: ["coach_cherry"]))
                                store.layout = layout
                                RailHaptics.place()
                            } label: {
                                HStack(spacing: 8) {
                                    RIcon(kind: .plus, size: 15, color: RailTheme.pineDeep)
                                    Text("Add a train")
                                }
                            }
                            .buttonStyle(SoftButtonStyle())
                        } else {
                            Text("The table crew allows three trains at once.")
                                .font(RailTheme.body(12))
                                .foregroundColor(RailTheme.inkFaint)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

struct TrainEditorCard: View {
    @EnvironmentObject var store: RailStore
    let index: Int
    @State private var showLocoPicker = false
    @State private var showWagonPicker = false

    var body: some View {
        if index < store.layout.trains.count {
            let train = store.layout.trains[index]
            let loco = RailContent.locomotive(train.locoID)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Train \(index + 1)")
                        .font(RailTheme.heading(13))
                        .foregroundColor(RailTheme.inkFaint)
                    Spacer()
                    Button {
                        var layout = store.layout
                        layout.trains.remove(at: index)
                        store.layout = layout
                        RailHaptics.tap()
                    } label: {
                        Text("Remove")
                            .font(RailTheme.body(12))
                            .foregroundColor(RailTheme.signalRed)
                    }
                }
                Button {
                    showLocoPicker = true
                } label: {
                    HStack(spacing: 10) {
                        ConsistPreview(train: train)
                            .frame(height: 30)
                        Spacer()
                        RIcon(kind: .chevronRight, size: 12, color: RailTheme.inkFaint)
                    }
                }
                HStack {
                    Text(loco.name)
                        .font(RailTheme.heading(16))
                        .foregroundColor(RailTheme.ink)
                    Text(loco.locoClass.label)
                        .font(RailTheme.body(11))
                        .foregroundColor(RailTheme.inkFaint)
                    Spacer()
                    Button {
                        showWagonPicker = true
                    } label: {
                        Text("\(train.wagonIDs.count) wagons")
                            .font(RailTheme.body(12))
                            .foregroundColor(RailTheme.brassDark)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(RailTheme.brass.opacity(0.15)))
                    }
                }
                HStack(spacing: 10) {
                    RIcon(kind: .gauge, size: 15, color: RailTheme.inkSoft)
                    Slider(value: throttleBinding, in: 0.2...1.0)
                        .accentColor(RailTheme.pine)
                    Text("\(Int(train.throttle * 100))%")
                        .font(RailTheme.mono(12))
                        .foregroundColor(RailTheme.inkSoft)
                        .frame(width: 42, alignment: .trailing)
                }
                Toggle(isOn: stopsBinding) {
                    Text("Calls at stations")
                        .font(RailTheme.body(14))
                        .foregroundColor(RailTheme.inkSoft)
                }
                .toggleStyle(SwitchToggleStyle(tint: RailTheme.pine))
            }
            .railCard()
            .sheet(isPresented: $showLocoPicker) {
                LocoPickerSheet(selected: train.locoID) { newID in
                    var layout = store.layout
                    layout.trains[index].locoID = newID
                    store.layout = layout
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showWagonPicker) {
                WagonPickerSheet(trainIndex: index)
                    .environmentObject(store)
            }
        }
    }

    private var throttleBinding: Binding<Double> {
        Binding(
            get: { index < store.layout.trains.count ? store.layout.trains[index].throttle : 0.5 },
            set: { value in
                guard index < store.layout.trains.count else { return }
                var layout = store.layout
                layout.trains[index].throttle = value
                store.layout = layout
            })
    }

    private var stopsBinding: Binding<Bool> {
        Binding(
            get: { index < store.layout.trains.count ? store.layout.trains[index].stopsAtStations : true },
            set: { value in
                guard index < store.layout.trains.count else { return }
                var layout = store.layout
                layout.trains[index].stopsAtStations = value
                store.layout = layout
            })
    }
}

struct ConsistPreview: View {
    let train: TrainSetup

    var body: some View {
        let loco = RailContent.locomotive(train.locoID)
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 4)
                .fill(loco.body)
                .frame(width: 40, height: 18)
                .overlay(
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(loco.roof)
                            .frame(width: 10, height: 12)
                        Spacer()
                        Circle()
                            .fill(loco.accent)
                            .frame(width: 6, height: 6)
                            .padding(.trailing, 4)
                    }
                    .padding(.leading, 3)
                )
            ForEach(train.wagonIDs.indices, id: \.self) { i in
                let wagon = RailContent.wagon(train.wagonIDs[i])
                RoundedRectangle(cornerRadius: 3)
                    .fill(wagon.body)
                    .frame(width: 26, height: 14)
                    .overlay(RoundedRectangle(cornerRadius: 2).fill(wagon.roof).padding(3))
            }
        }
    }
}

struct LocoPickerSheet: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let selected: String
    let onPick: (String) -> Void

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 0) {
                HStack {
                    Text("Choose an Engine")
                        .font(RailTheme.title(20))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        RIcon(kind: .close, size: 15, color: RailTheme.inkSoft)
                            .padding(8)
                            .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(RailContent.locomotives) { loco in
                            locoRow(loco)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func locoRow(_ loco: Locomotive) -> some View {
        let unlocked = store.isLocoUnlocked(loco)
        return Button {
            guard unlocked else {
                RailHaptics.warning()
                return
            }
            onPick(loco.id)
            RailHaptics.tap()
            presentationMode.wrappedValue.dismiss()
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(loco.body)
                    .frame(width: 46, height: 22)
                    .overlay(Circle().fill(loco.accent).frame(width: 8, height: 8).offset(x: 12))
                    .opacity(unlocked ? 1 : 0.35)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loco.name)
                        .font(RailTheme.heading(15))
                        .foregroundColor(RailTheme.ink)
                    Text("\(loco.workshopNumber) · \(loco.locoClass.label)")
                        .font(RailTheme.body(11))
                        .foregroundColor(RailTheme.inkFaint)
                }
                Spacer()
                if selected == loco.id {
                    RIcon(kind: .check, size: 15, color: RailTheme.pine)
                } else if !unlocked {
                    LockBadge(rankName: RailStore.ranks[loco.unlockRank].name)
                }
            }
            .railCard(padding: 12)
        }
    }
}

struct WagonPickerSheet: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let trainIndex: Int

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 0) {
                HStack {
                    Text("Marshal the Consist")
                        .font(RailTheme.title(20))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        RIcon(kind: .close, size: 15, color: RailTheme.inkSoft)
                            .padding(8)
                            .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 4)
                if trainIndex < store.layout.trains.count {
                    let train = store.layout.trains[trainIndex]
                    ScrollView(.horizontal, showsIndicators: false) {
                        ConsistPreview(train: train)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                    }
                    Text("Tap a wagon type to couple it on; tap one in the train to uncouple it. Six wagons at most.")
                        .font(RailTheme.body(12))
                        .foregroundColor(RailTheme.inkFaint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 6)
                    ScrollView {
                        VStack(spacing: 8) {
                            if !train.wagonIDs.isEmpty {
                                SectionHeader(title: "In the train")
                                    .padding(.top, 4)
                                ForEach(train.wagonIDs.indices, id: \.self) { i in
                                    wagonRow(RailContent.wagon(train.wagonIDs[i]), action: {
                                        var layout = store.layout
                                        layout.trains[trainIndex].wagonIDs.remove(at: i)
                                        store.layout = layout
                                        RailHaptics.tap()
                                    }, actionLabel: "Uncouple")
                                }
                            }
                            SectionHeader(title: "Wagon shelf")
                                .padding(.top, 8)
                            ForEach(RailContent.wagons) { wagon in
                                let unlocked = store.isWagonUnlocked(wagon)
                                wagonRow(wagon, action: {
                                    guard unlocked else {
                                        RailHaptics.warning()
                                        return
                                    }
                                    var layout = store.layout
                                    guard layout.trains[trainIndex].wagonIDs.count < 6 else {
                                        RailHaptics.warning()
                                        return
                                    }
                                    layout.trains[trainIndex].wagonIDs.append(wagon.id)
                                    store.layout = layout
                                    RailHaptics.place()
                                }, actionLabel: unlocked ? "Couple" : nil, locked: !unlocked, lockRank: wagon.unlockRank)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }

    private func wagonRow(_ wagon: WagonType, action: @escaping () -> Void, actionLabel: String?, locked: Bool = false, lockRank: Int = 0) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(wagon.body)
                    .frame(width: 36, height: 18)
                    .overlay(RoundedRectangle(cornerRadius: 3).fill(wagon.roof).padding(4))
                    .opacity(locked ? 0.35 : 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(wagon.name)
                        .font(RailTheme.heading(14))
                        .foregroundColor(RailTheme.ink)
                    Text(wagon.kind)
                        .font(RailTheme.body(11))
                        .foregroundColor(RailTheme.inkFaint)
                }
                Spacer()
                if locked {
                    LockBadge(rankName: RailStore.ranks[lockRank].name)
                } else if let label = actionLabel {
                    Text(label)
                        .font(RailTheme.body(12))
                        .foregroundColor(label == "Uncouple" ? RailTheme.signalRed : RailTheme.pine)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill((label == "Uncouple" ? RailTheme.signalRed : RailTheme.pine).opacity(0.12)))
                }
            }
            .railCard(padding: 11)
        }
    }
}

struct TrainControlSheet: View {
    @ObservedObject var engine: RailRunEngine
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let trainID: UUID

    var body: some View {
        ZStack {
            PaperBackdrop()
            if let train = engine.trains.first(where: { $0.id == trainID }) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(train.loco.name)
                                .font(RailTheme.title(22))
                                .foregroundColor(RailTheme.ink)
                            Text("\(train.loco.workshopNumber) · \(train.setup.wagonIDs.count) wagons")
                                .font(RailTheme.body(13))
                                .foregroundColor(RailTheme.inkFaint)
                        }
                        Spacer()
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            RIcon(kind: .close, size: 15, color: RailTheme.inkSoft)
                                .padding(8)
                                .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                        }
                    }
                    ConsistPreview(train: train.setup)
                    HStack(spacing: 10) {
                        RIcon(kind: .gauge, size: 17, color: RailTheme.inkSoft)
                        Slider(value: Binding(
                            get: { train.setup.throttle },
                            set: { engine.setThrottle(train, $0) }), in: 0.2...1.0)
                            .accentColor(RailTheme.pine)
                        Text("\(Int(train.setup.throttle * 100))%")
                            .font(RailTheme.mono(13))
                            .foregroundColor(RailTheme.inkSoft)
                            .frame(width: 46, alignment: .trailing)
                    }
                    .railCard(padding: 14)
                    HStack(spacing: 10) {
                        Button {
                            engine.reverse(train)
                        } label: {
                            HStack(spacing: 6) {
                                RIcon(kind: .reverse, size: 15, color: RailTheme.pineDeep)
                                Text("Reverse")
                            }
                        }
                        .buttonStyle(SoftButtonStyle())
                        if train.state == .held || train.state == .blocked {
                            Button {
                                engine.resume(train)
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    RIcon(kind: .play, size: 13, color: RailTheme.cream)
                                    Text("Resume")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    Text(stateDescription(train))
                        .font(RailTheme.body(13))
                        .foregroundColor(RailTheme.inkFaint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
                .padding(20)
            } else {
                VStack {
                    Text("The train has gone to the shed.")
                        .font(RailTheme.body(15))
                        .foregroundColor(RailTheme.inkFaint)
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                        .buttonStyle(SoftButtonStyle())
                        .padding(.top, 8)
                }
                .padding(30)
            }
        }
    }

    private func stateDescription(_ train: RunTrain) -> String {
        switch train.state {
        case .running: return "Running well. Tap a switch's brass lever on the table to change its route."
        case .dwelling: return "Standing at the platform while imaginary passengers board."
        case .held: return "Held after meeting another train. Move the other train on, then resume."
        case .buffered: return "Right up against the buffer stop. Reverse to run the other way."
        case .blocked: return "The track simply ends here. Reverse, or stop the session and lay more track."
        }
    }
}
