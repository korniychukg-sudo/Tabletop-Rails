import SwiftUI

enum RIconKind {
    case table, depot, orders, learn, journal
    case play, pause, reverse, rotate, eraser, check, lock, chevronRight, chevronDown, star, lamp, close, plus, gauge, book, ribbon, clock, spanner, leaf, flag
}

struct RIcon: View {
    let kind: RIconKind
    var size: CGFloat = 24
    var color: Color = RailTheme.ink

    var body: some View {
        Canvas { ctx, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize).insetBy(dx: canvasSize.width * 0.08, dy: canvasSize.height * 0.08)
            draw(&ctx, rect: rect)
        }
        .frame(width: size, height: size)
    }

    private func stroke(_ ctx: inout GraphicsContext, _ p: Path, _ w: CGFloat) {
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
    }

    private func draw(_ ctx: inout GraphicsContext, rect: CGRect) {
        let w = rect.width
        let h = rect.height
        let lw = max(1.4, w * 0.09)
        switch kind {
        case .table:
            let board = Path(roundedRect: CGRect(x: rect.minX, y: rect.minY + h * 0.1, width: w, height: h * 0.62), cornerRadius: w * 0.08)
            stroke(&ctx, board, lw)
            var oval = Path()
            oval.addEllipse(in: CGRect(x: rect.minX + w * 0.16, y: rect.minY + h * 0.22, width: w * 0.68, height: h * 0.36))
            stroke(&ctx, oval, lw * 0.8)
            var legs = Path()
            legs.move(to: CGPoint(x: rect.minX + w * 0.14, y: rect.minY + h * 0.72))
            legs.addLine(to: CGPoint(x: rect.minX + w * 0.08, y: rect.maxY))
            legs.move(to: CGPoint(x: rect.maxX - w * 0.14, y: rect.minY + h * 0.72))
            legs.addLine(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.maxY))
            stroke(&ctx, legs, lw)
        case .depot:
            var body = Path()
            body.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + h * 0.34, width: w * 0.66, height: h * 0.34), cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            body.addRoundedRect(in: CGRect(x: rect.minX + w * 0.60, y: rect.minY + h * 0.14, width: w * 0.34, height: h * 0.54), cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            stroke(&ctx, body, lw)
            var stack = Path()
            stack.move(to: CGPoint(x: rect.minX + w * 0.16, y: rect.minY + h * 0.34))
            stack.addLine(to: CGPoint(x: rect.minX + w * 0.16, y: rect.minY + h * 0.12))
            stroke(&ctx, stack, lw)
            for cx in [0.18, 0.48, 0.78] {
                var wheel = Path()
                wheel.addEllipse(in: CGRect(x: rect.minX + w * CGFloat(cx) - w * 0.09, y: rect.minY + h * 0.70, width: w * 0.18, height: w * 0.18))
                stroke(&ctx, wheel, lw * 0.8)
            }
        case .orders:
            let board = Path(roundedRect: CGRect(x: rect.minX + w * 0.12, y: rect.minY + h * 0.06, width: w * 0.76, height: h * 0.9), cornerRadius: w * 0.08)
            stroke(&ctx, board, lw)
            let clip = Path(roundedRect: CGRect(x: rect.minX + w * 0.36, y: rect.minY, width: w * 0.28, height: h * 0.14), cornerRadius: w * 0.04)
            stroke(&ctx, clip, lw * 0.8)
            var lines = Path()
            for ly in [0.34, 0.52, 0.70] {
                lines.move(to: CGPoint(x: rect.minX + w * 0.26, y: rect.minY + h * CGFloat(ly)))
                lines.addLine(to: CGPoint(x: rect.minX + w * 0.74, y: rect.minY + h * CGFloat(ly)))
            }
            stroke(&ctx, lines, lw * 0.8)
        case .learn:
            var book = Path()
            book.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.16))
            book.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.10), control: CGPoint(x: rect.minX + w * 0.22, y: rect.minY))
            book.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - h * 0.12))
            book.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.minX + w * 0.24, y: rect.maxY - h * 0.06))
            book.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.12), control: CGPoint(x: rect.maxX - w * 0.24, y: rect.maxY - h * 0.06))
            book.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.10))
            book.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.16), control: CGPoint(x: rect.maxX - w * 0.22, y: rect.minY))
            book.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.16))
            book.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            stroke(&ctx, book, lw)
        case .journal:
            var medal = Path()
            medal.addEllipse(in: CGRect(x: rect.midX - w * 0.24, y: rect.minY, width: w * 0.48, height: w * 0.48))
            stroke(&ctx, medal, lw)
            var star = Path()
            let c = CGPoint(x: rect.midX, y: rect.minY + w * 0.24)
            for i in 0..<5 {
                let ang = CGFloat(i) * 2 * .pi / 5 - .pi / 2
                let pt = CGPoint(x: c.x + cos(ang) * w * 0.11, y: c.y + sin(ang) * w * 0.11)
                if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
                let ang2 = ang + .pi / 5
                star.addLine(to: CGPoint(x: c.x + cos(ang2) * w * 0.045, y: c.y + sin(ang2) * w * 0.045))
            }
            star.closeSubpath()
            ctx.fill(star, with: .color(color))
            var ribbons = Path()
            ribbons.move(to: CGPoint(x: rect.midX - w * 0.13, y: rect.minY + w * 0.44))
            ribbons.addLine(to: CGPoint(x: rect.midX - w * 0.20, y: rect.maxY))
            ribbons.move(to: CGPoint(x: rect.midX + w * 0.13, y: rect.minY + w * 0.44))
            ribbons.addLine(to: CGPoint(x: rect.midX + w * 0.20, y: rect.maxY))
            stroke(&ctx, ribbons, lw)
        case .play:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.16, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.16, y: rect.maxY))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        case .pause:
            var p = Path()
            p.addRoundedRect(in: CGRect(x: rect.minX + w * 0.14, y: rect.minY, width: w * 0.24, height: h), cornerSize: CGSize(width: 2, height: 2))
            p.addRoundedRect(in: CGRect(x: rect.maxX - w * 0.38, y: rect.minY, width: w * 0.24, height: h), cornerSize: CGSize(width: 2, height: 2))
            ctx.fill(p, with: .color(color))
        case .reverse:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.28))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.56))
            stroke(&ctx, p, lw)
            var arc = Path()
            arc.move(to: CGPoint(x: rect.minX + w * 0.04, y: rect.minY + h * 0.28))
            arc.addLine(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.minY + h * 0.28))
            arc.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.maxY), control: CGPoint(x: rect.maxX + w * 0.14, y: rect.minY + h * 0.64))
            arc.addLine(to: CGPoint(x: rect.minX + w * 0.2, y: rect.maxY))
            stroke(&ctx, arc, lw)
        case .rotate:
            var arc = Path()
            arc.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: w * 0.36, startAngle: Angle(degrees: -30), endAngle: Angle(degrees: 230), clockwise: false)
            stroke(&ctx, arc, lw)
            var head = Path()
            let tip = CGPoint(x: rect.midX + cos(CGFloat(-30) * .pi / 180) * w * 0.36, y: rect.midY + sin(CGFloat(-30) * .pi / 180) * w * 0.36)
            head.move(to: CGPoint(x: tip.x - w * 0.16, y: tip.y - w * 0.03))
            head.addLine(to: tip)
            head.addLine(to: CGPoint(x: tip.x - w * 0.02, y: tip.y - w * 0.18))
            stroke(&ctx, head, lw)
        case .eraser:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.32, y: rect.maxY - h * 0.10))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - h * 0.42))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.52, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.40))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.50, y: rect.maxY - h * 0.10))
            p.closeSubpath()
            stroke(&ctx, p, lw)
            var line = Path()
            line.move(to: CGPoint(x: rect.minX + w * 0.2, y: rect.maxY - h * 0.10))
            line.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.10))
            stroke(&ctx, line, lw)
        case .check:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY + h * 0.06))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.34, y: rect.maxY - h * 0.12))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.10))
            stroke(&ctx, p, lw * 1.2)
        case .lock:
            let bodyR = CGRect(x: rect.minX + w * 0.14, y: rect.midY - h * 0.04, width: w * 0.72, height: h * 0.56)
            stroke(&ctx, Path(roundedRect: bodyR, cornerRadius: w * 0.1), lw)
            var shackle = Path()
            shackle.addArc(center: CGPoint(x: rect.midX, y: rect.midY - h * 0.04), radius: w * 0.22, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 0), clockwise: false)
            stroke(&ctx, shackle, lw)
            ctx.fill(Path(ellipseIn: CGRect(x: rect.midX - w * 0.05, y: rect.midY + h * 0.14, width: w * 0.1, height: w * 0.1)), with: .color(color))
        case .chevronRight:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.3, y: rect.minY + h * 0.12))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.26, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.3, y: rect.maxY - h * 0.12))
            stroke(&ctx, p, lw * 1.1)
        case .chevronDown:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.12, y: rect.minY + h * 0.3))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.26))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.12, y: rect.minY + h * 0.3))
            stroke(&ctx, p, lw * 1.1)
        case .star:
            var star = Path()
            let c = CGPoint(x: rect.midX, y: rect.midY)
            for i in 0..<5 {
                let ang = CGFloat(i) * 2 * .pi / 5 - .pi / 2
                let pt = CGPoint(x: c.x + cos(ang) * w * 0.48, y: c.y + sin(ang) * w * 0.48)
                if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
                let ang2 = ang + .pi / 5
                star.addLine(to: CGPoint(x: c.x + cos(ang2) * w * 0.20, y: c.y + sin(ang2) * w * 0.20))
            }
            star.closeSubpath()
            ctx.fill(star, with: .color(color))
        case .lamp:
            var shade = Path()
            shade.move(to: CGPoint(x: rect.midX - w * 0.3, y: rect.minY + h * 0.34))
            shade.addLine(to: CGPoint(x: rect.midX - w * 0.14, y: rect.minY))
            shade.addLine(to: CGPoint(x: rect.midX + w * 0.14, y: rect.minY))
            shade.addLine(to: CGPoint(x: rect.midX + w * 0.3, y: rect.minY + h * 0.34))
            shade.closeSubpath()
            stroke(&ctx, shade, lw)
            var stem = Path()
            stem.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.34))
            stem.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.14))
            stem.move(to: CGPoint(x: rect.midX - w * 0.2, y: rect.maxY))
            stem.addLine(to: CGPoint(x: rect.midX + w * 0.2, y: rect.maxY))
            stroke(&ctx, stem, lw)
            for ray in [-0.6, 0.0, 0.6] {
                var r = Path()
                let a = CGFloat(ray) + .pi / 2
                r.move(to: CGPoint(x: rect.midX + cos(a) * w * 0.12, y: rect.minY + h * 0.40 + sin(a) * w * 0.06))
                r.addLine(to: CGPoint(x: rect.midX + cos(a) * w * 0.24, y: rect.minY + h * 0.40 + sin(a) * w * 0.18))
                stroke(&ctx, r, lw * 0.7)
            }
        case .close:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.14, y: rect.minY + h * 0.14))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.14, y: rect.maxY - h * 0.14))
            p.move(to: CGPoint(x: rect.maxX - w * 0.14, y: rect.minY + h * 0.14))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.14, y: rect.maxY - h * 0.14))
            stroke(&ctx, p, lw * 1.1)
        case .plus:
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.1))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.1))
            p.move(to: CGPoint(x: rect.minX + w * 0.1, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.1, y: rect.midY))
            stroke(&ctx, p, lw * 1.1)
        case .gauge:
            var arc = Path()
            arc.addArc(center: CGPoint(x: rect.midX, y: rect.maxY - h * 0.16), radius: w * 0.42, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 0), clockwise: false)
            stroke(&ctx, arc, lw)
            var needle = Path()
            needle.move(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.16))
            needle.addLine(to: CGPoint(x: rect.midX + w * 0.2, y: rect.minY + h * 0.22))
            stroke(&ctx, needle, lw)
            ctx.fill(Path(ellipseIn: CGRect(x: rect.midX - w * 0.06, y: rect.maxY - h * 0.22, width: w * 0.12, height: w * 0.12)), with: .color(color))
        case .book:
            let cover = Path(roundedRect: CGRect(x: rect.minX + w * 0.12, y: rect.minY, width: w * 0.76, height: h), cornerRadius: w * 0.06)
            stroke(&ctx, cover, lw)
            var spine = Path()
            spine.move(to: CGPoint(x: rect.minX + w * 0.26, y: rect.minY))
            spine.addLine(to: CGPoint(x: rect.minX + w * 0.26, y: rect.maxY))
            stroke(&ctx, spine, lw * 0.8)
        case .ribbon:
            var band = Path()
            band.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + h * 0.2, width: w, height: h * 0.32), cornerSize: CGSize(width: w * 0.06, height: w * 0.06))
            stroke(&ctx, band, lw)
            var tails = Path()
            tails.move(to: CGPoint(x: rect.midX - w * 0.16, y: rect.minY + h * 0.52))
            tails.addLine(to: CGPoint(x: rect.midX - w * 0.24, y: rect.maxY))
            tails.move(to: CGPoint(x: rect.midX + w * 0.16, y: rect.minY + h * 0.52))
            tails.addLine(to: CGPoint(x: rect.midX + w * 0.24, y: rect.maxY))
            stroke(&ctx, tails, lw)
        case .clock:
            stroke(&ctx, Path(ellipseIn: rect), lw)
            var hands = Path()
            hands.move(to: CGPoint(x: rect.midX, y: rect.midY))
            hands.addLine(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.22))
            hands.move(to: CGPoint(x: rect.midX, y: rect.midY))
            hands.addLine(to: CGPoint(x: rect.midX + w * 0.22, y: rect.midY + h * 0.1))
            stroke(&ctx, hands, lw)
        case .spanner:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.1, y: rect.maxY - h * 0.1))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY + h * 0.3))
            stroke(&ctx, p, lw * 1.4)
            var jaw = Path()
            jaw.addArc(center: CGPoint(x: rect.maxX - w * 0.22, y: rect.minY + h * 0.22), radius: w * 0.2, startAngle: Angle(degrees: 300), endAngle: Angle(degrees: 160), clockwise: false)
            stroke(&ctx, jaw, lw * 1.2)
        case .leaf:
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX - w * 0.1, y: rect.midY - h * 0.1))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX + w * 0.1, y: rect.midY + h * 0.1))
            stroke(&ctx, p, lw)
            var vein = Path()
            vein.move(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.08))
            vein.addLine(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.14))
            stroke(&ctx, vein, lw * 0.7)
        case .flag:
            var pole = Path()
            pole.move(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY))
            pole.addLine(to: CGPoint(x: rect.minX + w * 0.18, y: rect.maxY))
            stroke(&ctx, pole, lw)
            var flag = Path()
            flag.move(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.06))
            flag.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.2))
            flag.addLine(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.42))
            flag.closeSubpath()
            ctx.fill(flag, with: .color(color))
        }
    }
}
