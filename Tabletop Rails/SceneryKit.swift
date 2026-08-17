import SwiftUI

enum SceneryKit {
    static func draw(_ ctx: inout GraphicsContext, kind: SceneryKind, variant: Int, rect: CGRect, phase: Double, night: Double, seed: UInt64) {
        var rng = SeededRandom(seed: seed &+ UInt64(variant) &* 977)
        switch kind {
        case .pine: drawPine(&ctx, rect: rect, rng: &rng, phase: phase)
        case .oakTree: drawOak(&ctx, rect: rect, rng: &rng, phase: phase)
        case .poplar: drawPoplar(&ctx, rect: rect, rng: &rng, phase: phase)
        case .bush: drawBush(&ctx, rect: rect, rng: &rng)
        case .house: drawHouse(&ctx, rect: rect, rng: &rng, night: night)
        case .barn: drawBarn(&ctx, rect: rect, rng: &rng, night: night)
        case .stationHouse: drawStationHouse(&ctx, rect: rect, night: night)
        case .windmill: drawWindmill(&ctx, rect: rect, phase: phase)
        case .waterTower: drawWaterTower(&ctx, rect: rect)
        case .pond: drawPond(&ctx, rect: rect, phase: phase, rng: &rng)
        case .rockOutcrop: drawRocks(&ctx, rect: rect, rng: &rng)
        case .fence: drawFence(&ctx, rect: rect, rng: &rng)
        case .lampPost: drawLamp(&ctx, rect: rect, night: night)
        case .signalPost: drawSignal(&ctx, rect: rect, armDown: false, night: night)
        case .flowerBed: drawFlowers(&ctx, rect: rect, rng: &rng)
        case .sheepPen: drawSheepPen(&ctx, rect: rect, rng: &rng)
        case .watchtower: drawWatchtower(&ctx, rect: rect, night: night)
        case .cargoShed: drawCargoShed(&ctx, rect: rect, night: night)
        }
    }

