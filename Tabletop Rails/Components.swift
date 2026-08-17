import SwiftUI

struct ArtImage: View {
    let name: String
    var contentMode: ContentMode = .fill

    var body: some View {
        if let ui = ArtImage.load(name) {
            Image(uiImage: ui)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            ZStack {
                LinearGradient(colors: [RailTheme.pineLight, RailTheme.pine], startPoint: .top, endPoint: .bottom)
                RIcon(kind: .depot, size: 42, color: RailTheme.cream.opacity(0.7))
            }
        }
    }

    static var cache = NSCache<NSString, UIImage>()

    static func load(_ name: String) -> UIImage? {
        if let hit = cache.object(forKey: name as NSString) { return hit }
        for ext in ["jpg", "png"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Art"),
               let img = UIImage(contentsOfFile: url.path) {
                cache.setObject(img, forKey: name as NSString)
                return img
            }
        }
        return nil
    }

    static func exists(_ name: String) -> Bool {
        load(name) != nil
    }
}

struct RailCard: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(RailTheme.paper)
                    .shadow(color: RailTheme.cardShadow, radius: 7, x: 0, y: 3)
            )
    }
}

extension View {
    func railCard(padding: CGFloat = 16) -> some View {
        modifier(RailCard(padding: padding))
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(RailTheme.title(21))
                .foregroundColor(RailTheme.ink)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(RailTheme.body(13))
                    .foregroundColor(RailTheme.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatChip: View {
    let icon: RIconKind
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            RIcon(kind: icon, size: 20, color: RailTheme.brassDark)
            Text(value)
                .font(RailTheme.title(16))
                .foregroundColor(RailTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(RailTheme.body(10))
                .foregroundColor(RailTheme.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(RailTheme.cream))
    }
}

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 7
    var color: Color = RailTheme.brass

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(progress.clamped(0, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

struct ProgressBar: View {
    let progress: Double
    var color: Color = RailTheme.brass
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.18))
                Capsule().fill(color)
                    .frame(width: max(height, geo.size.width * CGFloat(progress.clamped(0, 1))))
            }
        }
        .frame(height: height)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = RailTheme.pine

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RailTheme.heading(16))
            .foregroundColor(RailTheme.cream)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color)
                    .shadow(color: RailTheme.cardShadow, radius: 4, x: 0, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RailTheme.heading(15))
            .foregroundColor(RailTheme.pineDeep)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(RailTheme.pine.opacity(0.13)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var delay: Double
    var color: Color
    var spin: Double
    var size: CGFloat
}

struct ConfettiView: View {
    @State private var fall = false
    let pieces: [ConfettiPiece]

    init(seed: UInt64 = 7) {
        var rng = SeededRandom(seed: seed)
        var result: [ConfettiPiece] = []
        let colors = [RailTheme.brass, RailTheme.signalRed, RailTheme.pine, RailTheme.brassLight, RailTheme.oakLight]
        for i in 0..<36 {
            result.append(ConfettiPiece(
                x: rng.next(),
                delay: Double(rng.next()) * 0.5,
                color: colors[i % colors.count],
                spin: Double(rng.next()) * 720 - 360,
                size: 5 + rng.next() * 6))
        }
        pieces = result
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.62)
                        .rotationEffect(.degrees(fall ? piece.spin : 0))
                        .position(x: piece.x * geo.size.width, y: fall ? geo.size.height + 30 : -40)
                        .animation(.easeIn(duration: 1.6).delay(piece.delay), value: fall)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { fall = true }
    }
}

struct CelebrationBanner: View {
    let text: String
    let dismiss: () -> Void

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                RIcon(kind: .star, size: 20, color: RailTheme.brassLight)
                Text(text)
                    .font(RailTheme.heading(14))
                    .foregroundColor(RailTheme.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(RailTheme.pineDeep)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { dismiss() }
        }
        .onTapGesture { dismiss() }
    }
}

struct LockBadge: View {
    let rankName: String

    var body: some View {
        HStack(spacing: 5) {
            RIcon(kind: .lock, size: 12, color: RailTheme.inkFaint)
            Text(rankName)
                .font(RailTheme.body(10))
                .foregroundColor(RailTheme.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(RailTheme.ink.opacity(0.08)))
    }
}

struct AwardEmblem: View {
    let index: Int
    let earned: Bool
    var size: CGFloat = 56

