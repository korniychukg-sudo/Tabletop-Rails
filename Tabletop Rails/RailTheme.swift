import SwiftUI

enum RailTheme {
    static let cream = Color(red: 0.965, green: 0.937, blue: 0.882)
    static let paper = Color(red: 0.984, green: 0.965, blue: 0.918)
    static let parchment = Color(red: 0.945, green: 0.906, blue: 0.827)
    static let oakLight = Color(red: 0.784, green: 0.608, blue: 0.400)
    static let oak = Color(red: 0.663, green: 0.486, blue: 0.294)
    static let oakDark = Color(red: 0.486, green: 0.337, blue: 0.188)
    static let oakShadow = Color(red: 0.357, green: 0.239, blue: 0.125)
    static let pine = Color(red: 0.180, green: 0.349, blue: 0.251)
    static let pineDeep = Color(red: 0.122, green: 0.243, blue: 0.176)
    static let pineLight = Color(red: 0.318, green: 0.478, blue: 0.365)
    static let brass = Color(red: 0.788, green: 0.635, blue: 0.294)
    static let brassLight = Color(red: 0.890, green: 0.784, blue: 0.498)
    static let brassDark = Color(red: 0.596, green: 0.459, blue: 0.176)
    static let ink = Color(red: 0.169, green: 0.129, blue: 0.094)
    static let inkSoft = Color(red: 0.337, green: 0.282, blue: 0.227)
    static let inkFaint = Color(red: 0.518, green: 0.459, blue: 0.392)
    static let signalRed = Color(red: 0.710, green: 0.263, blue: 0.184)
    static let signalRedDark = Color(red: 0.545, green: 0.184, blue: 0.125)
    static let matGrass = Color(red: 0.553, green: 0.647, blue: 0.396)
    static let matGrassDark = Color(red: 0.443, green: 0.541, blue: 0.310)
    static let matGrassLight = Color(red: 0.647, green: 0.729, blue: 0.482)
    static let ballast = Color(red: 0.706, green: 0.663, blue: 0.588)
    static let ballastDark = Color(red: 0.596, green: 0.549, blue: 0.471)
    static let sleeper = Color(red: 0.412, green: 0.310, blue: 0.208)
    static let railSteel = Color(red: 0.427, green: 0.400, blue: 0.365)
    static let railShine = Color(red: 0.694, green: 0.671, blue: 0.635)
    static let water = Color(red: 0.451, green: 0.612, blue: 0.663)
    static let waterDeep = Color(red: 0.337, green: 0.494, blue: 0.553)
    static let skyDay = Color(red: 0.788, green: 0.851, blue: 0.827)
    static let cardShadow = Color.black.opacity(0.10)

    static func title(_ size: CGFloat) -> Font { Font.system(size: size, weight: .bold, design: .rounded) }
    static func heading(_ size: CGFloat) -> Font { Font.system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat) -> Font { Font.system(size: size, weight: .regular, design: .rounded) }
    static func serif(_ size: CGFloat) -> Font { Font.custom("Georgia", size: size) }
    static func serifBold(_ size: CGFloat) -> Font { Font.custom("Georgia-Bold", size: size) }
    static func mono(_ size: CGFloat) -> Font { Font.system(size: size, weight: .medium, design: .monospaced) }
}

struct PaperBackdrop: View {
    var tone: Color = RailTheme.cream
    var body: some View {
        ZStack {
            tone
            GeometryReader { geo in
                Canvas { ctx, size in
                    var rng = SeededRandom(seed: 41)
                    for _ in 0..<220 {
                        let x = rng.next() * size.width
                        let y = rng.next() * size.height
                        let r = 0.6 + rng.next() * 1.4
                        let a = 0.02 + rng.next() * 0.04
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r * (0.6 + rng.next() * 0.8))), with: .color(RailTheme.ink.opacity(a)))
                    }
                    for i in 0..<14 {
                        let y = size.height * CGFloat(i) / 14 + rng.next() * 30
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addCurve(to: CGPoint(x: size.width, y: y + rng.next() * 24 - 12), control1: CGPoint(x: size.width * 0.3, y: y + rng.next() * 16 - 8), control2: CGPoint(x: size.width * 0.7, y: y + rng.next() * 16 - 8))
                        ctx.stroke(p, with: .color(RailTheme.oak.opacity(0.025)), lineWidth: 8 + rng.next() * 14)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct WoodBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(colors: [RailTheme.oakLight, RailTheme.oak]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                var rng = SeededRandom(seed: 7)
                let plankH: CGFloat = 64
                var y: CGFloat = 0
                while y < size.height {
                    ctx.stroke(Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    }, with: .color(RailTheme.oakShadow.opacity(0.35)), lineWidth: 1.4)
                    for _ in 0..<9 {
                        let gy = y + rng.next() * plankH
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: gy))
                        p.addCurve(to: CGPoint(x: size.width, y: gy + rng.next() * 10 - 5), control1: CGPoint(x: size.width * 0.35, y: gy + rng.next() * 8 - 4), control2: CGPoint(x: size.width * 0.65, y: gy + rng.next() * 8 - 4))
                        ctx.stroke(p, with: .color(RailTheme.oakDark.opacity(0.10 + rng.next() * 0.10)), lineWidth: 0.8 + rng.next() * 1.1)
                    }
                    if rng.next() > 0.45 {
                        let kx = rng.next() * size.width
                        let ky = y + 12 + rng.next() * (plankH - 24)
                        let kr = 3.5 + rng.next() * 4
                        ctx.stroke(Path(ellipseIn: CGRect(x: kx - kr, y: ky - kr * 0.7, width: kr * 2, height: kr * 1.4)), with: .color(RailTheme.oakShadow.opacity(0.4)), lineWidth: 1.2)
                        ctx.stroke(Path(ellipseIn: CGRect(x: kx - kr * 0.5, y: ky - kr * 0.35, width: kr, height: kr * 0.7)), with: .color(RailTheme.oakShadow.opacity(0.5)), lineWidth: 1)
                    }
                    y += plankH
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }
    mutating func nextInt(_ upper: Int) -> Int {
        guard upper > 0 else { return 0 }
        return Int(next() * CGFloat(upper)).clamped(0, upper - 1)
    }
}

extension Int {
    func clamped(_ lo: Int, _ hi: Int) -> Int { Swift.max(lo, Swift.min(hi, self)) }
}

extension Double {
    func clamped(_ lo: Double, _ hi: Double) -> Double { Swift.max(lo, Swift.min(hi, self)) }
}

extension CGFloat {
    func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { Swift.max(lo, Swift.min(hi, self)) }
}

struct RailHaptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func place() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