    static func groundShadow(_ ctx: inout GraphicsContext, center: CGPoint, w: CGFloat, h: CGFloat) {
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - w / 2 + w * 0.06, y: center.y - h / 2 + h * 0.14, width: w, height: h)), with: .color(Color.black.opacity(0.13)))
    }

    private static func outline(_ ctx: inout GraphicsContext, _ path: Path, fill: Color, line: CGFloat = 1.0) {
        ctx.fill(path, with: .color(fill))
        ctx.stroke(path, with: .color(RailTheme.ink.opacity(0.55)), lineWidth: line)
    }

    private static func drawPine(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom, phase: Double) {
        let cx = rect.midX + (rng.next() - 0.5) * rect.width * 0.16
        let baseY = rect.maxY - rect.height * 0.12
        let h = rect.height * (0.62 + rng.next() * 0.18)
        let w = rect.width * (0.42 + rng.next() * 0.12)
        let sway = CGFloat(sin(phase * 0.8 + Double(rng.next() * 6))) * rect.width * 0.008
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: w * 0.9, h: rect.height * 0.10)
        let trunk = Path(CGRect(x: cx - w * 0.05, y: baseY - h * 0.16, width: w * 0.10, height: h * 0.17))
        outline(&ctx, trunk, fill: RailTheme.sleeper)
        let tiers = 3
        for i in 0..<tiers {
            let f = CGFloat(i)
            let tierW = w * (1.0 - f * 0.26)
            let tierTopY = baseY - h * (0.36 + f * 0.30)
            let tierBotY = baseY - h * (0.10 + f * 0.28)
            var p = Path()
            p.move(to: CGPoint(x: cx + sway * f, y: tierTopY))
            p.addLine(to: CGPoint(x: cx - tierW / 2, y: tierBotY))
            let scallops = 4
            for s in 0..<scallops {
                let sx0 = cx - tierW / 2 + tierW * CGFloat(s) / CGFloat(scallops)
                let sx1 = cx - tierW / 2 + tierW * CGFloat(s + 1) / CGFloat(scallops)
                p.addQuadCurve(to: CGPoint(x: sx1, y: tierBotY), control: CGPoint(x: (sx0 + sx1) / 2, y: tierBotY + rect.height * 0.035))
            }
            p.closeSubpath()
            let green = i == 0 ? RailTheme.pine : (i == 1 ? RailTheme.pineLight : Color(red: 0.42, green: 0.56, blue: 0.40))
            outline(&ctx, p, fill: green)
        }
    }

    private static func drawOak(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom, phase: Double) {
        let cx = rect.midX + (rng.next() - 0.5) * rect.width * 0.1
        let baseY = rect.maxY - rect.height * 0.12
        let h = rect.height * (0.58 + rng.next() * 0.14)
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: rect.width * 0.6, h: rect.height * 0.11)
        var trunk = Path()
        trunk.move(to: CGPoint(x: cx - rect.width * 0.05, y: baseY))
        trunk.addQuadCurve(to: CGPoint(x: cx - rect.width * 0.02, y: baseY - h * 0.34), control: CGPoint(x: cx - rect.width * 0.07, y: baseY - h * 0.2))
        trunk.addLine(to: CGPoint(x: cx + rect.width * 0.02, y: baseY - h * 0.34))
        trunk.addQuadCurve(to: CGPoint(x: cx + rect.width * 0.05, y: baseY), control: CGPoint(x: cx + rect.width * 0.07, y: baseY - h * 0.2))
        trunk.closeSubpath()
        outline(&ctx, trunk, fill: RailTheme.sleeper)
        let sway = CGFloat(sin(phase * 0.7 + Double(rng.next() * 6))) * rect.width * 0.01
        let lobes = 5
        var canopy = Path()
        for i in 0..<lobes {
            let ang = CGFloat(i) / CGFloat(lobes) * 2 * .pi + rng.next() * 0.5
            let r = rect.width * (0.16 + rng.next() * 0.08)
            let lx = cx + sway + cos(ang) * rect.width * 0.16
            let ly = baseY - h * 0.55 + sin(ang) * h * 0.14
            canopy.addEllipse(in: CGRect(x: lx - r, y: ly - r, width: r * 2, height: r * 2))
        }
        let green = Color(red: 0.36 + rng.next() * 0.08, green: 0.50 + rng.next() * 0.06, blue: 0.30)
        ctx.fill(canopy, with: .color(green))
        ctx.stroke(canopy, with: .color(RailTheme.ink.opacity(0.45)), lineWidth: 1)
        var highlight = Path()
        highlight.addEllipse(in: CGRect(x: cx + sway - rect.width * 0.13, y: baseY - h * 0.66, width: rect.width * 0.16, height: rect.width * 0.10))
        ctx.fill(highlight, with: .color(Color.white.opacity(0.16)))
    }

    private static func drawPoplar(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom, phase: Double) {
        let cx = rect.midX + (rng.next() - 0.5) * rect.width * 0.14
        let baseY = rect.maxY - rect.height * 0.10
        let h = rect.height * (0.72 + rng.next() * 0.12)
        let sway = CGFloat(sin(phase * 0.9 + Double(rng.next() * 6))) * rect.width * 0.012
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: rect.width * 0.36, h: rect.height * 0.08)
        var p = Path()
        p.move(to: CGPoint(x: cx - rect.width * 0.08, y: baseY))
        p.addQuadCurve(to: CGPoint(x: cx + sway, y: baseY - h), control: CGPoint(x: cx - rect.width * 0.10, y: baseY - h * 0.55))
        p.addQuadCurve(to: CGPoint(x: cx + rect.width * 0.08, y: baseY), control: CGPoint(x: cx + rect.width * 0.10, y: baseY - h * 0.55))
        p.closeSubpath()
        outline(&ctx, p, fill: Color(red: 0.40, green: 0.53, blue: 0.32))
        var vein = Path()
        vein.move(to: CGPoint(x: cx, y: baseY - h * 0.06))
        vein.addQuadCurve(to: CGPoint(x: cx + sway, y: baseY - h * 0.92), control: CGPoint(x: cx, y: baseY - h * 0.5))
        ctx.stroke(vein, with: .color(RailTheme.ink.opacity(0.3)), lineWidth: 0.8)
    }

    private static func drawBush(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom) {
        let baseY = rect.maxY - rect.height * 0.18
        let count = 3
        for i in 0..<count {
            let bx = rect.minX + rect.width * (0.24 + 0.26 * CGFloat(i)) + (rng.next() - 0.5) * rect.width * 0.08
            let r = rect.width * (0.13 + rng.next() * 0.07)
            groundShadow(&ctx, center: CGPoint(x: bx, y: baseY + r * 0.5), w: r * 2.1, h: r * 0.7)
            let p = Path(ellipseIn: CGRect(x: bx - r, y: baseY - r, width: r * 2, height: r * 1.7))
            outline(&ctx, p, fill: Color(red: 0.33 + rng.next() * 0.06, green: 0.47, blue: 0.29))
            if rng.next() > 0.5 {
                let bp = Path(ellipseIn: CGRect(x: bx - r * 0.3, y: baseY - r * 0.7, width: r * 0.16, height: r * 0.16))
                ctx.fill(bp, with: .color(RailTheme.signalRed.opacity(0.8)))
            }
        }
    }

    private static func drawHouse(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom, night: Double) {
        let w = rect.width * 0.62
        let bh = rect.height * 0.30
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.16
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: w * 1.15, h: rect.height * 0.10)
        let wallTones = [Color(red: 0.92, green: 0.88, blue: 0.78), Color(red: 0.85, green: 0.77, blue: 0.62), Color(red: 0.80, green: 0.83, blue: 0.78)]
        let wall = wallTones[rng.nextInt(wallTones.count)]
        outline(&ctx, Path(CGRect(x: cx - w / 2, y: baseY - bh, width: w, height: bh)), fill: wall)
        var roof = Path()
        let roofH = rect.height * 0.22
        roof.move(to: CGPoint(x: cx - w / 2 - w * 0.07, y: baseY - bh))
        roof.addLine(to: CGPoint(x: cx, y: baseY - bh - roofH))
        roof.addLine(to: CGPoint(x: cx + w / 2 + w * 0.07, y: baseY - bh))
        roof.closeSubpath()
        outline(&ctx, roof, fill: rng.next() > 0.5 ? RailTheme.signalRedDark : RailTheme.sleeper)
        let chimney = Path(CGRect(x: cx + w * 0.18, y: baseY - bh - roofH * 0.85, width: w * 0.10, height: roofH * 0.5))
        outline(&ctx, chimney, fill: RailTheme.oakDark)
        let doorW = w * 0.16
        outline(&ctx, Path(CGRect(x: cx - doorW / 2, y: baseY - bh * 0.62, width: doorW, height: bh * 0.62)), fill: RailTheme.oakShadow)
        let winGlow = night > 0.4 ? Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.5 + night * 0.5) : Color(red: 0.55, green: 0.62, blue: 0.68)
        for sx in [-0.3, 0.3] {
            let win = Path(CGRect(x: cx + CGFloat(sx) * w - w * 0.08, y: baseY - bh * 0.78, width: w * 0.16, height: bh * 0.3))
            outline(&ctx, win, fill: winGlow, line: 0.8)
        }
    }

    private static func drawBarn(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom, night: Double) {
        let w = rect.width * 0.68
        let bh = rect.height * 0.34
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.14
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: w * 1.15, h: rect.height * 0.1)
        outline(&ctx, Path(CGRect(x: cx - w / 2, y: baseY - bh, width: w, height: bh)), fill: Color(red: 0.58, green: 0.22, blue: 0.17))
        var roof = Path()
        let roofH = rect.height * 0.2
        roof.move(to: CGPoint(x: cx - w / 2 - w * 0.05, y: baseY - bh))
        roof.addLine(to: CGPoint(x: cx - w * 0.28, y: baseY - bh - roofH * 0.8))
        roof.addLine(to: CGPoint(x: cx, y: baseY - bh - roofH))
        roof.addLine(to: CGPoint(x: cx + w * 0.28, y: baseY - bh - roofH * 0.8))
        roof.addLine(to: CGPoint(x: cx + w / 2 + w * 0.05, y: baseY - bh))
        roof.closeSubpath()
        outline(&ctx, roof, fill: RailTheme.oakShadow)
        var doors = Path()
        doors.addRect(CGRect(x: cx - w * 0.14, y: baseY - bh * 0.7, width: w * 0.28, height: bh * 0.7))
        outline(&ctx, doors, fill: Color(red: 0.45, green: 0.16, blue: 0.13))
        var cross = Path()
        cross.move(to: CGPoint(x: cx - w * 0.14, y: baseY - bh * 0.7))
        cross.addLine(to: CGPoint(x: cx + w * 0.14, y: baseY))
        cross.move(to: CGPoint(x: cx + w * 0.14, y: baseY - bh * 0.7))
        cross.addLine(to: CGPoint(x: cx - w * 0.14, y: baseY))
        ctx.stroke(cross, with: .color(Color.white.opacity(0.75)), lineWidth: 1.4)
        let loft = Path(ellipseIn: CGRect(x: cx - w * 0.06, y: baseY - bh - roofH * 0.55, width: w * 0.12, height: w * 0.12))
        outline(&ctx, loft, fill: night > 0.4 ? Color(red: 1.0, green: 0.85, blue: 0.5) : RailTheme.ink.opacity(0.7), line: 0.8)
    }

    private static func drawStationHouse(_ ctx: inout GraphicsContext, rect: CGRect, night: Double) {
        let w = rect.width * 0.72
        let bh = rect.height * 0.28
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.16
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: w * 1.1, h: rect.height * 0.1)
        outline(&ctx, Path(CGRect(x: cx - w / 2, y: baseY - bh, width: w, height: bh)), fill: Color(red: 0.72, green: 0.55, blue: 0.38))
        outline(&ctx, Path(CGRect(x: cx - w / 2 - w * 0.08, y: baseY - bh - rect.height * 0.07, width: w * 1.16, height: rect.height * 0.07)), fill: RailTheme.pineDeep)
        let winGlow = night > 0.4 ? Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.5 + night * 0.5) : Color(red: 0.55, green: 0.62, blue: 0.68)
        for sx in [-0.32, 0.0, 0.32] {
            let win = Path(CGRect(x: cx + CGFloat(sx) * w - w * 0.07, y: baseY - bh * 0.72, width: w * 0.14, height: bh * 0.42))
            outline(&ctx, win, fill: winGlow, line: 0.8)
        }
        var sign = Path()
        sign.addRoundedRect(in: CGRect(x: cx - w * 0.2, y: baseY - bh - rect.height * 0.16, width: w * 0.4, height: rect.height * 0.07), cornerSize: CGSize(width: 2, height: 2))
        outline(&ctx, sign, fill: RailTheme.cream, line: 0.8)
    }

    private static func drawWindmill(_ ctx: inout GraphicsContext, rect: CGRect, phase: Double) {
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.12
        let h = rect.height * 0.6
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: rect.width * 0.5, h: rect.height * 0.1)
        var tower = Path()
        tower.move(to: CGPoint(x: cx - rect.width * 0.16, y: baseY))
        tower.addLine(to: CGPoint(x: cx - rect.width * 0.07, y: baseY - h))
        tower.addLine(to: CGPoint(x: cx + rect.width * 0.07, y: baseY - h))
        tower.addLine(to: CGPoint(x: cx + rect.width * 0.16, y: baseY))
        tower.closeSubpath()
        outline(&ctx, tower, fill: Color(red: 0.82, green: 0.76, blue: 0.64))
        let cap = Path(ellipseIn: CGRect(x: cx - rect.width * 0.09, y: baseY - h - rect.height * 0.07, width: rect.width * 0.18, height: rect.height * 0.09))
        outline(&ctx, cap, fill: RailTheme.pineDeep)
        let hub = CGPoint(x: cx, y: baseY - h - rect.height * 0.02)
        let bladeLen = rect.width * 0.30
        let rotation = CGFloat(phase * 0.9)
        for i in 0..<4 {
            let ang = rotation + CGFloat(i) * .pi / 2
            var blade = Path()
            let tip = CGPoint(x: hub.x + cos(ang) * bladeLen, y: hub.y + sin(ang) * bladeLen)
            let side = CGPoint(x: hub.x + cos(ang + 0.16) * bladeLen * 0.9, y: hub.y + sin(ang + 0.16) * bladeLen * 0.9)
            blade.move(to: hub)
            blade.addLine(to: tip)
            blade.addLine(to: side)
            blade.closeSubpath()
            outline(&ctx, blade, fill: RailTheme.cream.opacity(0.92), line: 0.8)
        }
        ctx.fill(Path(ellipseIn: CGRect(x: hub.x - 2.5, y: hub.y - 2.5, width: 5, height: 5)), with: .color(RailTheme.ink))
    }

    private static func drawWaterTower(_ ctx: inout GraphicsContext, rect: CGRect) {
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.12
        let h = rect.height * 0.5
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: rect.width * 0.5, h: rect.height * 0.09)
        for sx in [-0.14, 0.14] {
            var leg = Path()
            leg.move(to: CGPoint(x: cx + CGFloat(sx) * rect.width, y: baseY))
            leg.addLine(to: CGPoint(x: cx + CGFloat(sx) * rect.width * 0.7, y: baseY - h * 0.55))
            ctx.stroke(leg, with: .color(RailTheme.sleeper), lineWidth: 2.4)
        }
        var brace = Path()
        brace.move(to: CGPoint(x: cx - rect.width * 0.12, y: baseY - h * 0.2))
        brace.addLine(to: CGPoint(x: cx + rect.width * 0.12, y: baseY - h * 0.38))
        brace.move(to: CGPoint(x: cx + rect.width * 0.12, y: baseY - h * 0.2))
        brace.addLine(to: CGPoint(x: cx - rect.width * 0.12, y: baseY - h * 0.38))
        ctx.stroke(brace, with: .color(RailTheme.sleeper.opacity(0.8)), lineWidth: 1.2)
        let tankW = rect.width * 0.34
        let tankH = h * 0.42
        let tank = Path(roundedRect: CGRect(x: cx - tankW / 2, y: baseY - h, width: tankW, height: tankH), cornerRadius: 3)
        outline(&ctx, tank, fill: Color(red: 0.52, green: 0.36, blue: 0.24))
        for i in 1..<4 {
            var band = Path()
            let by = baseY - h + tankH * CGFloat(i) / 4
            band.move(to: CGPoint(x: cx - tankW / 2, y: by))
            band.addLine(to: CGPoint(x: cx + tankW / 2, y: by))
            ctx.stroke(band, with: .color(RailTheme.ink.opacity(0.35)), lineWidth: 0.8)
        }
        var roof = Path()
        roof.move(to: CGPoint(x: cx - tankW / 2 - 2, y: baseY - h))
        roof.addLine(to: CGPoint(x: cx, y: baseY - h - rect.height * 0.08))
        roof.addLine(to: CGPoint(x: cx + tankW / 2 + 2, y: baseY - h))
        roof.closeSubpath()
        outline(&ctx, roof, fill: RailTheme.pineDeep)
        var spout = Path()
        spout.move(to: CGPoint(x: cx + tankW / 2, y: baseY - h + tankH * 0.7))
        spout.addQuadCurve(to: CGPoint(x: cx + tankW * 0.9, y: baseY - h * 0.4), control: CGPoint(x: cx + tankW * 0.9, y: baseY - h + tankH * 0.8))
        ctx.stroke(spout, with: .color(RailTheme.railSteel), lineWidth: 2)
    }

    private static func drawPond(_ ctx: inout GraphicsContext, rect: CGRect, phase: Double, rng: inout SeededRandom) {
        var pond = Path()
        let inset = rect.width * 0.10
        pond.move(to: CGPoint(x: rect.minX + inset * 2, y: rect.midY))
        pond.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + inset * 1.4), control1: CGPoint(x: rect.minX + inset, y: rect.minY + rect.height * 0.28), control2: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + inset))
        pond.addCurve(to: CGPoint(x: rect.maxX - inset * 1.6, y: rect.midY), control1: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY + inset * 1.2), control2: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.34))
        pond.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY - inset), control1: CGPoint(x: rect.maxX - inset, y: rect.maxY - rect.height * 0.3), control2: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.maxY - inset * 0.8))
        pond.addCurve(to: CGPoint(x: rect.minX + inset * 2, y: rect.midY), control1: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.maxY - inset * 0.9), control2: CGPoint(x: rect.minX + inset, y: rect.maxY - rect.height * 0.32))
        pond.closeSubpath()
        ctx.fill(pond, with: .color(RailTheme.waterDeep))
        var inner = pond
        inner = inner.applying(CGAffineTransform(translationX: rect.width * 0.02, y: rect.height * 0.02).scaledBy(x: 0.94, y: 0.94).translatedBy(x: rect.minX * 0.06 / 0.94, y: rect.minY * 0.06 / 0.94))
        ctx.fill(inner, with: .color(RailTheme.water.opacity(0.85)))
        ctx.stroke(pond, with: .color(Color(red: 0.72, green: 0.66, blue: 0.5)), lineWidth: 1.6)
        for i in 0..<4 {
            let sy = rect.minY + rect.height * (0.32 + 0.13 * CGFloat(i))
            let shift = CGFloat(sin(phase * 1.2 + Double(i))) * rect.width * 0.03
            var ripple = Path()
            ripple.move(to: CGPoint(x: rect.midX - rect.width * 0.14 + shift, y: sy))
            ripple.addQuadCurve(to: CGPoint(x: rect.midX + rect.width * 0.14 + shift, y: sy), control: CGPoint(x: rect.midX + shift, y: sy - rect.height * 0.02))
            ctx.stroke(ripple, with: .color(Color.white.opacity(0.35)), lineWidth: 0.9)
        }
        for _ in 0..<3 {
            let lx = rect.minX + rect.width * (0.2 + rng.next() * 0.6)
            let ly = rect.minY + rect.height * (0.2 + rng.next() * 0.6)
            let lily = Path(ellipseIn: CGRect(x: lx, y: ly, width: rect.width * 0.06, height: rect.width * 0.045))
            ctx.fill(lily, with: .color(RailTheme.pineLight))
        }
    }

    private static func drawRocks(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom) {
        let baseY = rect.maxY - rect.height * 0.2
        for i in 0..<3 {
            let rx = rect.minX + rect.width * (0.22 + 0.26 * CGFloat(i)) + (rng.next() - 0.5) * rect.width * 0.06
            let rw = rect.width * (0.16 + rng.next() * 0.12)
            let rh = rw * (0.7 + rng.next() * 0.3)
            groundShadow(&ctx, center: CGPoint(x: rx, y: baseY + rh * 0.14), w: rw * 1.3, h: rh * 0.4)
            var rock = Path()
            rock.move(to: CGPoint(x: rx - rw / 2, y: baseY))
            rock.addLine(to: CGPoint(x: rx - rw * 0.3, y: baseY - rh * 0.8))
            rock.addLine(to: CGPoint(x: rx + rw * 0.12, y: baseY - rh))
            rock.addLine(to: CGPoint(x: rx + rw / 2, y: baseY - rh * 0.4))
            rock.addLine(to: CGPoint(x: rx + rw * 0.4, y: baseY))
            rock.closeSubpath()
            outline(&ctx, rock, fill: Color(red: 0.62 + rng.next() * 0.06, green: 0.60, blue: 0.56))
            var crack = Path()
            crack.move(to: CGPoint(x: rx - rw * 0.1, y: baseY - rh * 0.7))
            crack.addLine(to: CGPoint(x: rx + rw * 0.05, y: baseY - rh * 0.3))
            ctx.stroke(crack, with: .color(RailTheme.ink.opacity(0.3)), lineWidth: 0.8)
        }
    }

    private static func drawFence(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom) {
        let y = rect.midY + rect.height * 0.14
        let posts = 5
        for i in 0..<posts {
            let px = rect.minX + rect.width * (0.12 + 0.19 * CGFloat(i))
            let ph = rect.height * (0.16 + rng.next() * 0.03)
            let post = Path(CGRect(x: px - 1.4, y: y - ph, width: 2.8, height: ph))
            outline(&ctx, post, fill: RailTheme.oak, line: 0.7)
        }
        for row in 0..<2 {
            var rail = Path()
            let ry = y - rect.height * (0.05 + 0.07 * CGFloat(row))
            rail.move(to: CGPoint(x: rect.minX + rect.width * 0.1, y: ry))
            rail.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.1, y: ry + (rng.next() - 0.5) * 2))
            ctx.stroke(rail, with: .color(RailTheme.oakDark), lineWidth: 1.8)
        }
    }

    private static func drawLamp(_ ctx: inout GraphicsContext, rect: CGRect, night: Double) {
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.18
        let h = rect.height * 0.44
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: rect.width * 0.2, h: rect.height * 0.05)
        var pole = Path()
        pole.move(to: CGPoint(x: cx, y: baseY))
        pole.addLine(to: CGPoint(x: cx, y: baseY - h))
        ctx.stroke(pole, with: .color(RailTheme.pineDeep), lineWidth: 2.6)
        let head = Path(roundedRect: CGRect(x: cx - rect.width * 0.07, y: baseY - h - rect.height * 0.09, width: rect.width * 0.14, height: rect.height * 0.1), cornerRadius: 2)
        if night > 0.35 {
            let glowR = rect.width * 0.4 * CGFloat(night)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - glowR, y: baseY - h - rect.height * 0.05 - glowR, width: glowR * 2, height: glowR * 2)), with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.85, blue: 0.5).opacity(0.5 * night), .clear]), center: CGPoint(x: cx, y: baseY - h - rect.height * 0.05), startRadius: 0, endRadius: glowR))
            outline(&ctx, head, fill: Color(red: 1.0, green: 0.88, blue: 0.55), line: 0.8)
        } else {
            outline(&ctx, head, fill: RailTheme.cream, line: 0.8)
        }
        var cap = Path()
        cap.move(to: CGPoint(x: cx - rect.width * 0.08, y: baseY - h - rect.height * 0.09))
        cap.addLine(to: CGPoint(x: cx, y: baseY - h - rect.height * 0.14))
        cap.addLine(to: CGPoint(x: cx + rect.width * 0.08, y: baseY - h - rect.height * 0.09))
        cap.closeSubpath()
        outline(&ctx, cap, fill: RailTheme.pineDeep, line: 0.7)
    }

    static func drawSignal(_ ctx: inout GraphicsContext, rect: CGRect, armDown: Bool, night: Double) {
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.18
        let h = rect.height * 0.5
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: rect.width * 0.2, h: rect.height * 0.05)
        var pole = Path()
        pole.move(to: CGPoint(x: cx, y: baseY))
        pole.addLine(to: CGPoint(x: cx, y: baseY - h))
        ctx.stroke(pole, with: .color(RailTheme.cream), lineWidth: 3)
        ctx.stroke(pole, with: .color(RailTheme.ink.opacity(0.4)), lineWidth: 0.7)
        let armLen = rect.width * 0.26
        let armAng: CGFloat = armDown ? 0.55 : 0.0
        var arm = Path()
        arm.move(to: CGPoint(x: cx, y: baseY - h))
        arm.addLine(to: CGPoint(x: cx + cos(armAng) * armLen, y: baseY - h + sin(armAng) * armLen))
        ctx.stroke(arm, with: .color(RailTheme.signalRed), lineWidth: 4)
        var stripe = Path()
        stripe.move(to: CGPoint(x: cx + cos(armAng) * armLen * 0.75, y: baseY - h + sin(armAng) * armLen * 0.75))
        stripe.addLine(to: CGPoint(x: cx + cos(armAng) * armLen * 0.9, y: baseY - h + sin(armAng) * armLen * 0.9))
        ctx.stroke(stripe, with: .color(.white), lineWidth: 4)
        if night > 0.35 {
            let lampColor = armDown ? Color(red: 1, green: 0.3, blue: 0.2) : Color(red: 0.4, green: 1, blue: 0.5)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 2, y: baseY - h - 6, width: 4, height: 4)), with: .color(lampColor.opacity(0.9)))
        }
    }

    private static func drawFlowers(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom) {
        let bed = Path(roundedRect: CGRect(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.3, width: rect.width * 0.68, height: rect.height * 0.42), cornerRadius: rect.width * 0.1)
        outline(&ctx, bed, fill: Color(red: 0.45, green: 0.34, blue: 0.22), line: 0.9)
        let colors = [Color(red: 0.85, green: 0.35, blue: 0.35), Color(red: 0.92, green: 0.75, blue: 0.30), Color(red: 0.80, green: 0.55, blue: 0.75), Color(red: 0.95, green: 0.90, blue: 0.85)]
        for _ in 0..<14 {
            let fx = rect.minX + rect.width * (0.22 + rng.next() * 0.56)
            let fy = rect.minY + rect.height * (0.36 + rng.next() * 0.3)
            let r = rect.width * (0.018 + rng.next() * 0.014)
            let c = colors[rng.nextInt(colors.count)]
            for k in 0..<5 {
                let a = CGFloat(k) / 5 * 2 * .pi
                ctx.fill(Path(ellipseIn: CGRect(x: fx + cos(a) * r - r * 0.7, y: fy + sin(a) * r - r * 0.7, width: r * 1.4, height: r * 1.4)), with: .color(c))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: fx - r * 0.5, y: fy - r * 0.5, width: r, height: r)), with: .color(Color(red: 0.95, green: 0.85, blue: 0.4)))
        }
    }

    private static func drawSheepPen(_ ctx: inout GraphicsContext, rect: CGRect, rng: inout SeededRandom) {
        let pen = Path(roundedRect: CGRect(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.22, width: rect.width * 0.72, height: rect.height * 0.56), cornerRadius: 3)
        ctx.stroke(pen, with: .color(RailTheme.oakDark), lineWidth: 2)
        for t in stride(from: 0.0, through: 1.0, by: 0.16) {
            let px = rect.minX + rect.width * (0.14 + 0.72 * CGFloat(t))
            ctx.fill(Path(CGRect(x: px - 1, y: rect.minY + rect.height * 0.20, width: 2, height: 5)), with: .color(RailTheme.oakDark))
        }
        for _ in 0..<4 {
            let sx = rect.minX + rect.width * (0.24 + rng.next() * 0.5)
            let sy = rect.minY + rect.height * (0.34 + rng.next() * 0.32)
            let sw = rect.width * 0.12
            groundShadow(&ctx, center: CGPoint(x: sx, y: sy + sw * 0.22), w: sw, h: sw * 0.34)
            let bodyR = CGRect(x: sx - sw / 2, y: sy - sw * 0.3, width: sw, height: sw * 0.6)
            outline(&ctx, Path(roundedRect: bodyR, cornerRadius: sw * 0.3), fill: Color(red: 0.93, green: 0.91, blue: 0.86), line: 0.8)
            let headSide: CGFloat = rng.next() > 0.5 ? 1 : -1
            ctx.fill(Path(ellipseIn: CGRect(x: sx + headSide * sw * 0.42 - sw * 0.12, y: sy - sw * 0.16, width: sw * 0.24, height: sw * 0.2)), with: .color(RailTheme.ink.opacity(0.85)))
        }
    }

    private static func drawWatchtower(_ ctx: inout GraphicsContext, rect: CGRect, night: Double) {
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.12
        let h = rect.height * 0.56
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: rect.width * 0.5, h: rect.height * 0.09)
        for sx in [-0.16, 0.16] {
            var leg = Path()
            leg.move(to: CGPoint(x: cx + CGFloat(sx) * rect.width, y: baseY))
            leg.addLine(to: CGPoint(x: cx + CGFloat(sx) * rect.width * 0.55, y: baseY - h * 0.6))
            ctx.stroke(leg, with: .color(RailTheme.sleeper), lineWidth: 2.6)
        }
        var brace = Path()
        brace.move(to: CGPoint(x: cx - rect.width * 0.13, y: baseY - h * 0.18))
        brace.addLine(to: CGPoint(x: cx + rect.width * 0.13, y: baseY - h * 0.42))
        brace.move(to: CGPoint(x: cx + rect.width * 0.13, y: baseY - h * 0.18))
        brace.addLine(to: CGPoint(x: cx - rect.width * 0.13, y: baseY - h * 0.42))
        ctx.stroke(brace, with: .color(RailTheme.sleeper.opacity(0.8)), lineWidth: 1.2)
        let cabW = rect.width * 0.36
        let cabH = h * 0.32
        outline(&ctx, Path(CGRect(x: cx - cabW / 2, y: baseY - h, width: cabW, height: cabH)), fill: Color(red: 0.70, green: 0.56, blue: 0.38))
        let winGlow = night > 0.4 ? Color(red: 1.0, green: 0.85, blue: 0.5) : Color(red: 0.55, green: 0.62, blue: 0.68)
        outline(&ctx, Path(CGRect(x: cx - cabW * 0.28, y: baseY - h + cabH * 0.24, width: cabW * 0.56, height: cabH * 0.4)), fill: winGlow, line: 0.7)
        var roof = Path()
        roof.move(to: CGPoint(x: cx - cabW / 2 - 3, y: baseY - h))
        roof.addLine(to: CGPoint(x: cx, y: baseY - h - rect.height * 0.09))
        roof.addLine(to: CGPoint(x: cx + cabW / 2 + 3, y: baseY - h))
        roof.closeSubpath()
        outline(&ctx, roof, fill: RailTheme.pineDeep)
    }

    private static func drawCargoShed(_ ctx: inout GraphicsContext, rect: CGRect, night: Double) {
        let w = rect.width * 0.7
        let bh = rect.height * 0.3
        let cx = rect.midX
        let baseY = rect.maxY - rect.height * 0.16
        groundShadow(&ctx, center: CGPoint(x: cx, y: baseY), w: w * 1.1, h: rect.height * 0.09)
        outline(&ctx, Path(CGRect(x: cx - w / 2, y: baseY - bh, width: w, height: bh)), fill: Color(red: 0.48, green: 0.52, blue: 0.50))
        var roof = Path()
        roof.move(to: CGPoint(x: cx - w / 2 - 4, y: baseY - bh))
        roof.addLine(to: CGPoint(x: cx - w / 2 + w * 0.3, y: baseY - bh - rect.height * 0.1))
        roof.addLine(to: CGPoint(x: cx + w / 2 + 4, y: baseY - bh - rect.height * 0.02))
        roof.closeSubpath()
        outline(&ctx, roof, fill: RailTheme.railSteel)
        let door = Path(CGRect(x: cx - w * 0.18, y: baseY - bh * 0.75, width: w * 0.36, height: bh * 0.75))
        outline(&ctx, door, fill: RailTheme.oakDark)
        for i in 1..<4 {
            var slat = Path()
            let sy = baseY - bh * 0.75 + bh * 0.75 * CGFloat(i) / 4
            slat.move(to: CGPoint(x: cx - w * 0.18, y: sy))
            slat.addLine(to: CGPoint(x: cx + w * 0.18, y: sy))
            ctx.stroke(slat, with: .color(RailTheme.ink.opacity(0.3)), lineWidth: 0.7)
        }
        for bx in [-0.36, 0.32] {
            let crate = Path(CGRect(x: cx + CGFloat(bx) * w, y: baseY - rect.height * 0.07, width: rect.width * 0.09, height: rect.height * 0.07))
            outline(&ctx, crate, fill: RailTheme.oak, line: 0.8)
        }
    }
}