    var body: some View {
        Canvas { ctx, canvasSize in
            let c = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let r = min(canvasSize.width, canvasSize.height) * 0.42
            let base = earned ? RailTheme.brass : Color(red: 0.72, green: 0.70, blue: 0.66)
            let dark = earned ? RailTheme.brassDark : Color(red: 0.55, green: 0.53, blue: 0.50)
            let light = earned ? RailTheme.brassLight : Color(red: 0.82, green: 0.80, blue: 0.77)
            var rim = Path()
            rim.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.fill(rim, with: .radialGradient(Gradient(colors: [light, base, dark]), center: CGPoint(x: c.x - r * 0.3, y: c.y - r * 0.3), startRadius: 0, endRadius: r * 1.6))
            ctx.stroke(rim, with: .color(dark), lineWidth: 1.6)
            var inner = Path()
            inner.addEllipse(in: CGRect(x: c.x - r * 0.78, y: c.y - r * 0.78, width: r * 1.56, height: r * 1.56))
            ctx.stroke(inner, with: .color(dark.opacity(0.7)), lineWidth: 0.9)
            let kind = index % 5
            var emblem = Path()
            switch kind {
            case 0:
                for i in 0..<5 {
                    let ang = CGFloat(i) * 2 * .pi / 5 - .pi / 2
                    let pt = CGPoint(x: c.x + cos(ang) * r * 0.5, y: c.y + sin(ang) * r * 0.5)
                    if i == 0 { emblem.move(to: pt) } else { emblem.addLine(to: pt) }
                    let ang2 = ang + .pi / 5
                    emblem.addLine(to: CGPoint(x: c.x + cos(ang2) * r * 0.22, y: c.y + sin(ang2) * r * 0.22))
                }
                emblem.closeSubpath()
            case 1:
                emblem.addEllipse(in: CGRect(x: c.x - r * 0.5, y: c.y - r * 0.5, width: r, height: r))
                emblem.move(to: CGPoint(x: c.x - r * 0.5, y: c.y))
                emblem.addLine(to: CGPoint(x: c.x + r * 0.5, y: c.y))
                emblem.move(to: CGPoint(x: c.x, y: c.y - r * 0.5))
                emblem.addLine(to: CGPoint(x: c.x, y: c.y + r * 0.5))
            case 2:
                emblem.move(to: CGPoint(x: c.x - r * 0.5, y: c.y + r * 0.3))
                emblem.addLine(to: CGPoint(x: c.x - r * 0.5, y: c.y - r * 0.1))
                emblem.addLine(to: CGPoint(x: c.x, y: c.y - r * 0.5))
                emblem.addLine(to: CGPoint(x: c.x + r * 0.5, y: c.y - r * 0.1))
                emblem.addLine(to: CGPoint(x: c.x + r * 0.5, y: c.y + r * 0.3))
                emblem.closeSubpath()
            case 3:
                emblem.addRoundedRect(in: CGRect(x: c.x - r * 0.45, y: c.y - r * 0.3, width: r * 0.9, height: r * 0.6), cornerSize: CGSize(width: r * 0.1, height: r * 0.1))
                emblem.move(to: CGPoint(x: c.x - r * 0.2, y: c.y + r * 0.3))
                emblem.addEllipse(in: CGRect(x: c.x - r * 0.34, y: c.y + r * 0.18, width: r * 0.24, height: r * 0.24))
                emblem.addEllipse(in: CGRect(x: c.x + r * 0.10, y: c.y + r * 0.18, width: r * 0.24, height: r * 0.24))
            default:
                emblem.move(to: CGPoint(x: c.x, y: c.y - r * 0.52))
                emblem.addLine(to: CGPoint(x: c.x + r * 0.5, y: c.y))
                emblem.addLine(to: CGPoint(x: c.x, y: c.y + r * 0.52))
                emblem.addLine(to: CGPoint(x: c.x - r * 0.5, y: c.y))
                emblem.closeSubpath()
            }
            ctx.stroke(emblem, with: .color(dark), lineWidth: 1.8)
            if !earned {
                var veil = Path()
                veil.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                ctx.fill(veil, with: .color(RailTheme.cream.opacity(0.45)))
            }
        }
        .frame(width: size, height: size)
    }
}

struct RailDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(RailTheme.ink.opacity(0.12)).frame(height: 1)
            Circle().fill(RailTheme.brass).frame(width: 5, height: 5)
            Rectangle().fill(RailTheme.ink.opacity(0.12)).frame(height: 1)
        }
    }
}
