import SwiftUI

struct TrackArtist {
    let layout: RailLayout
    let cellSize: CGFloat
    var buildMode: Bool
    var selectedCell: GridPoint?
    var phase: Double
    var night: Double

    func cellRect(_ p: GridPoint) -> CGRect {
        CGRect(x: CGFloat(p.x) * cellSize, y: CGFloat(p.y) * cellSize, width: cellSize, height: cellSize)
    }

    func drawTable(_ ctx: inout GraphicsContext, size: CGSize) {
        let mat = CGRect(x: 0, y: 0, width: CGFloat(layout.cols) * cellSize, height: CGFloat(layout.rows) * cellSize)
        ctx.fill(Path(roundedRect: mat, cornerRadius: cellSize * 0.2), with: .linearGradient(Gradient(colors: [RailTheme.matGrassLight, RailTheme.matGrass]), startPoint: .zero, endPoint: CGPoint(x: 0, y: mat.height)))
        var rng = SeededRandom(seed: 99)
        for _ in 0..<Int(mat.width * mat.height / 900) {
            let x = rng.next() * mat.width
            let y = rng.next() * mat.height
            let tuftW = 3 + rng.next() * 4
            var tuft = Path()
            tuft.move(to: CGPoint(x: x, y: y))
            tuft.addQuadCurve(to: CGPoint(x: x + tuftW * 0.4, y: y - tuftW * 0.8), control: CGPoint(x: x, y: y - tuftW * 0.5))
            tuft.move(to: CGPoint(x: x + tuftW * 0.3, y: y))
            tuft.addQuadCurve(to: CGPoint(x: x + tuftW * 0.7, y: y - tuftW * 0.7), control: CGPoint(x: x + tuftW * 0.4, y: y - tuftW * 0.4))
            ctx.stroke(tuft, with: .color(RailTheme.matGrassDark.opacity(0.30 + rng.next() * 0.2)), lineWidth: 0.7)
        }
        for _ in 0..<Int(mat.width * mat.height / 5200) {
            let x = rng.next() * mat.width
            let y = rng.next() * mat.height
            let r = 1.0 + rng.next() * 1.6
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(Color.white.opacity(0.12)))
        }
        if buildMode {
            var gridPath = Path()
            for gx in 0...layout.cols {
                gridPath.move(to: CGPoint(x: CGFloat(gx) * cellSize, y: 0))
                gridPath.addLine(to: CGPoint(x: CGFloat(gx) * cellSize, y: mat.height))
            }
            for gy in 0...layout.rows {
                gridPath.move(to: CGPoint(x: 0, y: CGFloat(gy) * cellSize))
                gridPath.addLine(to: CGPoint(x: mat.width, y: CGFloat(gy) * cellSize))
            }
            ctx.stroke(gridPath, with: .color(Color.white.opacity(0.14)), style: StrokeStyle(lineWidth: 0.7, dash: [3, 4]))
        }
    }

    func drawFrame(_ ctx: inout GraphicsContext) {
        let mat = CGRect(x: 0, y: 0, width: CGFloat(layout.cols) * cellSize, height: CGFloat(layout.rows) * cellSize)
        let frameW = cellSize * 0.42
        let outer = mat.insetBy(dx: -frameW, dy: -frameW)
        var frame = Path(roundedRect: outer, cornerRadius: cellSize * 0.3)
        frame.addRoundedRect(in: mat, cornerSize: CGSize(width: cellSize * 0.2, height: cellSize * 0.2))
        ctx.fill(frame, with: .linearGradient(Gradient(colors: [RailTheme.oakLight, RailTheme.oakDark]), startPoint: CGPoint(x: outer.minX, y: outer.minY), endPoint: CGPoint(x: outer.minX, y: outer.maxY)), style: FillStyle(eoFill: true))
        var rng = SeededRandom(seed: 31)
        for _ in 0..<40 {
            let onTop = rng.next() > 0.5
            let along = rng.next()
            var grain = Path()
            if onTop {
                let gy = outer.minY + rng.next() * frameW * (rng.next() > 0.5 ? 1 : 0) + (rng.next() > 0.5 ? 0 : mat.height + frameW)
                grain.move(to: CGPoint(x: outer.minX + along * outer.width * 0.8, y: gy))
                grain.addQuadCurve(to: CGPoint(x: outer.minX + along * outer.width * 0.8 + 40 + rng.next() * 60, y: gy + rng.next() * 3 - 1.5), control: CGPoint(x: outer.minX + along * outer.width * 0.8 + 30, y: gy + rng.next() * 4 - 2))
            } else {
                let gx = outer.minX + rng.next() * frameW * (rng.next() > 0.5 ? 1 : 0) + (rng.next() > 0.5 ? 0 : mat.width + frameW)
                grain.move(to: CGPoint(x: gx, y: outer.minY + along * outer.height * 0.8))
                grain.addQuadCurve(to: CGPoint(x: gx + rng.next() * 3 - 1.5, y: outer.minY + along * outer.height * 0.8 + 40 + rng.next() * 60), control: CGPoint(x: gx + rng.next() * 4 - 2, y: outer.minY + along * outer.height * 0.8 + 30))
            }
            ctx.stroke(grain, with: .color(RailTheme.oakShadow.opacity(0.2)), lineWidth: 0.8)
        }
        ctx.stroke(Path(roundedRect: mat, cornerRadius: cellSize * 0.2), with: .color(RailTheme.oakShadow.opacity(0.7)), lineWidth: 2)
        ctx.stroke(Path(roundedRect: outer, cornerRadius: cellSize * 0.3), with: .color(RailTheme.oakShadow.opacity(0.8)), lineWidth: 1.6)
        for corner in [CGPoint(x: outer.minX + frameW * 0.5, y: outer.minY + frameW * 0.5), CGPoint(x: outer.maxX - frameW * 0.5, y: outer.minY + frameW * 0.5), CGPoint(x: outer.minX + frameW * 0.5, y: outer.maxY - frameW * 0.5), CGPoint(x: outer.maxX - frameW * 0.5, y: outer.maxY - frameW * 0.5)] {
            let r = frameW * 0.16
            ctx.fill(Path(ellipseIn: CGRect(x: corner.x - r, y: corner.y - r, width: r * 2, height: r * 2)), with: .color(RailTheme.brass))
            ctx.stroke(Path(ellipseIn: CGRect(x: corner.x - r, y: corner.y - r, width: r * 2, height: r * 2)), with: .color(RailTheme.brassDark), lineWidth: 1)
        }
    }

    func drawTrack(_ ctx: inout GraphicsContext) {
        let cells = layout.track.keys.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        for cell in cells {
            guard let piece = layout.track[cell] else { continue }
            let rect = cellRect(cell)
            drawPiece(&ctx, piece: piece, rect: rect, cell: cell)
        }
    }

    private func segmentPath(from: Dir4, to: Dir4?, rect: CGRect, offset: CGFloat = 0) -> Path {
        var p = Path()
        if let to = to, to != from.opposite {
            let corner = TrackGeometry.sharedCorner(from, to)
            let c = CGPoint(x: rect.minX + corner.x * rect.width, y: rect.minY + corner.y * rect.height)
            let a = from.mid
            let b = to.mid
            let a0 = atan2(a.y - corner.y, a.x - corner.x)
            var a1 = atan2(b.y - corner.y, b.x - corner.x)
            while a1 - a0 > .pi { a1 -= 2 * .pi }
            while a0 - a1 > .pi { a1 += 2 * .pi }
            let radius = rect.width * 0.5 + offset
            guard radius > 0.5 else { return p }
            p.addArc(center: c, radius: radius, startAngle: Angle(radians: Double(a0)), endAngle: Angle(radians: Double(a1)), clockwise: a1 < a0)
            return p
        }
        let steps = 12
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let local = TrackGeometry.point(from: from, to: to, t: t)
            let ang = TrackGeometry.tangent(from: from, to: to, t: t)
            let normal = CGPoint(x: -sin(ang), y: cos(ang))
            let pt = CGPoint(x: rect.minX + local.x * rect.width + normal.x * offset, y: rect.minY + local.y * rect.height + normal.y * offset)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }

    private func railOffsets(from: Dir4, to: Dir4?, rect: CGRect, gauge: CGFloat) -> (Path, Path) {
        if let to = to, to != from.opposite {
            let corner = TrackGeometry.sharedCorner(from, to)
            let c = CGPoint(x: rect.minX + corner.x * rect.width, y: rect.minY + corner.y * rect.height)
            let a = from.mid
            let b = to.mid
            let a0 = atan2(a.y - corner.y, a.x - corner.x)
            var a1 = atan2(b.y - corner.y, b.x - corner.x)
            while a1 - a0 > .pi { a1 -= 2 * .pi }
            while a0 - a1 > .pi { a1 += 2 * .pi }
            var inner = Path()
            inner.addArc(center: c, radius: rect.width * 0.5 - gauge, startAngle: Angle(radians: Double(a0)), endAngle: Angle(radians: Double(a1)), clockwise: a1 < a0)
            var outerP = Path()
            outerP.addArc(center: c, radius: rect.width * 0.5 + gauge, startAngle: Angle(radians: Double(a0)), endAngle: Angle(radians: Double(a1)), clockwise: a1 < a0)
            return (inner, outerP)
        }
        return (segmentPath(from: from, to: to, rect: rect, offset: -gauge), segmentPath(from: from, to: to, rect: rect, offset: gauge))
    }

    private func drawSegment(_ ctx: inout GraphicsContext, from: Dir4, to: Dir4?, rect: CGRect, active: Bool) {
        let ballastW = rect.width * 0.46
        let center = segmentPath(from: from, to: to, rect: rect)
        ctx.stroke(center, with: .color(RailTheme.ballast), style: StrokeStyle(lineWidth: ballastW, lineCap: .butt))
        ctx.stroke(center, with: .color(RailTheme.ballastDark.opacity(0.5)), style: StrokeStyle(lineWidth: ballastW, lineCap: .butt, dash: [1.5, 5]))
        let segLen = TrackGeometry.segmentLength(from: from, to: to)
        let sleeperCount = max(3, Int(segLen * 7))
        let sleeperHalf = rect.width * 0.17
        for i in 0..<sleeperCount {
            let t = (CGFloat(i) + 0.5) / CGFloat(sleeperCount)
            let local = TrackGeometry.point(from: from, to: to, t: t)
            let ang = TrackGeometry.tangent(from: from, to: to, t: t)
            let normal = CGPoint(x: -sin(ang), y: cos(ang))
            let cpt = CGPoint(x: rect.minX + local.x * rect.width, y: rect.minY + local.y * rect.height)
            var sleeper = Path()
            sleeper.move(to: CGPoint(x: cpt.x - normal.x * sleeperHalf, y: cpt.y - normal.y * sleeperHalf))
            sleeper.addLine(to: CGPoint(x: cpt.x + normal.x * sleeperHalf, y: cpt.y + normal.y * sleeperHalf))
            ctx.stroke(sleeper, with: .color(RailTheme.sleeper.opacity(0.9)), style: StrokeStyle(lineWidth: rect.width * 0.055, lineCap: .round))
        }
        let gauge = rect.width * 0.095
        let (railA, railB) = railOffsets(from: from, to: to, rect: rect, gauge: gauge)
        let railColor = active ? RailTheme.railShine : RailTheme.railSteel
        for rail in [railA, railB] {
            ctx.stroke(rail, with: .color(RailTheme.ink.opacity(0.35)), style: StrokeStyle(lineWidth: rect.width * 0.045, lineCap: .butt))
            ctx.stroke(rail, with: .color(railColor), style: StrokeStyle(lineWidth: rect.width * 0.028, lineCap: .butt))
        }
    }

    private func drawPiece(_ ctx: inout GraphicsContext, piece: PlacedTrack, rect: CGRect, cell: GridPoint) {
        switch piece.kind {
        case .straight:
            let conns = TrackGeometry.connections(piece)
            drawSegment(&ctx, from: conns[0].0, to: conns[0].1, rect: rect, active: true)
        case .curve:
            let conns = TrackGeometry.connections(piece)
            drawSegment(&ctx, from: conns[0].0, to: conns[0].1, rect: rect, active: true)
        case .cross:
            drawSegment(&ctx, from: .e, to: .w, rect: rect, active: true)
            drawSegment(&ctx, from: .n, to: .s, rect: rect, active: true)
        case .switchRight, .switchLeft:
            let r = piece.rot
            let root = Dir4.s.rotated(r)
            let straightExit = Dir4.n.rotated(r)
            let branchExit: Dir4 = piece.kind == .switchRight ? Dir4.e.rotated(r) : Dir4.w.rotated(r)
            drawSegment(&ctx, from: root, to: piece.toBranch ? straightExit : branchExit, rect: rect, active: false)
            drawSegment(&ctx, from: root, to: piece.toBranch ? branchExit : straightExit, rect: rect, active: true)
            let leverPos = CGPoint(x: rect.midX + (piece.kind == .switchRight ? -1 : 1) * rect.width * 0.30, y: rect.midY + rect.height * 0.30)
            let lr = rect.width * 0.10
            ctx.fill(Path(ellipseIn: CGRect(x: leverPos.x - lr, y: leverPos.y - lr, width: lr * 2, height: lr * 2)), with: .color(RailTheme.brass))
            ctx.stroke(Path(ellipseIn: CGRect(x: leverPos.x - lr, y: leverPos.y - lr, width: lr * 2, height: lr * 2)), with: .color(RailTheme.brassDark), lineWidth: 1.2)
            var lever = Path()
            let leverAng: CGFloat = piece.toBranch ? -0.7 : -2.4
            lever.move(to: leverPos)
            lever.addLine(to: CGPoint(x: leverPos.x + cos(leverAng) * lr * 1.5, y: leverPos.y + sin(leverAng) * lr * 1.5))
            ctx.stroke(lever, with: .color(RailTheme.signalRedDark), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        case .station:
            let conns = TrackGeometry.connections(piece)
            let axisVertical = conns[0].0 == .n || conns[0].0 == .s
            let platformFirst = piece.rot == 0 || piece.rot == 1
            let pw = rect.width * 0.20
            var platformRect: CGRect
            if axisVertical {
                platformRect = CGRect(x: platformFirst ? rect.minX + rect.width * 0.02 : rect.maxX - rect.width * 0.02 - pw, y: rect.minY + rect.height * 0.04, width: pw, height: rect.height * 0.92)
            } else {
                platformRect = CGRect(x: rect.minX + rect.width * 0.04, y: platformFirst ? rect.minY + rect.height * 0.02 : rect.maxY - rect.height * 0.02 - pw, width: rect.width * 0.92, height: pw)
            }
            drawSegment(&ctx, from: conns[0].0, to: conns[0].1, rect: rect, active: true)
            let platform = Path(roundedRect: platformRect, cornerRadius: 2)
            ctx.fill(platform, with: .color(Color(red: 0.78, green: 0.72, blue: 0.60)))
            ctx.stroke(platform, with: .color(RailTheme.ink.opacity(0.5)), lineWidth: 1)
            var edge = Path()
            if axisVertical {
                let ex = platformFirst ? platformRect.maxX : platformRect.minX
                edge.move(to: CGPoint(x: ex, y: platformRect.minY))
                edge.addLine(to: CGPoint(x: ex, y: platformRect.maxY))
            } else {
                let ey = platformFirst ? platformRect.maxY : platformRect.minY
                edge.move(to: CGPoint(x: platformRect.minX, y: ey))
                edge.addLine(to: CGPoint(x: platformRect.maxX, y: ey))
            }
            ctx.stroke(edge, with: .color(Color.white.opacity(0.8)), lineWidth: 1.6)
            let benchR = CGRect(x: platformRect.midX - 3, y: platformRect.midY - 3, width: 6, height: 6)
            ctx.fill(Path(roundedRect: benchR, cornerRadius: 1), with: .color(RailTheme.oakDark))
            if night > 0.35 {
                let glowR = rect.width * 0.3
                ctx.fill(Path(ellipseIn: CGRect(x: platformRect.midX - glowR, y: platformRect.midY - glowR, width: glowR * 2, height: glowR * 2)), with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.85, blue: 0.5).opacity(0.30 * night), .clear]), center: CGPoint(x: platformRect.midX, y: platformRect.midY), startRadius: 0, endRadius: glowR))
            }
        case .bridge:
            let conns = TrackGeometry.connections(piece)
            let axisVertical = conns[0].0 == .n || conns[0].0 == .s
            var shadow = Path()
            if axisVertical {
                shadow.addRect(CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY, width: rect.width * 0.6, height: rect.height))
            } else {
                shadow.addRect(CGRect(x: rect.minX, y: rect.minY + rect.height * 0.2, width: rect.width, height: rect.height * 0.6))
            }
            ctx.fill(shadow, with: .color(Color.black.opacity(0.12)))
            drawSegment(&ctx, from: conns[0].0, to: conns[0].1, rect: rect, active: true)
            let girderW = rect.width * 0.06
            for side in [-1.0, 1.0] {
                var girder = Path()
                if axisVertical {
                    let gx = rect.midX + CGFloat(side) * rect.width * 0.3
                    girder.addRect(CGRect(x: gx - girderW / 2, y: rect.minY, width: girderW, height: rect.height))
                } else {
                    let gy = rect.midY + CGFloat(side) * rect.height * 0.3
                    girder.addRect(CGRect(x: rect.minX, y: gy - girderW / 2, width: rect.width, height: girderW))
                }
                ctx.fill(girder, with: .color(RailTheme.signalRedDark))
                ctx.stroke(girder, with: .color(RailTheme.ink.opacity(0.5)), lineWidth: 0.8)
            }
            var lattice = Path()
            let steps = 5
            for i in 0..<steps {
                let t0 = CGFloat(i) / CGFloat(steps)
                let t1 = CGFloat(i + 1) / CGFloat(steps)
                if axisVertical {
                    lattice.move(to: CGPoint(x: rect.midX - rect.width * 0.3, y: rect.minY + t0 * rect.height))
                    lattice.addLine(to: CGPoint(x: rect.midX + rect.width * 0.3, y: rect.minY + t1 * rect.height))
                    lattice.move(to: CGPoint(x: rect.midX + rect.width * 0.3, y: rect.minY + t0 * rect.height))
                    lattice.addLine(to: CGPoint(x: rect.midX - rect.width * 0.3, y: rect.minY + t1 * rect.height))
                } else {
                    lattice.move(to: CGPoint(x: rect.minX + t0 * rect.width, y: rect.midY - rect.height * 0.3))
                    lattice.addLine(to: CGPoint(x: rect.minX + t1 * rect.width, y: rect.midY + rect.height * 0.3))
                    lattice.move(to: CGPoint(x: rect.minX + t0 * rect.width, y: rect.midY + rect.height * 0.3))
                    lattice.addLine(to: CGPoint(x: rect.minX + t1 * rect.width, y: rect.midY - rect.height * 0.3))
                }
            }
            ctx.stroke(lattice, with: .color(RailTheme.signalRedDark.opacity(0.8)), lineWidth: 1.2)
        case .buffer:
            let open = TrackGeometry.bufferOpenEdge(piece)
            drawSegment(&ctx, from: open, to: nil, rect: rect, active: true)
            let local = TrackGeometry.point(from: open, to: nil, t: 1)
            let ang = TrackGeometry.tangent(from: open, to: nil, t: 1)
            let normal = CGPoint(x: -sin(ang), y: cos(ang))
            let cpt = CGPoint(x: rect.minX + local.x * rect.width, y: rect.minY + local.y * rect.height)
            var block = Path()
            let bw = rect.width * 0.16
            block.move(to: CGPoint(x: cpt.x - normal.x * bw, y: cpt.y - normal.y * bw))
            block.addLine(to: CGPoint(x: cpt.x + normal.x * bw, y: cpt.y + normal.y * bw))
            ctx.stroke(block, with: .color(RailTheme.signalRed), style: StrokeStyle(lineWidth: rect.width * 0.09, lineCap: .round))
            var post = Path()
            post.move(to: cpt)
            post.addLine(to: CGPoint(x: cpt.x - cos(ang) * rect.width * 0.1, y: cpt.y - sin(ang) * rect.width * 0.1))
            ctx.stroke(post, with: .color(RailTheme.sleeper), style: StrokeStyle(lineWidth: rect.width * 0.07, lineCap: .round))
        }
    }

    func drawScenery(_ ctx: inout GraphicsContext, engineTrains: [RunTrain]) {
        let cells = layout.scenery.keys.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        for cell in cells {
            guard let item = layout.scenery[cell] else { continue }
            let rect = cellRect(cell)
            let seed = UInt64(cell.x * 73 + cell.y * 1031 + 7)
            if item.kind == .signalPost {
                let trainNear = engineTrains.contains { train in
                    train.vehicles.contains { v in
                        abs(v.cell.x - cell.x) + abs(v.cell.y - cell.y) <= 1
                    }
                }
                var copy = ctx
                SceneryKit.drawSignal(&copy, rect: rect, armDown: trainNear, night: night)
            } else {
                var copy = ctx
                SceneryKit.draw(&copy, kind: item.kind, variant: item.variant, rect: rect, phase: phase, night: night, seed: seed)
            }
        }
    }

    func drawTrains(_ ctx: inout GraphicsContext, engine: RailRunEngine) {
        for train in engine.trains {
            let loco = train.loco
            for (i, v) in train.vehicles.enumerated().reversed() {
                let pt = v.tablePoint
                let center = CGPoint(x: pt.x * cellSize, y: pt.y * cellSize)
                let ang = v.heading + (train.reversedDirection && i == 0 ? 0 : 0)
                let isLoco = i == 0
                let bodyLen = cellSize * (isLoco ? 0.34 : 0.28)
                let bodyW = cellSize * 0.155
                var vc = ctx
                vc.translateBy(x: center.x, y: center.y)
                vc.rotate(by: Angle(radians: Double(ang)))
                vc.fill(Path(ellipseIn: CGRect(x: -bodyLen / 2 + 1.5, y: -bodyW / 2 + 2, width: bodyLen, height: bodyW)), with: .color(Color.black.opacity(0.22)))
                if isLoco {
                    drawLoco(&vc, loco: loco, len: bodyLen, w: bodyW)
                    if night > 0.4, train.state == .running {
                        var beam = Path()
                        beam.move(to: CGPoint(x: bodyLen * 0.45, y: 0))
                        beam.addLine(to: CGPoint(x: bodyLen * 1.9, y: -bodyW * 0.9))
                        beam.addLine(to: CGPoint(x: bodyLen * 1.9, y: bodyW * 0.9))
                        beam.closeSubpath()
                        vc.fill(beam, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.92, blue: 0.6).opacity(0.4 * night), .clear]), startPoint: CGPoint(x: bodyLen * 0.45, y: 0), endPoint: CGPoint(x: bodyLen * 1.9, y: 0)))
                    }
                } else {
                    let wagonIndex = i - 1
                    let wagonID = wagonIndex < train.setup.wagonIDs.count ? train.setup.wagonIDs[wagonIndex] : "boxcar"
                    drawWagon(&vc, wagon: RailContent.wagon(wagonID), len: bodyLen, w: bodyW)
                }
            }
            if case .dwelling = train.state, let head = train.vehicles.first {
                let pt = head.tablePoint
                let center = CGPoint(x: pt.x * cellSize, y: pt.y * cellSize - cellSize * 0.24)
                let pulse = 0.6 + 0.4 * sin(phase * 5)
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - 2.4, y: center.y - 2.4, width: 4.8, height: 4.8)), with: .color(RailTheme.brass.opacity(pulse)))
            }
            if train.state == .held || train.state == .blocked || train.state == .buffered, let head = train.vehicles.first {
                let pt = head.tablePoint
                let center = CGPoint(x: pt.x * cellSize, y: pt.y * cellSize - cellSize * 0.26)
                let r: CGFloat = cellSize * 0.085
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(RailTheme.signalRed.opacity(0.9)))
                var mark = Path()
                mark.move(to: CGPoint(x: center.x, y: center.y - r * 0.45))
                mark.addLine(to: CGPoint(x: center.x, y: center.y + r * 0.15))
                ctx.stroke(mark, with: .color(.white), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - 0.9, y: center.y + r * 0.3, width: 1.8, height: 1.8)), with: .color(.white))
            }
        }
    }

    private func drawLoco(_ ctx: inout GraphicsContext, loco: Locomotive, len: CGFloat, w: CGFloat) {
        let body = Path(roundedRect: CGRect(x: -len / 2, y: -w / 2, width: len, height: w), cornerRadius: w * 0.28)
        ctx.fill(body, with: .color(loco.body))
        ctx.stroke(body, with: .color(RailTheme.ink.opacity(0.6)), lineWidth: 0.9)
        let cab = Path(roundedRect: CGRect(x: -len / 2 + len * 0.06, y: -w / 2 + w * 0.12, width: len * 0.30, height: w * 0.76), cornerRadius: w * 0.14)
        ctx.fill(cab, with: .color(loco.roof))
        switch loco.locoClass {
        case .tank, .tender:
            let boiler = Path(roundedRect: CGRect(x: -len * 0.08, y: -w * 0.30, width: len * 0.52, height: w * 0.60), cornerRadius: w * 0.30)
            ctx.fill(boiler, with: .color(loco.body))
            ctx.stroke(boiler, with: .color(RailTheme.ink.opacity(0.35)), lineWidth: 0.7)
            let chimney = Path(ellipseIn: CGRect(x: len * 0.30, y: -w * 0.16, width: w * 0.32, height: w * 0.32))
            ctx.fill(chimney, with: .color(RailTheme.ink))
            ctx.stroke(chimney, with: .color(loco.accent), lineWidth: 0.9)
            let dome = Path(ellipseIn: CGRect(x: len * 0.08, y: -w * 0.14, width: w * 0.28, height: w * 0.28))
            ctx.fill(dome, with: .color(loco.accent))
        case .diesel, .electric:
            let hood = Path(roundedRect: CGRect(x: -len * 0.10, y: -w * 0.34, width: len * 0.55, height: w * 0.68), cornerRadius: w * 0.16)
            ctx.fill(hood, with: .color(loco.body))
            ctx.stroke(hood, with: .color(RailTheme.ink.opacity(0.3)), lineWidth: 0.7)
            var stripe = Path()
            stripe.move(to: CGPoint(x: len * 0.42, y: -w * 0.32))
            stripe.addLine(to: CGPoint(x: len * 0.42, y: w * 0.32))
            ctx.stroke(stripe, with: .color(loco.accent), lineWidth: w * 0.16)
            if loco.locoClass == .electric {
                var panto = Path()
                panto.move(to: CGPoint(x: -len * 0.02, y: -w * 0.1))
                panto.addLine(to: CGPoint(x: len * 0.10, y: 0))
                panto.addLine(to: CGPoint(x: -len * 0.02, y: w * 0.1))
                ctx.stroke(panto, with: .color(RailTheme.ink.opacity(0.7)), lineWidth: 0.8)
            }
        case .railcar:
            for wx in stride(from: -len * 0.28, through: len * 0.34, by: len * 0.17) {
                let win = Path(roundedRect: CGRect(x: wx, y: -w * 0.22, width: len * 0.10, height: w * 0.44), cornerRadius: 1)
                ctx.fill(win, with: .color(RailTheme.cream.opacity(0.9)))
            }
        }
        ctx.fill(Path(ellipseIn: CGRect(x: len / 2 - w * 0.20, y: -w * 0.11, width: w * 0.22, height: w * 0.22)), with: .color(RailTheme.brassLight))
    }

    private func drawWagon(_ ctx: inout GraphicsContext, wagon: WagonType, len: CGFloat, w: CGFloat) {
        let body = Path(roundedRect: CGRect(x: -len / 2, y: -w / 2, width: len, height: w), cornerRadius: w * 0.2)
        ctx.fill(body, with: .color(wagon.body))
        ctx.stroke(body, with: .color(RailTheme.ink.opacity(0.55)), lineWidth: 0.8)
        switch wagon.kind {
        case "Passenger Coach", "Observation Coach", "Mail Van":
            let roof = Path(roundedRect: CGRect(x: -len * 0.42, y: -w * 0.20, width: len * 0.84, height: w * 0.40), cornerRadius: w * 0.2)
            ctx.fill(roof, with: .color(wagon.roof))
            for wx in stride(from: -len * 0.34, through: len * 0.30, by: len * 0.16) {
                let win = Path(roundedRect: CGRect(x: wx, y: -w * 0.10, width: len * 0.09, height: w * 0.20), cornerRadius: 0.8)
                ctx.fill(win, with: .color(RailTheme.cream.opacity(0.85)))
            }
        case "Open Hopper", "Open Wagon":
            let load = Path(roundedRect: CGRect(x: -len * 0.36, y: -w * 0.26, width: len * 0.72, height: w * 0.52), cornerRadius: w * 0.1)
            ctx.fill(load, with: .color(wagon.kind == "Open Hopper" ? Color(red: 0.12, green: 0.12, blue: 0.13) : Color(red: 0.55, green: 0.52, blue: 0.46)))
            var rng = SeededRandom(seed: 55)
            for _ in 0..<8 {
                let px = -len * 0.3 + rng.next() * len * 0.6
                let py = -w * 0.18 + rng.next() * w * 0.36
                ctx.fill(Path(ellipseIn: CGRect(x: px, y: py, width: 1.4, height: 1.4)), with: .color(Color.white.opacity(0.25)))
            }
        case "Tank Wagon":
            let tank = Path(roundedRect: CGRect(x: -len * 0.40, y: -w * 0.28, width: len * 0.80, height: w * 0.56), cornerRadius: w * 0.28)
            ctx.fill(tank, with: .color(wagon.roof))
            ctx.stroke(tank, with: .color(RailTheme.ink.opacity(0.4)), lineWidth: 0.7)
            ctx.fill(Path(ellipseIn: CGRect(x: -w * 0.10, y: -w * 0.10, width: w * 0.20, height: w * 0.20)), with: .color(wagon.accent))
        case "Flat Wagon", "Heavy Hauler":
            for lx in stride(from: -len * 0.36, through: len * 0.22, by: len * 0.15) {
                let log = Path(roundedRect: CGRect(x: lx, y: -w * 0.24, width: len * 0.12, height: w * 0.48), cornerRadius: w * 0.06)
                ctx.fill(log, with: .color(wagon.accent))
                ctx.stroke(log, with: .color(RailTheme.ink.opacity(0.3)), lineWidth: 0.5)
            }
        default:
            let roof = Path(roundedRect: CGRect(x: -len * 0.42, y: -w * 0.22, width: len * 0.84, height: w * 0.44), cornerRadius: w * 0.12)
            ctx.fill(roof, with: .color(wagon.roof))
            var doorLine = Path()
            doorLine.move(to: CGPoint(x: 0, y: -w * 0.22))
            doorLine.addLine(to: CGPoint(x: 0, y: w * 0.22))
            ctx.stroke(doorLine, with: .color(RailTheme.ink.opacity(0.4)), lineWidth: 0.7)
        }
    }

    func drawEffects(_ ctx: inout GraphicsContext, engine: RailRunEngine) {
        for puff in engine.smoke {
            let a = (1 - puff.age / puff.life).clamped(0, 1)
            let r = puff.size * cellSize
            let color = puff.dark ? Color(red: 0.35, green: 0.35, blue: 0.36) : Color.white
            ctx.fill(Path(ellipseIn: CGRect(x: puff.pos.x * cellSize - r, y: puff.pos.y * cellSize - r, width: r * 2, height: r * 2)), with: .color(color.opacity(0.42 * a)))
        }
        for bump in engine.bumps {
            let a = (1 - bump.age / 0.8).clamped(0, 1)
            let r = cellSize * (0.2 + CGFloat(bump.age) * 0.5)
            let center = CGPoint(x: bump.pos.x * cellSize, y: bump.pos.y * cellSize)
            ctx.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(RailTheme.signalRed.opacity(0.7 * a)), lineWidth: 2)
        }
    }

    func drawNight(_ ctx: inout GraphicsContext, size: CGSize) {
        guard night > 0.02 else { return }
        let mat = CGRect(x: -cellSize, y: -cellSize, width: CGFloat(layout.cols + 2) * cellSize, height: CGFloat(layout.rows + 2) * cellSize)
        ctx.fill(Path(mat), with: .color(Color(red: 0.08, green: 0.10, blue: 0.22).opacity(0.34 * night)))
    }

    func drawSelection(_ ctx: inout GraphicsContext) {
        guard buildMode, let sel = selectedCell else { return }
        let rect = cellRect(sel).insetBy(dx: 1, dy: 1)
        let pulse = 0.6 + 0.3 * sin(phase * 4)
        ctx.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(RailTheme.brassLight.opacity(pulse)), style: StrokeStyle(lineWidth: 2.2, dash: [5, 4]))
    }
}

