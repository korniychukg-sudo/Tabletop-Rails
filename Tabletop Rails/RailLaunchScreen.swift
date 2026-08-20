import SwiftUI

struct RailLaunchScreen: View {
    @State private var wheelSpin = false
    @State private var puffPhase: CGFloat = 0

    var body: some View {
        ZStack {
            WoodBackdrop()
            VStack(spacing: 26) {
                Canvas { ctx, size in
                    let rect = CGRect(origin: .zero, size: size)
                    let baseY = rect.midY + rect.height * 0.16
                    var rail = Path()
                    rail.move(to: CGPoint(x: rect.minX, y: baseY + 6))
                    rail.addLine(to: CGPoint(x: rect.maxX, y: baseY + 6))
                    ctx.stroke(rail, with: .color(RailTheme.railShine.opacity(0.8)), lineWidth: 3)
                    for sx in stride(from: rect.minX, to: rect.maxX, by: 26) {
                        ctx.fill(Path(CGRect(x: sx, y: baseY + 2, width: 14, height: 6)), with: .color(RailTheme.sleeper.opacity(0.8)))
                    }
                    let bodyRect = CGRect(x: rect.midX - 60, y: baseY - 46, width: 120, height: 46)
                    ctx.fill(Path(roundedRect: bodyRect, cornerRadius: 10), with: .color(RailTheme.pine))
                    ctx.stroke(Path(roundedRect: bodyRect, cornerRadius: 10), with: .color(RailTheme.ink.opacity(0.5)), lineWidth: 1.4)
                    let cabRect = CGRect(x: bodyRect.maxX - 40, y: bodyRect.minY - 22, width: 40, height: 24)
                    ctx.fill(Path(roundedRect: cabRect, cornerRadius: 6), with: .color(RailTheme.pineDeep))
                    ctx.fill(Path(roundedRect: CGRect(x: cabRect.minX + 8, y: cabRect.minY + 6, width: 20, height: 12), cornerRadius: 3), with: .color(RailTheme.brassLight))
                    let chimney = CGRect(x: bodyRect.minX + 14, y: bodyRect.minY - 20, width: 16, height: 22)
                    ctx.fill(Path(roundedRect: chimney, cornerRadius: 3), with: .color(RailTheme.ink))
                    ctx.fill(Path(roundedRect: CGRect(x: chimney.minX - 3, y: chimney.minY - 5, width: 22, height: 7), cornerRadius: 2), with: .color(RailTheme.brass))
                    for i in 0..<3 {
                        let t = (puffPhase + CGFloat(i) * 0.33).truncatingRemainder(dividingBy: 1)
                        let r = 5 + t * 12
                        let px = chimney.midX + t * 42
                        let py = chimney.minY - 8 - t * 34
                        ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)), with: .color(Color.white.opacity(Double(0.4 * (1 - t)))))
                    }
                    for wx in [bodyRect.minX + 24, bodyRect.midX + 6, bodyRect.maxX - 22] {
                        let wr: CGFloat = 13
                        let c = CGPoint(x: wx, y: baseY - 6)
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - wr, y: c.y - wr, width: wr * 2, height: wr * 2)), with: .color(RailTheme.signalRedDark))
                        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - wr, y: c.y - wr, width: wr * 2, height: wr * 2)), with: .color(RailTheme.ink.opacity(0.6)), lineWidth: 1.6)
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(RailTheme.brass))
                    }
                }
                .frame(width: 260, height: 150)
                Text("Tabletop Rails")
                    .font(RailTheme.title(24))
                    .foregroundColor(RailTheme.cream)
                ZStack {
                    Capsule()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: 132, height: 6)
                    Capsule()
                        .fill(RailTheme.brassLight)
                        .frame(width: 46, height: 6)
                        .offset(x: wheelSpin ? 43 : -43)
                        .animation(Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: wheelSpin)
                }
            }
        }
        .onAppear {
            wheelSpin = true
            withAnimation(Animation.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                puffPhase = 1
            }
        }
    }
}