extension TrackArtist {
    func drawAmbient(_ ctx: inout GraphicsContext) {
        let matW = CGFloat(layout.cols) * cellSize
        let matH = CGFloat(layout.rows) * cellSize
        if night < 0.5 {
            for bird in 0..<2 {
                let cycle: Double = bird == 0 ? 26 : 37
                let offset: Double = bird == 0 ? 0 : 13
                let t = (phase + offset).truncatingRemainder(dividingBy: cycle)
                let flightTime: Double = 7
                guard t < flightTime else { continue }
                let progress = CGFloat(t / flightTime)
                let dir: CGFloat = bird == 0 ? 1 : -1
                let x = dir > 0 ? progress * (matW + cellSize * 2) - cellSize : matW + cellSize - progress * (matW + cellSize * 2)
                let baseYPos = matH * (bird == 0 ? 0.24 : 0.55)
                let y = baseYPos + sin(progress * .pi * 3) * cellSize * 0.4
                let flap = sin(phase * 9 + Double(bird) * 2)
                let wing = cellSize * 0.16
                var body = Path()
                body.move(to: CGPoint(x: x - wing, y: y - CGFloat(flap) * wing * 0.5))
                body.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - wing * 0.4, y: y + wing * 0.18))
                body.addQuadCurve(to: CGPoint(x: x + wing, y: y - CGFloat(flap) * wing * 0.5), control: CGPoint(x: x + wing * 0.4, y: y + wing * 0.18))
                ctx.stroke(body, with: .color(RailTheme.ink.opacity(0.62)), style: StrokeStyle(lineWidth: max(1.6, cellSize * 0.028), lineCap: .round))
                var shadow = Path()
                shadow.addEllipse(in: CGRect(x: x - wing * 0.5, y: y + cellSize * 1.6, width: wing, height: wing * 0.22))
                ctx.fill(shadow, with: .color(Color.black.opacity(0.05)))
            }
            var flowerCells: [GridPoint] = []
            for (cell, item) in layout.scenery where item.kind == .flowerBed || item.kind == .bush {
                flowerCells.append(cell)
            }
            for (i, cell) in flowerCells.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }).prefix(3).enumerated() {
                let rect = cellRect(cell)
                let fx = rect.midX + CGFloat(sin(phase * 0.9 + Double(i) * 2.1)) * rect.width * 0.42
                let fy = rect.midY - rect.height * 0.28 + CGFloat(sin(phase * 1.7 + Double(i))) * rect.height * 0.2
                let flap = abs(sin(phase * 7 + Double(i) * 1.3))
                let wingW = rect.width * 0.045 + rect.width * 0.03 * CGFloat(flap)
                let tint = i % 2 == 0 ? Color(red: 0.93, green: 0.78, blue: 0.34) : Color(red: 0.88, green: 0.60, blue: 0.72)
                var left = Path()
                left.addEllipse(in: CGRect(x: fx - wingW, y: fy - rect.height * 0.03, width: wingW, height: rect.height * 0.06))
                var right = Path()
                right.addEllipse(in: CGRect(x: fx, y: fy - rect.height * 0.03, width: wingW, height: rect.height * 0.06))
                ctx.fill(left, with: .color(tint.opacity(0.9)))
                ctx.fill(right, with: .color(tint.opacity(0.75)))
                ctx.fill(Path(ellipseIn: CGRect(x: fx - 1, y: fy - 2, width: 2, height: 4)), with: .color(RailTheme.ink.opacity(0.7)))
            }
        }
        if night > 0.2 {
            for (cell, item) in layout.scenery where item.kind == .house || item.kind == .barn {
                let rect = cellRect(cell)
                let chimneyX = rect.midX + rect.width * 0.23
                let chimneyTop = rect.maxY - rect.height * 0.72
                var rng = SeededRandom(seed: UInt64(cell.x * 31 + cell.y * 57 + 5))
                for p in 0..<3 {
                    let cycle = 5.0 + Double(rng.next()) * 2
                    let t = (phase / cycle + Double(p) / 3 + Double(rng.next())).truncatingRemainder(dividingBy: 1)
                    let py = chimneyTop - CGFloat(t) * rect.height * 0.5
                    let px = chimneyX + CGFloat(sin(phase * 0.8 + Double(p) * 2)) * rect.width * 0.05 + CGFloat(t) * rect.width * 0.08
                    let r = rect.width * (0.02 + CGFloat(t) * 0.05)
                    ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)), with: .color(Color.white.opacity(0.18 * (1 - t) * night)))
                }
            }
        }
    }
}
