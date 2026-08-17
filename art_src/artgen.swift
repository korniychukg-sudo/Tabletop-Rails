import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "./out"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

struct RGB {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    func cg(_ a: CGFloat = 1) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: a) }
    func mix(_ o: RGB, _ t: CGFloat) -> RGB { RGB(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t) }
    func darker(_ t: CGFloat) -> RGB { mix(RGB(r: 0.08, g: 0.06, b: 0.05), t) }
    func lighter(_ t: CGFloat) -> RGB { mix(RGB(r: 0.99, g: 0.97, b: 0.93), t) }
}

let paperTone = RGB(r: 0.955, g: 0.925, b: 0.860)
let paperEdge = RGB(r: 0.90, g: 0.85, b: 0.76)
let inkTone = RGB(r: 0.20, g: 0.16, b: 0.12)
let brassTone = RGB(r: 0.78, g: 0.63, b: 0.30)
let pineTone = RGB(r: 0.18, g: 0.35, b: 0.25)
let redTone = RGB(r: 0.68, g: 0.26, b: 0.19)
let steelTone = RGB(r: 0.45, g: 0.43, b: 0.40)
let grassTone = RGB(r: 0.55, g: 0.64, b: 0.40)
let skyTone = RGB(r: 0.80, g: 0.85, b: 0.82)

final class Rand {
    var state: UInt64
    init(_ seed: UInt64) { state = seed &* 2862933555777941757 &+ 3037000493 }
    func next() -> CGFloat {
        state = state &* 2862933555777941757 &+ 3037000493
        return CGFloat((state >> 33) & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }
    func range(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { lo + next() * (hi - lo) }
    func int(_ n: Int) -> Int { n <= 0 ? 0 : min(n - 1, Int(next() * CGFloat(n))) }
}

let renderScale: CGFloat = 1.7

func makeContext(_ w: Int, _ h: Int) -> CGContext {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let pw = Int(CGFloat(w) * renderScale)
    let ph = Int(CGFloat(h) * renderScale)
    let ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    ctx.scaleBy(x: renderScale, y: renderScale)
    return ctx
}

func saveJPEG(_ ctx: CGContext, _ name: String, quality: CGFloat = 0.90) {
    let img = ctx.makeImage()!
    let url = URL(fileURLWithPath: "\(outDir)/\(name).jpg") as CFURL
    let dest = CGImageDestinationCreateWithURL(url, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    CGImageDestinationFinalize(dest)
    print("wrote \(name).jpg \(ctx.width)x\(ctx.height)")
}

func savePNG(_ ctx: CGContext, _ path: String) {
    let img = ctx.makeImage()!
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(path)")
}

func drawText(_ ctx: CGContext, _ text: String, font: String, size: CGFloat, at p: CGPoint, color: CGColor, centered: Bool = true, tracking: CGFloat = 0) {
    let ctFont = CTFontCreateWithName(font as CFString, size, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): ctFont,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        NSAttributedString.Key(kCTKernAttributeName as String): tracking,
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(str)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.saveGState()
    ctx.textPosition = CGPoint(x: centered ? p.x - bounds.width / 2 : p.x, y: p.y)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

func paperBase(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat, seed: UInt64, tone: RGB = paperTone) {
    let rand = Rand(seed)
    ctx.setFillColor(tone.cg())
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let grad = CGGradient(colorsSpace: nil, colors: [tone.lighter(0.05).cg(), tone.cg(), paperEdge.cg()] as CFArray, locations: [0, 0.55, 1])!
    ctx.saveGState()
    ctx.drawRadialGradient(grad, startCenter: CGPoint(x: w * 0.5, y: h * 0.6), startRadius: 0, endCenter: CGPoint(x: w * 0.5, y: h * 0.5), endRadius: max(w, h) * 0.75, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
    for _ in 0..<2200 {
        let x = rand.next() * w
        let y = rand.next() * h
        let len = rand.range(2, 9)
        let ang = rand.next() * .pi
        ctx.setStrokeColor(inkTone.cg(rand.range(0.015, 0.05)))
        ctx.setLineWidth(rand.range(0.5, 1.1))
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + cos(ang) * len, y: y + sin(ang) * len))
        ctx.strokePath()
    }
    for _ in 0..<44 {
        let x = rand.next() * w
        let y = rand.next() * h
        let r = rand.range(6, 42)
        ctx.setFillColor(RGB(r: 0.72, g: 0.62, b: 0.45).cg(rand.range(0.02, 0.06)))
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r * 0.7, width: r * 2, height: r * 1.4))
    }
    for _ in 0..<Int(w * h / 70) {
        let x = rand.next() * w
        let y = rand.next() * h
        let d = rand.range(0.5, 1.3)
        ctx.setFillColor(inkTone.cg(rand.range(0.015, 0.045)))
        ctx.fill(CGRect(x: x, y: y, width: d, height: d))
    }
}

func plateFrame(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat, inset: CGFloat) {
    let outer = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
    ctx.setStrokeColor(inkTone.cg(0.75))
    ctx.setLineWidth(3)
    ctx.stroke(outer)
    ctx.setLineWidth(1.2)
    ctx.stroke(outer.insetBy(dx: 9, dy: 9))
    let corners = [
        CGPoint(x: outer.minX, y: outer.minY), CGPoint(x: outer.maxX, y: outer.minY),
        CGPoint(x: outer.minX, y: outer.maxY), CGPoint(x: outer.maxX, y: outer.maxY),
    ]
    for c in corners {
        ctx.setFillColor(inkTone.cg(0.8))
        let d: CGFloat = 7
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: .pi / 4)
        ctx.fill(CGRect(x: -d / 2, y: -d / 2, width: d, height: d))
        ctx.restoreGState()
    }
}

func wobblyLine(_ ctx: CGContext, from a: CGPoint, to b: CGPoint, rand: Rand, width: CGFloat, color: CGColor, wobble: CGFloat = 1.4) {
    let steps = max(3, Int(hypot(b.x - a.x, b.y - a.y) / 26))
    ctx.setStrokeColor(color)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.move(to: a)
    for i in 1...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let px = a.x + (b.x - a.x) * t + rand.range(-wobble, wobble)
        let py = a.y + (b.y - a.y) * t + rand.range(-wobble, wobble)
        ctx.addLine(to: CGPoint(x: px, y: py))
    }
    ctx.strokePath()
}

func inkRect(_ ctx: CGContext, _ rect: CGRect, rand: Rand, width: CGFloat = 2.4, color: CGColor = inkTone.cg(0.85)) {
    wobblyLine(ctx, from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.minY), rand: rand, width: width, color: color)
    wobblyLine(ctx, from: CGPoint(x: rect.maxX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.maxY), rand: rand, width: width, color: color)
    wobblyLine(ctx, from: CGPoint(x: rect.maxX, y: rect.maxY), to: CGPoint(x: rect.minX, y: rect.maxY), rand: rand, width: width, color: color)
    wobblyLine(ctx, from: CGPoint(x: rect.minX, y: rect.maxY), to: CGPoint(x: rect.minX, y: rect.minY), rand: rand, width: width, color: color)
}

func hatchRect(_ ctx: CGContext, _ rect: CGRect, rand: Rand, angle: CGFloat = -0.7, gap: CGFloat = 7, alpha: CGFloat = 0.28, width: CGFloat = 1.1) {
    ctx.saveGState()
    ctx.clip(to: rect)
    let diag = hypot(rect.width, rect.height)
    let n = Int(diag / gap) + 2
    let cx = rect.midX
    let cy = rect.midY
    let dirX = cos(angle)
    let dirY = sin(angle)
    let perpX = -dirY
    let perpY = dirX
    for i in -n...n {
        let off = CGFloat(i) * gap + rand.range(-1, 1)
        let baseX = cx + perpX * off
        let baseY = cy + perpY * off
        ctx.setStrokeColor(inkTone.cg(alpha * rand.range(0.7, 1.0)))
        ctx.setLineWidth(width)
        ctx.move(to: CGPoint(x: baseX - dirX * diag, y: baseY - dirY * diag))
        ctx.addLine(to: CGPoint(x: baseX + dirX * diag, y: baseY + dirY * diag))
        ctx.strokePath()
    }
    ctx.restoreGState()
}

func hatchPath(_ ctx: CGContext, _ path: CGPath, rand: Rand, angle: CGFloat = -0.7, gap: CGFloat = 7, alpha: CGFloat = 0.28, width: CGFloat = 1.1) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let rect = path.boundingBox
    let diag = hypot(rect.width, rect.height)
    let n = Int(diag / gap) + 2
    let dirX = cos(angle)
    let dirY = sin(angle)
    let perpX = -dirY
    let perpY = dirX
    for i in -n...n {
        let off = CGFloat(i) * gap + rand.range(-1, 1)
        let baseX = rect.midX + perpX * off
        let baseY = rect.midY + perpY * off
        ctx.setStrokeColor(inkTone.cg(alpha * rand.range(0.7, 1.0)))
        ctx.setLineWidth(width)
        ctx.move(to: CGPoint(x: baseX - dirX * diag, y: baseY - dirY * diag))
        ctx.addLine(to: CGPoint(x: baseX + dirX * diag, y: baseY + dirY * diag))
        ctx.strokePath()
    }
    ctx.restoreGState()
}

func groundShadow(_ ctx: CGContext, cx: CGFloat, y: CGFloat, w: CGFloat, rand: Rand) {
    let rect = CGRect(x: cx - w / 2, y: y - 14, width: w, height: 24)
    hatchRect(ctx, rect, rand: rand, angle: 0.05, gap: 5, alpha: 0.20, width: 1.0)
}

struct Livery {
    var body: RGB
    var roof: RGB
    var accent: RGB
}

func washFill(_ ctx: CGContext, _ path: CGPath, _ color: RGB, rand: Rand, alpha: CGFloat = 0.85) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let box = path.boundingBox
    ctx.setFillColor(color.cg(alpha))
    ctx.fill(box)
    let grad = CGGradient(colorsSpace: nil, colors: [color.lighter(0.25).cg(0.55), color.cg(0.0), color.darker(0.3).cg(0.45)] as CFArray, locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: box.minX, y: box.maxY), end: CGPoint(x: box.minX, y: box.minY), options: [])
    for _ in 0..<Int(box.width * box.height / 2400) {
        let x = box.minX + rand.next() * box.width
        let y = box.minY + rand.next() * box.height
        ctx.setFillColor(color.darker(0.35).cg(rand.range(0.03, 0.10)))
        ctx.fillEllipse(in: CGRect(x: x, y: y, width: rand.range(2, 7), height: rand.range(2, 5)))
    }
    ctx.restoreGState()
}

func rrect(_ r: CGRect, _ rad: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: min(rad, r.width / 2), cornerHeight: min(rad, r.height / 2), transform: nil)
}

func spokedWheel(_ ctx: CGContext, c: CGPoint, r: CGFloat, rand: Rand, spokes: Int = 10, accent: RGB) {
    let rim = CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2), transform: nil)
    washFill(ctx, rim, steelTone.darker(0.2), rand: rand, alpha: 0.35)
    ctx.setStrokeColor(inkTone.cg(0.9))
    ctx.setLineWidth(3.2)
    ctx.strokeEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    ctx.setLineWidth(1.6)
    ctx.strokeEllipse(in: CGRect(x: c.x - r * 0.82, y: c.y - r * 0.82, width: r * 1.64, height: r * 1.64))
    for i in 0..<spokes {
        let a = CGFloat(i) / CGFloat(spokes) * 2 * .pi + 0.15
        ctx.setStrokeColor(inkTone.cg(0.75))
        ctx.setLineWidth(1.8)
        ctx.move(to: CGPoint(x: c.x + cos(a) * r * 0.16, y: c.y + sin(a) * r * 0.16))
        ctx.addLine(to: CGPoint(x: c.x + cos(a) * r * 0.8, y: c.y + sin(a) * r * 0.8))
        ctx.strokePath()
    }
    ctx.setFillColor(accent.cg())
    ctx.fillEllipse(in: CGRect(x: c.x - r * 0.14, y: c.y - r * 0.14, width: r * 0.28, height: r * 0.28))
    ctx.setStrokeColor(inkTone.cg(0.9))
    ctx.setLineWidth(1.4)
    ctx.strokeEllipse(in: CGRect(x: c.x - r * 0.14, y: c.y - r * 0.14, width: r * 0.28, height: r * 0.28))
    hatchPath(ctx, CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y + r * 0.3, width: r * 2, height: r * 0.7), transform: nil), rand: rand, angle: -0.6, gap: 5, alpha: 0.2)
}

func smallWheel(_ ctx: CGContext, c: CGPoint, r: CGFloat, rand: Rand) {
    ctx.setFillColor(steelTone.cg(0.5))
    ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    ctx.setStrokeColor(inkTone.cg(0.9))
    ctx.setLineWidth(2.6)
    ctx.strokeEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    ctx.setFillColor(inkTone.cg(0.8))
    ctx.fillEllipse(in: CGRect(x: c.x - r * 0.16, y: c.y - r * 0.16, width: r * 0.32, height: r * 0.32))
}

func railLine(_ ctx: CGContext, y: CGFloat, minX: CGFloat, maxX: CGFloat, rand: Rand) {
    for sx in stride(from: minX, through: maxX, by: 34) {
        ctx.setFillColor(RGB(r: 0.42, g: 0.32, b: 0.22).cg(0.8))
        ctx.fill(CGRect(x: sx, y: y - 8, width: 22, height: 9))
        ctx.setStrokeColor(inkTone.cg(0.5))
        ctx.setLineWidth(1.2)
        ctx.stroke(CGRect(x: sx, y: y - 8, width: 22, height: 9))
    }
    wobblyLine(ctx, from: CGPoint(x: minX, y: y + 3), to: CGPoint(x: maxX, y: y + 3), rand: rand, width: 4.5, color: steelTone.cg(0.95), wobble: 0.7)
    wobblyLine(ctx, from: CGPoint(x: minX, y: y + 8), to: CGPoint(x: maxX, y: y + 8), rand: rand, width: 2.2, color: inkTone.cg(0.5), wobble: 0.7)
}

func drawSmoke(_ ctx: CGContext, from p: CGPoint, rand: Rand, count: Int = 5, drift: CGFloat = 1) {
    var cx = p.x
    var cy = p.y
    var r: CGFloat = 12
    for _ in 0..<count {
        ctx.setStrokeColor(inkTone.cg(rand.range(0.25, 0.45)))
        ctx.setLineWidth(2)
        let steps = 11
        var a0 = rand.next() * 2 * .pi
        ctx.move(to: CGPoint(x: cx + cos(a0) * r, y: cy + sin(a0) * r))
        for _ in 0..<steps {
            a0 += 2 * .pi / CGFloat(steps) + rand.range(-0.2, 0.2)
            let rr = r * rand.range(0.85, 1.15)
            ctx.addLine(to: CGPoint(x: cx + cos(a0) * rr, y: cy + sin(a0) * rr))
        }
        ctx.strokePath()
        cx += drift * rand.range(14, 30)
        cy += rand.range(22, 40)
        r *= rand.range(1.18, 1.4)
    }
}

func titleBlock(_ ctx: CGContext, w: CGFloat, name: String, sub: String, y: CGFloat = 92) {
    drawText(ctx, name.uppercased(), font: "Georgia-Bold", size: 54, at: CGPoint(x: w / 2, y: y + 34), color: inkTone.cg(0.92), tracking: 5)
    drawText(ctx, sub, font: "Georgia-Italic", size: 30, at: CGPoint(x: w / 2, y: y - 14), color: inkTone.cg(0.62))
    let lineW: CGFloat = 260
    let rand = Rand(9)
    wobblyLine(ctx, from: CGPoint(x: w / 2 - lineW, y: y + 12), to: CGPoint(x: w / 2 - 190, y: y + 12), rand: rand, width: 1.6, color: inkTone.cg(0.5))
    wobblyLine(ctx, from: CGPoint(x: w / 2 + 190, y: y + 12), to: CGPoint(x: w / 2 + lineW, y: y + 12), rand: rand, width: 1.6, color: inkTone.cg(0.5))
    ctx.setFillColor(brassTone.cg(0.9))
    ctx.fillEllipse(in: CGRect(x: w / 2 - 174, y: y + 8, width: 9, height: 9))
    ctx.fillEllipse(in: CGRect(x: w / 2 + 165, y: y + 8, width: 9, height: 9))
}

struct LocoSpec {
    var id: String
    var name: String
    var works: String
    var cls: String
    var livery: Livery
    var seed: UInt64
}

let locoSpecs: [LocoSpec] = [
    LocoSpec(id: "pip", name: "Pip", works: "Works No. 1 · Tank Engine", cls: "tank", livery: Livery(body: RGB(r: 0.18, g: 0.36, b: 0.27), roof: RGB(r: 0.13, g: 0.13, b: 0.13), accent: RGB(r: 0.85, g: 0.68, b: 0.32)), seed: 101),
    LocoSpec(id: "juniper", name: "Juniper", works: "Works No. 4 · Tank Engine", cls: "tank", livery: Livery(body: RGB(r: 0.55, g: 0.20, b: 0.16), roof: RGB(r: 0.15, g: 0.13, b: 0.12), accent: RGB(r: 0.90, g: 0.83, b: 0.62)), seed: 102),
    LocoSpec(id: "duchess", name: "Duchess of Fir", works: "Works No. 7 · Express Engine", cls: "tender", livery: Livery(body: RGB(r: 0.16, g: 0.22, b: 0.38), roof: RGB(r: 0.12, g: 0.12, b: 0.14), accent: RGB(r: 0.83, g: 0.66, b: 0.30)), seed: 103),
    LocoSpec(id: "bram", name: "Old Bram", works: "Works No. 3 · Freight Engine", cls: "tender", livery: Livery(body: RGB(r: 0.16, g: 0.15, b: 0.14), roof: RGB(r: 0.10, g: 0.10, b: 0.10), accent: RGB(r: 0.72, g: 0.32, b: 0.22)), seed: 104),
    LocoSpec(id: "wren", name: "Wren", works: "Works No. 11 · Railbus", cls: "railcar", livery: Livery(body: RGB(r: 0.62, g: 0.45, b: 0.18), roof: RGB(r: 0.82, g: 0.78, b: 0.70), accent: RGB(r: 0.30, g: 0.25, b: 0.18)), seed: 105),
    LocoSpec(id: "harlan", name: "Harlan", works: "Works No. 9 · Diesel Shunter", cls: "diesel", livery: Livery(body: RGB(r: 0.23, g: 0.34, b: 0.36), roof: RGB(r: 0.15, g: 0.18, b: 0.19), accent: RGB(r: 0.85, g: 0.72, b: 0.28)), seed: 106),
    LocoSpec(id: "comet", name: "Silver Comet", works: "Works No. 14 · Streamliner", cls: "streamliner", livery: Livery(body: RGB(r: 0.72, g: 0.72, b: 0.74), roof: RGB(r: 0.45, g: 0.45, b: 0.48), accent: RGB(r: 0.70, g: 0.24, b: 0.18)), seed: 107),
    LocoSpec(id: "greta", name: "Greta", works: "Works No. 17 · Electric", cls: "electric", livery: Livery(body: RGB(r: 0.44, g: 0.26, b: 0.42), roof: RGB(r: 0.20, g: 0.16, b: 0.20), accent: RGB(r: 0.88, g: 0.84, b: 0.75)), seed: 108),
    LocoSpec(id: "moss", name: "Little Moss", works: "Works No. 6 · Narrow Gauge", cls: "tank_small", livery: Livery(body: RGB(r: 0.35, g: 0.42, b: 0.25), roof: RGB(r: 0.16, g: 0.15, b: 0.12), accent: RGB(r: 0.78, g: 0.60, b: 0.28)), seed: 109),
    LocoSpec(id: "atlas", name: "Atlas", works: "Works No. 19 · Mountain Engine", cls: "tender_heavy", livery: Livery(body: RGB(r: 0.24, g: 0.20, b: 0.16), roof: RGB(r: 0.13, g: 0.12, b: 0.11), accent: RGB(r: 0.62, g: 0.68, b: 0.70)), seed: 110),
    LocoSpec(id: "nightowl", name: "Night Owl", works: "Works No. 21 · Sleeper Diesel", cls: "diesel_long", livery: Livery(body: RGB(r: 0.13, g: 0.17, b: 0.26), roof: RGB(r: 0.09, g: 0.11, b: 0.16), accent: RGB(r: 0.90, g: 0.78, b: 0.42)), seed: 111),
    LocoSpec(id: "magnolia", name: "Magnolia", works: "Works No. 23 · Excursion Engine", cls: "tender", livery: Livery(body: RGB(r: 0.36, g: 0.44, b: 0.40), roof: RGB(r: 0.14, g: 0.14, b: 0.13), accent: RGB(r: 0.86, g: 0.62, b: 0.60)), seed: 112),
    LocoSpec(id: "foreman", name: "The Foreman", works: "Works No. 25 · Road Switcher", cls: "diesel", livery: Livery(body: RGB(r: 0.65, g: 0.40, b: 0.14), roof: RGB(r: 0.25, g: 0.20, b: 0.14), accent: RGB(r: 0.20, g: 0.20, b: 0.20)), seed: 113),
    LocoSpec(id: "empress", name: "Empress of Dawn", works: "Works No. 28 · Crimson Flagship", cls: "streamliner", livery: Livery(body: RGB(r: 0.48, g: 0.16, b: 0.14), roof: RGB(r: 0.16, g: 0.12, b: 0.11), accent: RGB(r: 0.88, g: 0.72, b: 0.34)), seed: 114),
]

func drawLocoPlate(_ spec: LocoSpec) {
    let W = 1400, H = 1000
    let w = CGFloat(W), h = CGFloat(H)
    let ctx = makeContext(W, H)
    let rand = Rand(spec.seed)
    paperBase(ctx, w, h, seed: spec.seed)
    plateFrame(ctx, w, h, inset: 44)

    let railY: CGFloat = 300
    railLine(ctx, y: railY - 30, minX: 120, maxX: w - 120, rand: rand)
    groundShadow(ctx, cx: w / 2, y: railY - 46, w: 760, rand: rand)

    let liv = spec.livery
    let baseY = railY
    let cx = w / 2

    func rods(_ centers: [CGPoint], r: CGFloat) {
        guard centers.count >= 2 else { return }
        ctx.setStrokeColor(redTone.cg(0.9))
        ctx.setLineWidth(9)
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: centers[0].x, y: centers[0].y + r * 0.45))
        for c in centers.dropFirst() {
            ctx.addLine(to: CGPoint(x: c.x, y: c.y + r * 0.45))
        }
        ctx.strokePath()
        for c in centers {
            ctx.setFillColor(inkTone.cg(0.9))
            ctx.fillEllipse(in: CGRect(x: c.x - 6, y: c.y + r * 0.45 - 6, width: 12, height: 12))
        }
    }

    func chimney(_ x: CGFloat, topY: CGFloat, wd: CGFloat = 46) {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: x - wd / 2 + 6, y: topY))
        p.addLine(to: CGPoint(x: x - wd / 2, y: topY + 74))
        p.addLine(to: CGPoint(x: x + wd / 2, y: topY + 74))
        p.addLine(to: CGPoint(x: x + wd / 2 - 6, y: topY))
        p.closeSubpath()
        washFill(ctx, p, inkTone.lighter(0.1), rand: rand)
        ctx.addPath(p)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
        let cap = rrect(CGRect(x: x - wd / 2 - 8, y: topY + 60, width: wd + 16, height: 18), 6)
        washFill(ctx, cap, RGB(r: 0.72, g: 0.5, b: 0.32), rand: rand)
        ctx.addPath(cap)
        ctx.strokePath()
        drawSmoke(ctx, from: CGPoint(x: x + 8, y: topY + 120), rand: rand, count: 5)
    }

    func dome(_ x: CGFloat, topY: CGFloat) {
        let p = CGMutablePath()
        p.addArc(center: CGPoint(x: x, y: topY), radius: 30, startAngle: 0, endAngle: .pi, clockwise: false)
        p.closeSubpath()
        washFill(ctx, p, brassTone, rand: rand)
        ctx.addPath(p)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
    }

    func cabWindows(_ rect: CGRect) {
        washFill(ctx, rrect(rect, 8), skyTone.darker(0.1), rand: rand, alpha: 0.9)
        inkRect(ctx, rect, rand: rand, width: 2.6)
        ctx.setStrokeColor(RGB(r: 1, g: 1, b: 1).cg(0.5))
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 6))
        ctx.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.minY + 8))
        ctx.strokePath()
    }

    func boilerBands(_ rect: CGRect, count: Int) {
        for i in 1...count {
            let x = rect.minX + rect.width * CGFloat(i) / CGFloat(count + 1)
            ctx.setStrokeColor(liv.accent.cg(0.85))
            ctx.setLineWidth(5)
            ctx.move(to: CGPoint(x: x, y: rect.minY + 2))
            ctx.addLine(to: CGPoint(x: x, y: rect.maxY - 2))
            ctx.strokePath()
        }
    }

    func buffers(_ x: CGFloat, dir: CGFloat) {
        for dy in [26.0, 66.0] {
            ctx.setStrokeColor(inkTone.cg(0.9))
            ctx.setLineWidth(5)
            ctx.move(to: CGPoint(x: x, y: baseY + CGFloat(dy)))
            ctx.addLine(to: CGPoint(x: x + dir * 26, y: baseY + CGFloat(dy)))
            ctx.strokePath()
            ctx.setFillColor(steelTone.cg())
            ctx.fill(CGRect(x: x + dir * 26 - (dir < 0 ? 8 : 0), y: baseY + CGFloat(dy) - 13, width: 8, height: 26))
        }
    }

    switch spec.cls {
    case "tank", "tank_small":
        let scale: CGFloat = spec.cls == "tank_small" ? 0.78 : 1.0
        let bodyW = 620 * scale
        let left = cx - bodyW / 2
        let frame = rrect(CGRect(x: left, y: baseY, width: bodyW, height: 26), 4)
        washFill(ctx, frame, inkTone.lighter(0.15), rand: rand)
        let wr = 62 * scale
        let centers = [CGPoint(x: cx - 150 * scale, y: baseY), CGPoint(x: cx + 10 * scale, y: baseY), CGPoint(x: cx + 170 * scale, y: baseY)]
        for c in centers { spokedWheel(ctx, c: c, r: wr, rand: rand, accent: liv.accent) }
        rods(centers, r: wr)
        let tankRect = CGRect(x: left + 30, y: baseY + 26, width: bodyW - 220 * scale, height: 130 * scale)
        let tank = rrect(tankRect, 10)
        washFill(ctx, tank, liv.body, rand: rand)
        inkRect(ctx, tankRect, rand: rand)
        boilerBands(tankRect, count: 3)
        let boilerRect = CGRect(x: left + 10, y: baseY + 26 + 130 * scale, width: bodyW - 260 * scale, height: 82 * scale)
        let boiler = rrect(boilerRect, 40 * scale)
        washFill(ctx, boiler, liv.body.darker(0.12), rand: rand)
        ctx.addPath(boiler)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
        hatchPath(ctx, boiler, rand: rand, angle: -0.5, gap: 8, alpha: 0.18)
        chimney(left + 80 * scale, topY: boilerRect.maxY, wd: 44 * scale)
        dome(left + 210 * scale, topY: boilerRect.maxY - 4)
        let cabRect = CGRect(x: left + bodyW - 210 * scale, y: baseY + 26, width: 180 * scale, height: 240 * scale)
        washFill(ctx, rrect(cabRect, 12), liv.body, rand: rand)
        inkRect(ctx, cabRect, rand: rand)
        cabWindows(CGRect(x: cabRect.minX + 26, y: cabRect.maxY - 96 * scale, width: 70 * scale, height: 62 * scale))
        let roofRect = CGRect(x: cabRect.minX - 12, y: cabRect.maxY, width: cabRect.width + 24, height: 18)
        washFill(ctx, rrect(roofRect, 8), liv.roof, rand: rand)
        inkRect(ctx, roofRect, rand: rand, width: 2)
        buffers(left, dir: -1)
        buffers(left + bodyW, dir: 1)
    case "tender", "tender_heavy":
        let heavy = spec.cls == "tender_heavy"
        let bodyW: CGFloat = 560
        let left = cx - 440
        let frame = rrect(CGRect(x: left, y: baseY, width: bodyW, height: 26), 4)
        washFill(ctx, frame, inkTone.lighter(0.15), rand: rand)
        let wr: CGFloat = heavy ? 56 : 68
        var centers: [CGPoint] = []
        let count = heavy ? 4 : 3
        for i in 0..<count {
            centers.append(CGPoint(x: left + 150 + CGFloat(i) * (heavy ? 118 : 150), y: baseY))
        }
        smallWheel(ctx, c: CGPoint(x: left + 60, y: baseY - 6), r: 34, rand: rand)
        for c in centers { spokedWheel(ctx, c: c, r: wr, rand: rand, accent: liv.accent) }
        rods(centers, r: wr)
        let boilerRect = CGRect(x: left + 20, y: baseY + 42, width: bodyW - 170, height: 118)
        let boiler = rrect(boilerRect, 52)
        washFill(ctx, boiler, liv.body, rand: rand)
        ctx.addPath(boiler)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3.4)
        ctx.strokePath()
        boilerBands(boilerRect.insetBy(dx: 40, dy: 0), count: 3)
        hatchPath(ctx, boiler, rand: rand, angle: -0.5, gap: 9, alpha: 0.15)
        let smokeboxRect = CGRect(x: left + 8, y: baseY + 42, width: 74, height: 118)
        washFill(ctx, rrect(smokeboxRect, 14), inkTone.lighter(0.08), rand: rand)
        inkRect(ctx, smokeboxRect, rand: rand)
        chimney(left + 52, topY: baseY + 160)
        dome(left + 240, topY: baseY + 158)
        dome(left + 360, topY: baseY + 156)
        let cabRect = CGRect(x: left + bodyW - 160, y: baseY + 26, width: 150, height: 224)
        washFill(ctx, rrect(cabRect, 12), liv.body, rand: rand)
        inkRect(ctx, cabRect, rand: rand)
        cabWindows(CGRect(x: cabRect.minX + 22, y: cabRect.maxY - 90, width: 62, height: 56))
        let roofRect = CGRect(x: cabRect.minX - 10, y: cabRect.maxY, width: cabRect.width + 20, height: 16)
        washFill(ctx, rrect(roofRect, 8), liv.roof, rand: rand)
        inkRect(ctx, roofRect, rand: rand, width: 2)
        let tenderRect = CGRect(x: left + bodyW + 14, y: baseY + 20, width: 250, height: 170)
        washFill(ctx, rrect(tenderRect, 10), liv.body.darker(0.06), rand: rand)
        inkRect(ctx, tenderRect, rand: rand)
        ctx.setStrokeColor(liv.accent.cg(0.9))
        ctx.setLineWidth(4)
        ctx.stroke(tenderRect.insetBy(dx: 14, dy: 14))
        let coal = CGMutablePath()
        coal.move(to: CGPoint(x: tenderRect.minX + 16, y: tenderRect.maxY))
        for i in 0...8 {
            let t = CGFloat(i) / 8
            coal.addLine(to: CGPoint(x: tenderRect.minX + 16 + t * (tenderRect.width - 32), y: tenderRect.maxY + rand.range(4, 26)))
        }
        coal.addLine(to: CGPoint(x: tenderRect.maxX - 16, y: tenderRect.maxY))
        coal.closeSubpath()
        washFill(ctx, coal, inkTone, rand: rand, alpha: 0.95)
        for wx in [tenderRect.minX + 60, tenderRect.midX, tenderRect.maxX - 60] {
            smallWheel(ctx, c: CGPoint(x: wx, y: baseY - 2), r: 30, rand: rand)
        }
        buffers(left, dir: -1)
        buffers(tenderRect.maxX, dir: 1)
        if heavy {
            let plough = CGMutablePath()
            plough.move(to: CGPoint(x: left - 4, y: baseY - 20))
            plough.addLine(to: CGPoint(x: left - 44, y: baseY - 34))
            plough.addLine(to: CGPoint(x: left - 4, y: baseY + 40))
            plough.closeSubpath()
            washFill(ctx, plough, redTone, rand: rand)
            ctx.addPath(plough)
            ctx.setStrokeColor(inkTone.cg(0.9))
            ctx.setLineWidth(2.6)
            ctx.strokePath()
        }
    case "diesel", "diesel_long":
        let long = spec.cls == "diesel_long"
        let bodyW: CGFloat = long ? 860 : 700
        let left = cx - bodyW / 2
        let frame = rrect(CGRect(x: left, y: baseY, width: bodyW, height: 30), 4)
        washFill(ctx, frame, inkTone.lighter(0.15), rand: rand)
        for bx in [left + 90, left + 190, left + bodyW - 190, left + bodyW - 90] {
            smallWheel(ctx, c: CGPoint(x: bx, y: baseY - 4), r: 40, rand: rand)
        }
        let bodyRect = CGRect(x: left + 14, y: baseY + 30, width: bodyW - 28, height: 168)
        washFill(ctx, rrect(bodyRect, 22), liv.body, rand: rand)
        inkRect(ctx, bodyRect, rand: rand, width: 3)
        hatchRect(ctx, CGRect(x: bodyRect.minX, y: bodyRect.minY, width: bodyRect.width, height: 40), rand: rand, angle: -0.5, gap: 8, alpha: 0.14)
        for i in 0..<(long ? 7 : 5) {
            let gx = bodyRect.minX + 60 + CGFloat(i) * (bodyRect.width - 120) / CGFloat(long ? 6 : 4)
            let grill = CGRect(x: gx - 20, y: bodyRect.minY + 46, width: 40, height: 62)
            inkRect(ctx, grill, rand: rand, width: 2)
            for gy in stride(from: grill.minY + 8, to: grill.maxY, by: 10) {
                ctx.setStrokeColor(inkTone.cg(0.45))
                ctx.setLineWidth(1.6)
                ctx.move(to: CGPoint(x: grill.minX + 4, y: gy))
                ctx.addLine(to: CGPoint(x: grill.maxX - 4, y: gy))
                ctx.strokePath()
            }
        }
        let cabRect = CGRect(x: left + bodyW - 190, y: baseY + 30, width: 165, height: 214)
        washFill(ctx, rrect(cabRect, 16), liv.body.darker(0.05), rand: rand)
        inkRect(ctx, cabRect, rand: rand)
        cabWindows(CGRect(x: cabRect.minX + 24, y: cabRect.maxY - 88, width: 110, height: 60))
        for sx in stride(from: left + 30, to: left + 130, by: 22) {
            let stripe = CGMutablePath()
            stripe.move(to: CGPoint(x: sx, y: baseY + 34))
            stripe.addLine(to: CGPoint(x: sx + 14, y: baseY + 34))
            stripe.addLine(to: CGPoint(x: sx - 26, y: baseY + 194))
            stripe.addLine(to: CGPoint(x: sx - 40, y: baseY + 194))
            stripe.closeSubpath()
            ctx.addPath(stripe)
            ctx.setFillColor(liv.accent.cg(0.9))
            ctx.fillPath()
        }
        let roofRect = CGRect(x: left + 10, y: bodyRect.maxY, width: bodyW - 20, height: 20)
        washFill(ctx, rrect(roofRect, 10), liv.roof, rand: rand)
        inkRect(ctx, roofRect, rand: rand, width: 2)
        drawSmoke(ctx, from: CGPoint(x: left + 120, y: roofRect.maxY + 30), rand: rand, count: 3)
        buffers(left, dir: -1)
        buffers(left + bodyW, dir: 1)
        if long {
            drawText(ctx, "NIGHT OWL", font: "Georgia-Bold", size: 30, at: CGPoint(x: cx, y: bodyRect.midY - 10), color: liv.accent.cg(0.95), tracking: 4)
            ctx.setFillColor(liv.accent.cg(0.9))
            ctx.fillEllipse(in: CGRect(x: bodyRect.minX + 40, y: bodyRect.midY - 4, width: 30, height: 30))
        }
    case "electric":
        let bodyW: CGFloat = 640
        let left = cx - bodyW / 2
        let frame = rrect(CGRect(x: left, y: baseY, width: bodyW, height: 30), 4)
        washFill(ctx, frame, inkTone.lighter(0.15), rand: rand)
        for bx in [left + 100, left + 200, left + bodyW - 200, left + bodyW - 100] {
            smallWheel(ctx, c: CGPoint(x: bx, y: baseY - 4), r: 40, rand: rand)
        }
        let bodyRect = CGRect(x: left + 14, y: baseY + 30, width: bodyW - 28, height: 190)
        washFill(ctx, rrect(bodyRect, 26), liv.body, rand: rand)
        inkRect(ctx, bodyRect, rand: rand, width: 3)
        cabWindows(CGRect(x: bodyRect.minX + 26, y: bodyRect.maxY - 84, width: 74, height: 56))
        cabWindows(CGRect(x: bodyRect.maxX - 100, y: bodyRect.maxY - 84, width: 74, height: 56))
        for i in 0..<4 {
            let gx = bodyRect.minX + 150 + CGFloat(i) * (bodyRect.width - 300) / 3
            let vent = CGRect(x: gx - 22, y: bodyRect.minY + 34, width: 44, height: 74)
            inkRect(ctx, vent, rand: rand, width: 2)
            hatchRect(ctx, vent, rand: rand, angle: 0, gap: 7, alpha: 0.3)
        }
        ctx.setStrokeColor(liv.accent.cg(0.9))
        ctx.setLineWidth(6)
        ctx.move(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + 24))
        ctx.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.minY + 24))
        ctx.strokePath()
        let roofRect = CGRect(x: left + 8, y: bodyRect.maxY, width: bodyW - 16, height: 18)
        washFill(ctx, rrect(roofRect, 9), liv.roof, rand: rand)
        inkRect(ctx, roofRect, rand: rand, width: 2)
        for px in [cx - 160, cx + 100] {
            ctx.setStrokeColor(inkTone.cg(0.9))
            ctx.setLineWidth(4)
            ctx.move(to: CGPoint(x: px, y: roofRect.maxY))
            ctx.addLine(to: CGPoint(x: px + 30, y: roofRect.maxY + 56))
            ctx.addLine(to: CGPoint(x: px + 62, y: roofRect.maxY + 4))
            ctx.strokePath()
            ctx.setLineWidth(6)
            ctx.move(to: CGPoint(x: px + 6, y: roofRect.maxY + 60))
            ctx.addLine(to: CGPoint(x: px + 56, y: roofRect.maxY + 60))
            ctx.strokePath()
        }
        buffers(left, dir: -1)
        buffers(left + bodyW, dir: 1)
    case "streamliner":
        let bodyW: CGFloat = 880
        let left = cx - bodyW / 2
        let body = CGMutablePath()
        body.move(to: CGPoint(x: left + bodyW, y: baseY))
        body.addLine(to: CGPoint(x: left + 150, y: baseY))
        body.addCurve(to: CGPoint(x: left + 60, y: baseY + 120), control1: CGPoint(x: left + 60, y: baseY + 6), control2: CGPoint(x: left + 44, y: baseY + 60))
        body.addCurve(to: CGPoint(x: left + 250, y: baseY + 212), control1: CGPoint(x: left + 80, y: baseY + 190), control2: CGPoint(x: left + 150, y: baseY + 212))
        body.addLine(to: CGPoint(x: left + bodyW - 40, y: baseY + 212))
        body.addQuadCurve(to: CGPoint(x: left + bodyW, y: baseY + 150), control: CGPoint(x: left + bodyW, y: baseY + 208))
        body.closeSubpath()
        washFill(ctx, body, liv.body, rand: rand)
        ctx.addPath(body)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3.4)
        ctx.strokePath()
        hatchPath(ctx, body, rand: rand, angle: -0.45, gap: 10, alpha: 0.13)
        let nose = CGMutablePath()
        nose.move(to: CGPoint(x: left + 150, y: baseY))
        nose.addCurve(to: CGPoint(x: left + 60, y: baseY + 120), control1: CGPoint(x: left + 60, y: baseY + 6), control2: CGPoint(x: left + 44, y: baseY + 60))
        nose.addCurve(to: CGPoint(x: left + 190, y: baseY + 150), control1: CGPoint(x: left + 76, y: baseY + 150), control2: CGPoint(x: left + 120, y: baseY + 158))
        nose.addLine(to: CGPoint(x: left + 210, y: baseY))
        nose.closeSubpath()
        washFill(ctx, nose, liv.accent, rand: rand)
        ctx.addPath(nose)
        ctx.setStrokeColor(inkTone.cg(0.85))
        ctx.setLineWidth(2.6)
        ctx.strokePath()
        for i in 0..<3 {
            let sy = baseY + 96 + CGFloat(i) * 22
            ctx.setStrokeColor(liv.accent.cg(0.9))
            ctx.setLineWidth(7)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: left + 230, y: sy))
            ctx.addLine(to: CGPoint(x: left + bodyW - 60, y: sy))
            ctx.strokePath()
        }
        cabWindows(CGRect(x: left + 250, y: baseY + 150, width: 90, height: 44))
        for bx in stride(from: left + 160, to: left + bodyW - 60, by: 130) {
            ctx.setFillColor(inkTone.cg(0.75))
            ctx.fillEllipse(in: CGRect(x: bx, y: baseY - 62, width: 62, height: 62))
            ctx.setStrokeColor(inkTone.cg(0.9))
            ctx.setLineWidth(3)
            ctx.strokeEllipse(in: CGRect(x: bx, y: baseY - 62, width: 62, height: 62))
            ctx.setFillColor(steelTone.lighter(0.2).cg())
            ctx.fillEllipse(in: CGRect(x: bx + 20, y: baseY - 42, width: 22, height: 22))
        }
        let skirt = CGRect(x: left + 40, y: baseY - 20, width: bodyW - 80, height: 24)
        washFill(ctx, rrect(skirt, 10), liv.body.darker(0.2), rand: rand)
        ctx.setStrokeColor(inkTone.cg(0.7))
        ctx.setLineWidth(2.6)
        ctx.stroke(skirt)
    default:
        let bodyW: CGFloat = 560
        let left = cx - bodyW / 2
        let frame = rrect(CGRect(x: left, y: baseY, width: bodyW, height: 26), 4)
        washFill(ctx, frame, inkTone.lighter(0.15), rand: rand)
        for bx in [left + 90, left + bodyW - 90] {
            smallWheel(ctx, c: CGPoint(x: bx, y: baseY - 4), r: 38, rand: rand)
        }
        let bodyRect = CGRect(x: left + 12, y: baseY + 26, width: bodyW - 24, height: 170)
        washFill(ctx, rrect(bodyRect, 30), liv.body, rand: rand)
        inkRect(ctx, bodyRect, rand: rand, width: 3)
        for i in 0..<5 {
            let wx = bodyRect.minX + 40 + CGFloat(i) * (bodyRect.width - 80) / 4
            cabWindows(CGRect(x: wx - 28, y: bodyRect.midY - 4, width: 56, height: 54))
        }
        ctx.setStrokeColor(liv.roof.cg())
        ctx.setLineWidth(5)
        ctx.move(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + 30))
        ctx.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.minY + 30))
        ctx.strokePath()
        let roof = CGMutablePath()
        roof.move(to: CGPoint(x: bodyRect.minX - 6, y: bodyRect.maxY))
        roof.addQuadCurve(to: CGPoint(x: bodyRect.maxX + 6, y: bodyRect.maxY), control: CGPoint(x: bodyRect.midX, y: bodyRect.maxY + 40))
        roof.closeSubpath()
        washFill(ctx, roof, liv.roof, rand: rand)
        ctx.addPath(roof)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
        drawSmoke(ctx, from: CGPoint(x: bodyRect.maxX - 60, y: bodyRect.maxY + 60), rand: rand, count: 2)
    }

    titleBlock(ctx, w: w, name: spec.name, sub: spec.works)
    saveJPEG(ctx, "loco_\(spec.id)")
}

for spec in locoSpecs {
    drawLocoPlate(spec)
}

func scenicGround(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat, horizon: CGFloat, rand: Rand) {
    let sky = CGRect(x: 54, y: horizon, width: w - 108, height: h - horizon - 54)
    let skyGrad = CGGradient(colorsSpace: nil, colors: [skyTone.lighter(0.2).cg(0.9), skyTone.cg(0.5), paperTone.cg(0.0)] as CFArray, locations: [0, 0.6, 1])!
    ctx.saveGState()
    ctx.clip(to: sky)
    ctx.drawLinearGradient(skyGrad, start: CGPoint(x: 0, y: h - 54), end: CGPoint(x: 0, y: horizon), options: [])
    ctx.restoreGState()
    let ground = CGRect(x: 54, y: 54, width: w - 108, height: horizon - 54)
    ctx.saveGState()
    ctx.clip(to: ground)
    ctx.setFillColor(grassTone.cg(0.5))
    ctx.fill(ground)
    for _ in 0..<400 {
        let x = ground.minX + rand.next() * ground.width
        let y = ground.minY + rand.next() * ground.height
        ctx.setStrokeColor(pineTone.cg(rand.range(0.1, 0.3)))
        ctx.setLineWidth(1.2)
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + rand.range(-3, 3), y: y + rand.range(4, 10)))
        ctx.strokePath()
    }
    ctx.restoreGState()
}

func plateTree(_ ctx: CGContext, x: CGFloat, y: CGFloat, s: CGFloat, rand: Rand, pine: Bool) {
    groundShadow(ctx, cx: x, y: y - 4, w: s * 1.1, rand: rand)
    if pine {
        ctx.setFillColor(RGB(r: 0.42, g: 0.32, b: 0.22).cg())
        ctx.fill(CGRect(x: x - s * 0.04, y: y, width: s * 0.08, height: s * 0.22))
        for i in 0..<3 {
            let f = CGFloat(i)
            let tier = CGMutablePath()
            let tw = s * (0.66 - f * 0.16)
            let ty = y + s * (0.16 + f * 0.26)
            tier.move(to: CGPoint(x: x, y: ty + s * 0.34))
            tier.addLine(to: CGPoint(x: x - tw / 2, y: ty))
            tier.addLine(to: CGPoint(x: x + tw / 2, y: ty))
            tier.closeSubpath()
            washFill(ctx, tier, pineTone.lighter(f * 0.14), rand: rand)
            ctx.addPath(tier)
            ctx.setStrokeColor(inkTone.cg(0.7))
            ctx.setLineWidth(2)
            ctx.strokePath()
        }
    } else {
        ctx.setFillColor(RGB(r: 0.42, g: 0.32, b: 0.22).cg())
        ctx.fill(CGRect(x: x - s * 0.05, y: y, width: s * 0.1, height: s * 0.3))
        let canopy = CGMutablePath()
        for i in 0..<5 {
            let a = CGFloat(i) / 5 * 2 * .pi
            let r = s * rand.range(0.2, 0.3)
            canopy.addEllipse(in: CGRect(x: x + cos(a) * s * 0.2 - r, y: y + s * 0.5 + sin(a) * s * 0.14 - r, width: r * 2, height: r * 2))
        }
        washFill(ctx, canopy, RGB(r: 0.38, g: 0.5, b: 0.3), rand: rand)
        ctx.addPath(canopy)
        ctx.setStrokeColor(inkTone.cg(0.6))
        ctx.setLineWidth(2)
        ctx.strokePath()
    }
}

func plateCottage(_ ctx: CGContext, x: CGFloat, y: CGFloat, s: CGFloat, rand: Rand, red: Bool = false) {
    groundShadow(ctx, cx: x, y: y - 4, w: s * 1.2, rand: rand)
    let wallRect = CGRect(x: x - s / 2, y: y, width: s, height: s * 0.52)
    washFill(ctx, rrect(wallRect, 4), red ? RGB(r: 0.58, g: 0.24, b: 0.18) : RGB(r: 0.9, g: 0.86, b: 0.76), rand: rand)
    inkRect(ctx, wallRect, rand: rand)
    let roof = CGMutablePath()
    roof.move(to: CGPoint(x: x - s * 0.6, y: wallRect.maxY))
    roof.addLine(to: CGPoint(x: x, y: wallRect.maxY + s * 0.42))
    roof.addLine(to: CGPoint(x: x + s * 0.6, y: wallRect.maxY))
    roof.closeSubpath()
    washFill(ctx, roof, red ? inkTone.lighter(0.2) : redTone.darker(0.1), rand: rand)
    ctx.addPath(roof)
    ctx.setStrokeColor(inkTone.cg(0.85))
    ctx.setLineWidth(2.6)
    ctx.strokePath()
    hatchPath(ctx, roof, rand: rand, angle: -0.9, gap: 7, alpha: 0.22)
    ctx.setFillColor(RGB(r: 0.35, g: 0.26, b: 0.18).cg())
    ctx.fill(CGRect(x: x + s * 0.16, y: wallRect.maxY + s * 0.2, width: s * 0.1, height: s * 0.26))
    let winColor = RGB(r: 0.95, g: 0.82, b: 0.45)
    for wx in [x - s * 0.26, x + s * 0.12] {
        let win = CGRect(x: wx, y: y + s * 0.14, width: s * 0.16, height: s * 0.2)
        ctx.setFillColor(winColor.cg(0.9))
        ctx.fill(win)
        inkRect(ctx, win, rand: rand, width: 1.8)
    }
    let door = CGRect(x: x - s * 0.07, y: y, width: s * 0.14, height: s * 0.3)
    ctx.setFillColor(RGB(r: 0.35, g: 0.24, b: 0.15).cg())
    ctx.fill(door)
    inkRect(ctx, door, rand: rand, width: 1.8)
}

func drawGuidePlate(_ id: String, _ title: String, _ sub: String, draw: (CGContext, CGFloat, CGFloat, Rand) -> Void) {
    let W = 1400, H = 1000
    let w = CGFloat(W), h = CGFloat(H)
    let ctx = makeContext(W, H)
    let rand = Rand(UInt64(abs(id.hashValue % 100000)) &+ 17)
    paperBase(ctx, w, h, seed: UInt64(abs(id.hashValue % 100000)) &+ 3)
    plateFrame(ctx, w, h, inset: 44)
    draw(ctx, w, h, rand)
    titleBlock(ctx, w: w, name: title, sub: sub)
    saveJPEG(ctx, id)
}

drawGuidePlate("guide_gauge", "The Gauge", "Fig. I — the promise of spacing") { ctx, w, h, rand in
    let railY = h * 0.42
    railLine(ctx, y: railY, minX: 140, maxX: w - 140, rand: rand)
    railLine(ctx, y: railY + 130, minX: 140, maxX: w - 140, rand: rand)
    let cx = w / 2
    ctx.setStrokeColor(redTone.cg(0.9))
    ctx.setLineWidth(4)
    ctx.move(to: CGPoint(x: cx, y: railY + 12))
    ctx.addLine(to: CGPoint(x: cx, y: railY + 126))
    ctx.strokePath()
    for yy in [railY + 12, railY + 126] {
        ctx.move(to: CGPoint(x: cx - 16, y: yy))
        ctx.addLine(to: CGPoint(x: cx + 16, y: yy))
        ctx.strokePath()
    }
    drawText(ctx, "1435 mm", font: "Georgia-Bold", size: 40, at: CGPoint(x: cx + 120, y: railY + 58), color: redTone.cg(0.95))
    let caliper = CGMutablePath()
    caliper.move(to: CGPoint(x: cx - 300, y: railY + 200))
    caliper.addArc(center: CGPoint(x: cx - 300, y: railY + 130), radius: 70, startAngle: .pi / 2, endAngle: -.pi / 2, clockwise: true)
    ctx.addPath(caliper)
    ctx.setStrokeColor(inkTone.cg(0.85))
    ctx.setLineWidth(5)
    ctx.strokePath()
    for i in 0..<7 {
        let mx = 220 + CGFloat(i) * 44
        ctx.setStrokeColor(inkTone.cg(0.6))
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: mx, y: h * 0.72))
        ctx.addLine(to: CGPoint(x: mx, y: h * 0.72 + (i % 2 == 0 ? 30 : 18)))
        ctx.strokePath()
    }
    wobblyLine(ctx, from: CGPoint(x: 200, y: h * 0.72), to: CGPoint(x: 220 + 6 * 44 + 20, y: h * 0.72), rand: rand, width: 3, color: inkTone.cg(0.7))
}

drawGuidePlate("guide_switch", "The Turnout", "Fig. II — where track decides") { ctx, w, h, rand in
    let cy = h * 0.52
    let minX: CGFloat = 130
    let maxX = w - 130
    railLine(ctx, y: cy, minX: minX, maxX: maxX, rand: rand)
    for t in stride(from: 0.0, through: 1.0, by: 0.06) {
        let x = w * 0.44 + CGFloat(t) * (w - 130 - w * 0.44)
        let y = cy + CGFloat(t * t) * 170
        ctx.setFillColor(RGB(r: 0.42, g: 0.32, b: 0.22).cg(0.8))
        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.rotate(by: CGFloat(t) * 0.5)
        ctx.fill(CGRect(x: -11, y: -5, width: 22, height: 9))
        ctx.restoreGState()
    }
    let branch = CGMutablePath()
    branch.move(to: CGPoint(x: w * 0.44, y: cy + 5))
    branch.addQuadCurve(to: CGPoint(x: maxX, y: cy + 180), control: CGPoint(x: w * 0.72, y: cy + 20))
    ctx.addPath(branch)
    ctx.setStrokeColor(steelTone.cg(0.95))
    ctx.setLineWidth(4.5)
    ctx.strokePath()
    let branch2 = CGMutablePath()
    branch2.move(to: CGPoint(x: w * 0.47, y: cy + 3))
    branch2.addQuadCurve(to: CGPoint(x: maxX, y: cy + 150), control: CGPoint(x: w * 0.74, y: cy + 16))
    ctx.addPath(branch2)
    ctx.setLineWidth(4.5)
    ctx.strokePath()
    ctx.setStrokeColor(redTone.cg(0.95))
    ctx.setLineWidth(6)
    ctx.move(to: CGPoint(x: w * 0.36, y: cy + 6))
    ctx.addLine(to: CGPoint(x: w * 0.47, y: cy + 4))
    ctx.strokePath()
    drawText(ctx, "point blades", font: "Georgia-Italic", size: 30, at: CGPoint(x: w * 0.38, y: cy + 60), color: inkTone.cg(0.75))
    ctx.setStrokeColor(inkTone.cg(0.6))
    ctx.setLineWidth(2)
    ctx.move(to: CGPoint(x: w * 0.41, y: cy + 52))
    ctx.addLine(to: CGPoint(x: w * 0.42, y: cy + 14))
    ctx.strokePath()
    drawText(ctx, "the frog", font: "Georgia-Italic", size: 30, at: CGPoint(x: w * 0.62, y: cy - 66), color: inkTone.cg(0.75))
    ctx.move(to: CGPoint(x: w * 0.62, y: cy - 40))
    ctx.addLine(to: CGPoint(x: w * 0.615, y: cy - 6))
    ctx.strokePath()
    ctx.setFillColor(brassTone.cg())
    ctx.fillEllipse(in: CGRect(x: w * 0.33 - 26, y: cy + 120, width: 52, height: 52))
    ctx.setStrokeColor(inkTone.cg(0.85))
    ctx.setLineWidth(3)
    ctx.strokeEllipse(in: CGRect(x: w * 0.33 - 26, y: cy + 120, width: 52, height: 52))
    ctx.setStrokeColor(redTone.cg())
    ctx.setLineWidth(7)
    ctx.move(to: CGPoint(x: w * 0.33, y: cy + 146))
    ctx.addLine(to: CGPoint(x: w * 0.33 + 40, y: cy + 186))
    ctx.strokePath()
    hatchRect(ctx, CGRect(x: 100, y: cy - 220, width: w - 200, height: 130), rand: rand, angle: 0.06, gap: 9, alpha: 0.10)
    let locoRect = CGRect(x: 170, y: cy + 16, width: 200, height: 92)
    washFill(ctx, rrect(locoRect, 12), pineTone, rand: rand)
    inkRect(ctx, locoRect, rand: rand, width: 2.8)
    let cabR = CGRect(x: locoRect.minX + 10, y: locoRect.maxY - 4, width: 60, height: 44)
    washFill(ctx, rrect(cabR, 8), pineTone.darker(0.1), rand: rand)
    inkRect(ctx, cabR, rand: rand, width: 2.2)
    ctx.setFillColor(brassTone.cg())
    ctx.fillEllipse(in: CGRect(x: locoRect.maxX - 48, y: locoRect.maxY - 4, width: 22, height: 22))
    for wx in [locoRect.minX + 46, locoRect.midX + 20, locoRect.maxX - 34] {
        smallWheel(ctx, c: CGPoint(x: wx, y: locoRect.minY - 8), r: 22, rand: rand)
    }
    drawSmoke(ctx, from: CGPoint(x: locoRect.maxX - 36, y: locoRect.maxY + 40), rand: rand, count: 3)
    plateTree(ctx, x: w * 0.85, y: cy + 190, s: 120, rand: rand, pine: true)
    plateTree(ctx, x: w * 0.12, y: cy + 210, s: 100, rand: rand, pine: false)
}

drawGuidePlate("guide_signals", "The Semaphore", "Fig. III — the block made visible") { ctx, w, h, rand in
    let px = w * 0.38
    let baseY = h * 0.24
    wobblyLine(ctx, from: CGPoint(x: px, y: baseY), to: CGPoint(x: px, y: h * 0.78), rand: rand, width: 12, color: RGB(r: 0.88, g: 0.86, b: 0.8).cg())
    wobblyLine(ctx, from: CGPoint(x: px, y: baseY), to: CGPoint(x: px, y: h * 0.78), rand: rand, width: 3, color: inkTone.cg(0.8))
    groundShadow(ctx, cx: px, y: baseY - 6, w: 200, rand: rand)
    let armY = h * 0.72
    let arm = CGMutablePath()
    arm.move(to: CGPoint(x: px, y: armY))
    arm.addLine(to: CGPoint(x: px + 190, y: armY))
    arm.addLine(to: CGPoint(x: px + 190, y: armY - 34))
    arm.addLine(to: CGPoint(x: px, y: armY - 34))
    arm.closeSubpath()
    washFill(ctx, arm, redTone, rand: rand)
    ctx.addPath(arm)
    ctx.setStrokeColor(inkTone.cg(0.9))
    ctx.setLineWidth(3)
    ctx.strokePath()
    ctx.setFillColor(RGB(r: 0.95, g: 0.93, b: 0.88).cg())
    ctx.fill(CGRect(x: px + 130, y: armY - 34, width: 26, height: 34))
    let arm2 = CGMutablePath()
    arm2.move(to: CGPoint(x: px, y: h * 0.52))
    arm2.addLine(to: CGPoint(x: px + 170, y: h * 0.52 - 110))
    ctx.addPath(arm2)
    ctx.setStrokeColor(brassTone.darker(0.1).cg())
    ctx.setLineWidth(26)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.setStrokeColor(inkTone.cg(0.85))
    ctx.setLineWidth(3)
    ctx.strokePath()
    for (dy, col) in [(0.0, redTone), (48.0, RGB(r: 0.3, g: 0.55, b: 0.35))] {
        let lamp = CGRect(x: px - 40, y: armY - 60 - CGFloat(dy), width: 30, height: 30)
        ctx.setFillColor(col.cg())
        ctx.fillEllipse(in: lamp)
        ctx.setStrokeColor(inkTone.cg(0.85))
        ctx.setLineWidth(2.6)
        ctx.strokeEllipse(in: lamp)
    }
    let ladderX = px + 26
    for ly in stride(from: baseY + 30, to: armY - 40, by: 34) {
        ctx.setStrokeColor(inkTone.cg(0.6))
        ctx.setLineWidth(2.2)
        ctx.move(to: CGPoint(x: ladderX, y: ly))
        ctx.addLine(to: CGPoint(x: ladderX + 26, y: ly))
        ctx.strokePath()
    }
    ctx.setStrokeColor(inkTone.cg(0.6))
    ctx.setLineWidth(2.4)
    ctx.move(to: CGPoint(x: ladderX, y: baseY + 20))
    ctx.addLine(to: CGPoint(x: ladderX, y: armY - 34))
    ctx.move(to: CGPoint(x: ladderX + 26, y: baseY + 20))
    ctx.addLine(to: CGPoint(x: ladderX + 26, y: armY - 34))
    ctx.strokePath()
    railLine(ctx, y: baseY - 40, minX: 130, maxX: w - 130, rand: rand)
    drawText(ctx, "line clear", font: "Georgia-Italic", size: 30, at: CGPoint(x: px + 320, y: h * 0.52), color: inkTone.cg(0.7))
    drawText(ctx, "danger", font: "Georgia-Italic", size: 30, at: CGPoint(x: px + 330, y: armY - 14), color: inkTone.cg(0.7))
}

drawGuidePlate("guide_steam", "The Boiler", "Fig. IV — fire, water and motion") { ctx, w, h, rand in
    let cx = w / 2
    let cy = h * 0.5
    let boilerRect = CGRect(x: cx - 420, y: cy - 110, width: 660, height: 220)
    let boiler = rrect(boilerRect, 90)
    washFill(ctx, boiler, RGB(r: 0.35, g: 0.3, b: 0.28), rand: rand, alpha: 0.35)
    ctx.addPath(boiler)
    ctx.setStrokeColor(inkTone.cg(0.9))
    ctx.setLineWidth(4)
    ctx.strokePath()
    let fireRect = CGRect(x: boilerRect.maxX - 10, y: cy - 130, width: 180, height: 250)
    inkRect(ctx, fireRect, rand: rand, width: 3.4)
    let fire = CGMutablePath()
    fire.move(to: CGPoint(x: fireRect.minX + 20, y: fireRect.minY + 20))
    for i in 0..<6 {
        let fx = fireRect.minX + 20 + CGFloat(i) * (fireRect.width - 40) / 5
        fire.addLine(to: CGPoint(x: fx, y: fireRect.minY + 20 + (i % 2 == 0 ? 60 : 26) + rand.range(0, 20)))
    }
    fire.addLine(to: CGPoint(x: fireRect.maxX - 20, y: fireRect.minY + 20))
    fire.closeSubpath()
    washFill(ctx, fire, RGB(r: 0.85, g: 0.5, b: 0.2), rand: rand)
    ctx.addPath(fire)
    ctx.setStrokeColor(redTone.cg(0.9))
    ctx.setLineWidth(2.6)
    ctx.strokePath()
    for i in 0..<5 {
        let ty = boilerRect.minY + 40 + CGFloat(i) * 36
        ctx.setStrokeColor(inkTone.cg(0.55))
        ctx.setLineWidth(3)
        ctx.setLineDash(phase: 0, lengths: [14, 9])
        ctx.move(to: CGPoint(x: boilerRect.minX + 30, y: ty))
        ctx.addLine(to: CGPoint(x: boilerRect.maxX - 20, y: ty))
        ctx.strokePath()
        ctx.setLineDash(phase: 0, lengths: [])
    }
    let domeP = CGMutablePath()
    domeP.addArc(center: CGPoint(x: cx - 60, y: boilerRect.maxY), radius: 54, startAngle: 0, endAngle: .pi, clockwise: false)
    domeP.closeSubpath()
    washFill(ctx, domeP, brassTone, rand: rand)
    ctx.addPath(domeP)
    ctx.setStrokeColor(inkTone.cg(0.9))
    ctx.setLineWidth(3)
    ctx.strokePath()
    let chim = CGRect(x: boilerRect.minX + 40, y: boilerRect.maxY, width: 44, height: 80)
    washFill(ctx, rrect(chim, 6), inkTone.lighter(0.1), rand: rand)
    inkRect(ctx, chim, rand: rand)
    drawSmoke(ctx, from: CGPoint(x: chim.midX + 10, y: chim.maxY + 40), rand: rand, count: 4)
    drawText(ctx, "firebox", font: "Georgia-Italic", size: 28, at: CGPoint(x: fireRect.midX, y: fireRect.maxY + 22), color: inkTone.cg(0.7))
    drawText(ctx, "fire tubes", font: "Georgia-Italic", size: 28, at: CGPoint(x: cx - 90, y: cy - 6), color: inkTone.cg(0.85))
    drawText(ctx, "steam dome", font: "Georgia-Italic", size: 28, at: CGPoint(x: cx - 60, y: boilerRect.maxY + 74), color: inkTone.cg(0.7))
}

drawGuidePlate("guide_diesel", "New Power", "Fig. V — the button that ended steam") { ctx, w, h, rand in
    let cy = h * 0.44
    railLine(ctx, y: cy - 60, minX: 130, maxX: w - 130, rand: rand)
    let left = w * 0.2
    let bodyRect = CGRect(x: left, y: cy - 40, width: 520, height: 150)
    washFill(ctx, rrect(bodyRect, 18), RGB(r: 0.23, g: 0.34, b: 0.36), rand: rand)
    inkRect(ctx, bodyRect, rand: rand, width: 3)
    let cab = CGRect(x: bodyRect.maxX - 130, y: bodyRect.minY, width: 118, height: 190)
    washFill(ctx, rrect(cab, 14), RGB(r: 0.2, g: 0.3, b: 0.32), rand: rand)
    inkRect(ctx, cab, rand: rand)
    ctx.setFillColor(skyTone.cg(0.9))
    ctx.fill(CGRect(x: cab.minX + 18, y: cab.maxY - 70, width: 82, height: 46))
    for sx in stride(from: left + 16, to: left + 110, by: 24) {
        let stripe = CGMutablePath()
        stripe.move(to: CGPoint(x: sx, y: bodyRect.minY))
        stripe.addLine(to: CGPoint(x: sx + 12, y: bodyRect.minY))
        stripe.addLine(to: CGPoint(x: sx - 30, y: bodyRect.maxY))
        stripe.addLine(to: CGPoint(x: sx - 42, y: bodyRect.maxY))
        stripe.closeSubpath()
        ctx.addPath(stripe)
        ctx.setFillColor(RGB(r: 0.85, g: 0.72, b: 0.28).cg())
        ctx.fillPath()
    }
    for bx in [left + 90, left + 190, left + 350, left + 450] {
        smallWheel(ctx, c: CGPoint(x: bx, y: cy - 52), r: 30, rand: rand)
    }
    let wireY = h * 0.78
    wobblyLine(ctx, from: CGPoint(x: 130, y: wireY), to: CGPoint(x: w - 130, y: wireY), rand: rand, width: 3, color: inkTone.cg(0.7))
    let px = w * 0.68
    ctx.setStrokeColor(inkTone.cg(0.85))
    ctx.setLineWidth(4)
    ctx.move(to: CGPoint(x: px, y: wireY - 150))
    ctx.addLine(to: CGPoint(x: px + 40, y: wireY - 60))
    ctx.addLine(to: CGPoint(x: px + 84, y: wireY - 146))
    ctx.strokePath()
    ctx.setLineWidth(7)
    ctx.move(to: CGPoint(x: px + 14, y: wireY - 56))
    ctx.addLine(to: CGPoint(x: px + 66, y: wireY - 56))
    ctx.strokePath()
    ctx.setLineWidth(6)
    ctx.move(to: CGPoint(x: px + 30, y: wireY - 4))
    ctx.addLine(to: CGPoint(x: px + 50, y: wireY - 4))
    ctx.strokePath()
    drawText(ctx, "the pantograph kiss", font: "Georgia-Italic", size: 28, at: CGPoint(x: px + 44, y: wireY + 26), color: inkTone.cg(0.7))
    for i in 0..<4 {
        ctx.setStrokeColor(brassTone.cg(0.8))
        ctx.setLineWidth(2.4)
        let sx = px + 40
        let sy = wireY - 10
        let a = CGFloat(i) * 0.5 + 0.4
        ctx.move(to: CGPoint(x: sx, y: sy))
        ctx.addLine(to: CGPoint(x: sx + cos(a) * 26, y: sy + sin(a) * 26))
        ctx.strokePath()
    }
}

drawGuidePlate("guide_couplings", "The Handshake", "Fig. VI — buffers, links and knuckles") { ctx, w, h, rand in
    let cy = h * 0.52
    for (idx, bx) in [w * 0.30, w * 0.70].enumerated() {
        let dir: CGFloat = idx == 0 ? 1 : -1
        let bodyRect = CGRect(x: bx - dir * 300 - (dir < 0 ? 0 : 300) + (dir < 0 ? 0 : 0), y: cy - 90, width: 300, height: 190)
        let rect = dir > 0 ? CGRect(x: bx - 300, y: cy - 90, width: 280, height: 190) : CGRect(x: bx + 20, y: cy - 90, width: 280, height: 190)
        _ = bodyRect
        washFill(ctx, rrect(rect, 12), idx == 0 ? RGB(r: 0.42, g: 0.3, b: 0.22) : RGB(r: 0.52, g: 0.22, b: 0.18), rand: rand)
        inkRect(ctx, rect, rand: rand, width: 3)
        hatchRect(ctx, CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 44), rand: rand, gap: 7, alpha: 0.2)
        for dy in [-30.0, 42.0] {
            let bufX = dir > 0 ? rect.maxX : rect.minX - 26
            ctx.setStrokeColor(inkTone.cg(0.9))
            ctx.setLineWidth(6)
            ctx.move(to: CGPoint(x: dir > 0 ? rect.maxX : rect.minX, y: cy + CGFloat(dy)))
            ctx.addLine(to: CGPoint(x: dir > 0 ? rect.maxX + 26 : rect.minX - 26, y: cy + CGFloat(dy)))
            ctx.strokePath()
            ctx.setFillColor(steelTone.cg())
            ctx.fill(CGRect(x: bufX + (dir > 0 ? 26 : -8), y: cy + CGFloat(dy) - 18, width: 8, height: 36))
        }
    }
    let hookL = CGPoint(x: w * 0.30 + 6, y: cy + 8)
    let hookR = CGPoint(x: w * 0.70 - 6, y: cy + 8)
    for hook in [hookL, hookR] {
        ctx.setStrokeColor(inkTone.cg(0.95))
        ctx.setLineWidth(7)
        ctx.move(to: CGPoint(x: hook.x, y: hook.y + 30))
        ctx.addLine(to: CGPoint(x: hook.x, y: hook.y))
        ctx.strokePath()
    }
    var linkX = hookL.x + 14
    let linkW = (hookR.x - hookL.x - 28) / 3
    for _ in 0..<3 {
        ctx.setStrokeColor(steelTone.darker(0.1).cg())
        ctx.setLineWidth(9)
        ctx.strokeEllipse(in: CGRect(x: linkX, y: cy - 4, width: linkW, height: 34))
        ctx.setStrokeColor(inkTone.cg(0.5))
        ctx.setLineWidth(2)
        ctx.strokeEllipse(in: CGRect(x: linkX, y: cy - 4, width: linkW, height: 34))
        linkX += linkW - 8
    }
    drawText(ctx, "three loose links, one careful shunter", font: "Georgia-Italic", size: 30, at: CGPoint(x: w / 2, y: cy - 130), color: inkTone.cg(0.7))
    drawText(ctx, "buffers keep the peace", font: "Georgia-Italic", size: 28, at: CGPoint(x: w / 2, y: cy + 150), color: inkTone.cg(0.6))
}

drawGuidePlate("guide_timetable", "The Timetable", "Fig. VII — a railway's day in minutes") { ctx, w, h, rand in
    let sheet = CGRect(x: w * 0.16, y: h * 0.2, width: w * 0.42, height: h * 0.56)
    ctx.setFillColor(RGB(r: 0.97, g: 0.95, b: 0.89).cg())
    ctx.fill(sheet)
    inkRect(ctx, sheet, rand: rand, width: 3)
    hatchRect(ctx, CGRect(x: sheet.minX, y: sheet.minY, width: sheet.width, height: 10), rand: rand, gap: 4, alpha: 0.2)
    drawText(ctx, "WORKING TIMETABLE", font: "Georgia-Bold", size: 30, at: CGPoint(x: sheet.midX, y: sheet.maxY - 56), color: inkTone.cg(0.85), tracking: 3)
    wobblyLine(ctx, from: CGPoint(x: sheet.minX + 30, y: sheet.maxY - 76), to: CGPoint(x: sheet.maxX - 30, y: sheet.maxY - 76), rand: rand, width: 2, color: inkTone.cg(0.6))
    let rows = ["06:12  Milk & Mail", "07:40  Stopping Passenger", "09.05  Pickup Goods", "11:30  The Fast Express", "14:22  Empty Stock", "17:48  Evening Commuter", "23:59  The Sleeper"]
    for (i, row) in rows.enumerated() {
        drawText(ctx, row, font: "Georgia", size: 26, at: CGPoint(x: sheet.minX + 40, y: sheet.maxY - 130 - CGFloat(i) * 52), color: inkTone.cg(0.75), centered: false)
        ctx.setStrokeColor(inkTone.cg(0.2))
        ctx.setLineWidth(1.2)
        ctx.move(to: CGPoint(x: sheet.minX + 30, y: sheet.maxY - 146 - CGFloat(i) * 52))
        ctx.addLine(to: CGPoint(x: sheet.maxX - 30, y: sheet.maxY - 146 - CGFloat(i) * 52))
        ctx.strokePath()
    }
    let watchC = CGPoint(x: w * 0.75, y: h * 0.5)
    let watchR: CGFloat = 170
    ctx.setFillColor(RGB(r: 0.93, g: 0.9, b: 0.82).cg())
    ctx.fillEllipse(in: CGRect(x: watchC.x - watchR, y: watchC.y - watchR, width: watchR * 2, height: watchR * 2))
    ctx.setStrokeColor(brassTone.darker(0.1).cg())
    ctx.setLineWidth(12)
    ctx.strokeEllipse(in: CGRect(x: watchC.x - watchR, y: watchC.y - watchR, width: watchR * 2, height: watchR * 2))
    ctx.setStrokeColor(inkTone.cg(0.85))
    ctx.setLineWidth(3)
    ctx.strokeEllipse(in: CGRect(x: watchC.x - watchR, y: watchC.y - watchR, width: watchR * 2, height: watchR * 2))
    for i in 0..<12 {
        let a = CGFloat(i) / 12 * 2 * .pi
        ctx.setStrokeColor(inkTone.cg(0.8))
        ctx.setLineWidth(i % 3 == 0 ? 4 : 2)
        ctx.move(to: CGPoint(x: watchC.x + cos(a) * watchR * 0.82, y: watchC.y + sin(a) * watchR * 0.82))
        ctx.addLine(to: CGPoint(x: watchC.x + cos(a) * watchR * 0.92, y: watchC.y + sin(a) * watchR * 0.92))
        ctx.strokePath()
    }
    ctx.setStrokeColor(inkTone.cg(0.9))
    ctx.setLineWidth(6)
    ctx.move(to: watchC)
    ctx.addLine(to: CGPoint(x: watchC.x + cos(1.1) * watchR * 0.5, y: watchC.y + sin(1.1) * watchR * 0.5))
    ctx.strokePath()
    ctx.setLineWidth(4)
    ctx.move(to: watchC)
    ctx.addLine(to: CGPoint(x: watchC.x + cos(-0.6) * watchR * 0.72, y: watchC.y + sin(-0.6) * watchR * 0.72))
    ctx.strokePath()
    ctx.setFillColor(brassTone.cg())
    ctx.fill(CGRect(x: watchC.x - 20, y: watchC.y + watchR, width: 40, height: 34))
    ctx.setStrokeColor(inkTone.cg(0.8))
    ctx.setLineWidth(6)
    ctx.strokeEllipse(in: CGRect(x: watchC.x - 26, y: watchC.y + watchR + 30, width: 52, height: 40))
}

drawGuidePlate("guide_freight", "The Goods Trade", "Fig. VIII — what the wagons carried") { ctx, w, h, rand in
    let railY = h * 0.3
    railLine(ctx, y: railY, minX: 130, maxX: w - 130, rand: rand)
    var x = w * 0.14
    let vans: [(RGB, String)] = [
        (RGB(r: 0.42, g: 0.3, b: 0.22), "van"),
        (RGB(r: 0.24, g: 0.24, b: 0.26), "hopper"),
        (RGB(r: 0.8, g: 0.8, b: 0.78), "tank"),
        (RGB(r: 0.78, g: 0.82, b: 0.8), "ice"),
    ]
    for (col, kind) in vans {
        let rect = CGRect(x: x, y: railY + 14, width: 250, height: 150)
        if kind == "tank" {
            let tank = rrect(CGRect(x: x + 8, y: railY + 30, width: 234, height: 110), 55)
            washFill(ctx, tank, col, rand: rand)
            ctx.addPath(tank)
            ctx.setStrokeColor(inkTone.cg(0.9))
            ctx.setLineWidth(3)
            ctx.strokePath()
            ctx.setFillColor(steelTone.cg())
            ctx.fill(CGRect(x: x + 108, y: railY + 134, width: 34, height: 22))
        } else {
            washFill(ctx, rrect(rect, 8), col, rand: rand)
            inkRect(ctx, rect, rand: rand, width: 3)
            if kind == "hopper" {
                let heap = CGMutablePath()
                heap.move(to: CGPoint(x: rect.minX + 14, y: rect.maxY))
                for i in 0...6 {
                    heap.addLine(to: CGPoint(x: rect.minX + 14 + CGFloat(i) * (rect.width - 28) / 6, y: rect.maxY + rand.range(6, 30)))
                }
                heap.addLine(to: CGPoint(x: rect.maxX - 14, y: rect.maxY))
                heap.closeSubpath()
                washFill(ctx, heap, inkTone, rand: rand, alpha: 0.95)
            }
            if kind == "van" {
                ctx.setStrokeColor(inkTone.cg(0.6))
                ctx.setLineWidth(2)
                for px in stride(from: rect.minX + 20, to: rect.maxX, by: 24) {
                    ctx.move(to: CGPoint(x: px, y: rect.minY + 6))
                    ctx.addLine(to: CGPoint(x: px, y: rect.maxY - 6))
                    ctx.strokePath()
                }
                drawText(ctx, "GOODS", font: "Georgia-Bold", size: 26, at: CGPoint(x: rect.midX, y: rect.midY - 10), color: RGB(r: 0.92, g: 0.88, b: 0.8).cg(0.9), tracking: 2)
            }
            if kind == "ice" {
                drawText(ctx, "ICE", font: "Georgia-Bold", size: 30, at: CGPoint(x: rect.midX, y: rect.midY - 8), color: RGB(r: 0.3, g: 0.45, b: 0.5).cg(), tracking: 4)
                hatchRect(ctx, rect, rand: rand, angle: 0.8, gap: 16, alpha: 0.08)
            }
        }
        for wx in [x + 54, x + 196] {
            smallWheel(ctx, c: CGPoint(x: wx, y: railY - 12), r: 26, rand: rand)
        }
        x += 274
    }
    let craneX = w * 0.72
    let craneY = h * 0.52
    ctx.setStrokeColor(RGB(r: 0.42, g: 0.32, b: 0.22).cg())
    ctx.setLineWidth(16)
    ctx.move(to: CGPoint(x: craneX, y: craneY))
    ctx.addLine(to: CGPoint(x: craneX, y: craneY + 240))
    ctx.strokePath()
    ctx.setLineWidth(10)
    ctx.move(to: CGPoint(x: craneX - 6, y: craneY + 210))
    ctx.addLine(to: CGPoint(x: craneX - 260, y: craneY + 120))
    ctx.strokePath()
    ctx.setStrokeColor(inkTone.cg(0.7))
    ctx.setLineWidth(2.6)
    ctx.move(to: CGPoint(x: craneX - 250, y: craneY + 122))
    ctx.addLine(to: CGPoint(x: craneX - 250, y: craneY + 40))
    ctx.strokePath()
    let crate = CGRect(x: craneX - 290, y: craneY - 20, width: 80, height: 62)
    washFill(ctx, rrect(crate, 4), RGB(r: 0.62, g: 0.48, b: 0.3), rand: rand)
    inkRect(ctx, crate, rand: rand, width: 2.6)
    ctx.setStrokeColor(inkTone.cg(0.6))
    ctx.setLineWidth(2)
    ctx.move(to: CGPoint(x: crate.minX, y: crate.minY))
    ctx.addLine(to: CGPoint(x: crate.maxX, y: crate.maxY))
    ctx.move(to: CGPoint(x: crate.maxX, y: crate.minY))
    ctx.addLine(to: CGPoint(x: crate.minX, y: crate.maxY))
    ctx.strokePath()
    drawText(ctx, "coal out, breakfast in", font: "Georgia-Italic", size: 30, at: CGPoint(x: w / 2, y: h * 0.78), color: inkTone.cg(0.65))
}

drawGuidePlate("guide_scenery", "The Baseboard Art", "Fig. IX — making a table a world") { ctx, w, h, rand in
    scenicGround(ctx, w, h, horizon: h * 0.56, rand: rand)
    let hill = CGMutablePath()
    hill.move(to: CGPoint(x: 54, y: h * 0.56))
    hill.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.56), control: CGPoint(x: w * 0.25, y: h * 0.74))
    hill.closeSubpath()
    washFill(ctx, hill, grassTone.darker(0.05), rand: rand)
    ctx.addPath(hill)
    ctx.setStrokeColor(inkTone.cg(0.6))
    ctx.setLineWidth(2.6)
    ctx.strokePath()
    let portal = CGMutablePath()
    let px = w * 0.30
    portal.move(to: CGPoint(x: px - 60, y: h * 0.56))
    portal.addLine(to: CGPoint(x: px - 60, y: h * 0.62))
    portal.addArc(center: CGPoint(x: px, y: h * 0.62), radius: 60, startAngle: .pi, endAngle: 0, clockwise: true)
    portal.addLine(to: CGPoint(x: px + 60, y: h * 0.56))
    portal.closeSubpath()
    washFill(ctx, portal, RGB(r: 0.55, g: 0.5, b: 0.45), rand: rand)
    ctx.addPath(portal)
    ctx.setStrokeColor(inkTone.cg(0.85))
    ctx.setLineWidth(3)
    ctx.strokePath()
    ctx.setFillColor(inkTone.cg(0.9))
    let hole = CGMutablePath()
    hole.move(to: CGPoint(x: px - 40, y: h * 0.56))
    hole.addLine(to: CGPoint(x: px - 40, y: h * 0.61))
    hole.addArc(center: CGPoint(x: px, y: h * 0.61), radius: 40, startAngle: .pi, endAngle: 0, clockwise: true)
    hole.addLine(to: CGPoint(x: px + 40, y: h * 0.56))
    hole.closeSubpath()
    ctx.addPath(hole)
    ctx.fillPath()
    railLine(ctx, y: h * 0.52, minX: 100, maxX: w - 100, rand: rand)
    plateTree(ctx, x: w * 0.6, y: h * 0.60, s: 150, rand: rand, pine: true)
    plateTree(ctx, x: w * 0.68, y: h * 0.57, s: 120, rand: rand, pine: false)
    plateCottage(ctx, x: w * 0.82, y: h * 0.60, s: 160, rand: rand)
    let mirror = CGRect(x: w * 0.42, y: h * 0.24, width: 220, height: 120)
    let pond = CGPath(ellipseIn: mirror, transform: nil)
    washFill(ctx, pond, RGB(r: 0.45, g: 0.61, b: 0.66), rand: rand)
    ctx.addPath(pond)
    ctx.setStrokeColor(RGB(r: 0.72, g: 0.66, b: 0.5).cg())
    ctx.setLineWidth(4)
    ctx.strokePath()
    for i in 0..<3 {
        ctx.setStrokeColor(RGB(r: 1, g: 1, b: 1).cg(0.4))
        ctx.setLineWidth(2)
        let ry = mirror.midY - 20 + CGFloat(i) * 20
        ctx.move(to: CGPoint(x: mirror.minX + 40, y: ry))
        ctx.addQuadCurve(to: CGPoint(x: mirror.maxX - 40, y: ry), control: CGPoint(x: mirror.midX, y: ry + 8))
        ctx.strokePath()
    }
    for i in 0..<4 {
        let sx = w * 0.15 + CGFloat(i) * 30
        ctx.setStrokeColor(inkTone.cg(0.7))
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: sx, y: h * 0.30))
        ctx.addLine(to: CGPoint(x: sx, y: h * 0.36))
        ctx.strokePath()
    }
    wobblyLine(ctx, from: CGPoint(x: w * 0.13, y: h * 0.33), to: CGPoint(x: w * 0.15 + 100, y: h * 0.33), rand: rand, width: 2.6, color: RGB(r: 0.42, g: 0.32, b: 0.22).cg())
    let sheepX = w * 0.19
    let sheepY = h * 0.24
    ctx.setFillColor(RGB(r: 0.93, g: 0.91, b: 0.86).cg())
    ctx.fillEllipse(in: CGRect(x: sheepX, y: sheepY, width: 54, height: 34))
    ctx.setStrokeColor(inkTone.cg(0.7))
    ctx.setLineWidth(2)
    ctx.strokeEllipse(in: CGRect(x: sheepX, y: sheepY, width: 54, height: 34))
    ctx.setFillColor(inkTone.cg(0.85))
    ctx.fillEllipse(in: CGRect(x: sheepX + 44, y: sheepY + 12, width: 16, height: 12))
}

drawGuidePlate("guide_history", "Small Trains", "Fig. X — a hundred and fifty years of wonder") { ctx, w, h, rand in
    let cx = w / 2
    let cy = h * 0.42
    railLine(ctx, y: cy - 50, minX: w * 0.2, maxX: w * 0.8, rand: rand)
    let bodyRect = CGRect(x: cx - 210, y: cy - 30, width: 300, height: 130)
    washFill(ctx, rrect(bodyRect, 14), RGB(r: 0.55, g: 0.25, b: 0.2), rand: rand)
    inkRect(ctx, bodyRect, rand: rand, width: 3)
    ctx.setStrokeColor(brassTone.cg(0.9))
    ctx.setLineWidth(4)
    ctx.stroke(bodyRect.insetBy(dx: 12, dy: 12))
    let boiler = rrect(CGRect(x: cx - 190, y: cy + 100, width: 200, height: 70), 35)
    washFill(ctx, boiler, RGB(r: 0.3, g: 0.42, b: 0.5), rand: rand)
    ctx.addPath(boiler)
    ctx.setStrokeColor(inkTone.cg(0.9))
    ctx.setLineWidth(3)
    ctx.strokePath()
    let chim = CGRect(x: cx - 160, y: cy + 170, width: 30, height: 50)
    washFill(ctx, rrect(chim, 5), brassTone, rand: rand)
    inkRect(ctx, chim, rand: rand, width: 2.4)
    let cab = CGRect(x: cx + 20, y: cy + 100, width: 70, height: 100)
    washFill(ctx, rrect(cab, 8), RGB(r: 0.55, g: 0.25, b: 0.2), rand: rand)
    inkRect(ctx, cab, rand: rand, width: 2.4)
    for wx in [cx - 150, cx - 40, cx + 40] {
        spokedWheel(ctx, c: CGPoint(x: wx, y: cy - 34), r: 40, rand: rand, spokes: 8, accent: brassTone)
    }
    let keyC = CGPoint(x: cx + 210, y: cy + 60)
    ctx.setStrokeColor(brassTone.darker(0.1).cg())
    ctx.setLineWidth(12)
    ctx.move(to: CGPoint(x: keyC.x - 70, y: keyC.y))
    ctx.addLine(to: keyC)
    ctx.strokePath()
    ctx.setLineWidth(9)
    ctx.strokeEllipse(in: CGRect(x: keyC.x, y: keyC.y - 34, width: 68, height: 68))
    ctx.setStrokeColor(inkTone.cg(0.7))
    ctx.setLineWidth(2.4)
    ctx.strokeEllipse(in: CGRect(x: keyC.x, y: keyC.y - 34, width: 68, height: 68))
    drawText(ctx, "wind fully — do not overwind", font: "Georgia-Italic", size: 26, at: CGPoint(x: cx + 160, y: cy - 100), color: inkTone.cg(0.6))
    for (i, year) in ["1840", "1901", "1938", "TODAY"].enumerated() {
        let bx = w * 0.2 + CGFloat(i) * w * 0.2
        ctx.setFillColor(brassTone.cg(0.9))
        ctx.fillEllipse(in: CGRect(x: bx - 7, y: h * 0.74 - 7, width: 14, height: 14))
        drawText(ctx, year, font: "Georgia-Bold", size: 26, at: CGPoint(x: bx, y: h * 0.74 + 22), color: inkTone.cg(0.75), tracking: 1)
    }
    wobblyLine(ctx, from: CGPoint(x: w * 0.17, y: h * 0.74), to: CGPoint(x: w * 0.83, y: h * 0.74), rand: rand, width: 3, color: inkTone.cg(0.55))
}

func drawOnboarding(_ id: String, _ index: Int) {
    let W = 1200, H = 1600
    let w = CGFloat(W), h = CGFloat(H)
    let ctx = makeContext(W, H)
    let rand = Rand(UInt64(700 + index))
    paperBase(ctx, w, h, seed: UInt64(41 + index))
    plateFrame(ctx, w, h, inset: 40)
    switch index {
    case 0:
        let tableRect = CGRect(x: w * 0.14, y: h * 0.30, width: w * 0.72, height: h * 0.46)
        let frameRect = tableRect.insetBy(dx: -34, dy: -34)
        washFill(ctx, rrect(frameRect, 26), RGB(r: 0.52, g: 0.37, b: 0.22), rand: rand)
        inkRect(ctx, frameRect, rand: rand, width: 3.4)
        washFill(ctx, rrect(tableRect, 16), grassTone, rand: rand)
        inkRect(ctx, tableRect, rand: rand, width: 2.6)
        let cx = tableRect.midX
        let cy = tableRect.midY
        let rx = tableRect.width * 0.32
        let ry = tableRect.height * 0.30
        for gauge in [-9.0, 9.0] {
            ctx.setStrokeColor(steelTone.cg(0.95))
            ctx.setLineWidth(5)
            ctx.strokeEllipse(in: CGRect(x: cx - rx - CGFloat(gauge), y: cy - ry - CGFloat(gauge), width: (rx + CGFloat(gauge)) * 2, height: (ry + CGFloat(gauge)) * 2))
        }
        for i in 0..<26 {
            let a = CGFloat(i) / 26 * 2 * .pi
            let px = cx + cos(a) * rx
            let py = cy + sin(a) * ry
            ctx.saveGState()
            ctx.translateBy(x: px, y: py)
            ctx.rotate(by: atan2(-sin(a) * rx, cos(a) * ry) + .pi / 2)
            ctx.setFillColor(RGB(r: 0.42, g: 0.32, b: 0.22).cg(0.85))
            ctx.fill(CGRect(x: -13, y: -5, width: 26, height: 10))
            ctx.restoreGState()
        }
        plateTree(ctx, x: cx - rx * 0.3, y: cy - 30, s: 110, rand: rand, pine: true)
        plateTree(ctx, x: cx + rx * 0.45, y: cy - 10, s: 90, rand: rand, pine: false)
        plateCottage(ctx, x: cx, y: cy + ry * 0.25, s: 110, rand: rand)
        let locoRect = CGRect(x: cx + rx - 60, y: cy - 24, width: 110, height: 48)
        washFill(ctx, rrect(locoRect, 10), pineTone, rand: rand)
        inkRect(ctx, locoRect, rand: rand, width: 2.4)
        drawSmoke(ctx, from: CGPoint(x: locoRect.maxX - 16, y: locoRect.maxY + 20), rand: rand, count: 3)
        drawText(ctx, "PLATE THE FIRST", font: "Georgia-Bold", size: 34, at: CGPoint(x: w / 2, y: h * 0.14), color: inkTone.cg(0.8), tracking: 6)
        drawText(ctx, "a board, a loop, a beginning", font: "Georgia-Italic", size: 30, at: CGPoint(x: w / 2, y: h * 0.10), color: inkTone.cg(0.6))
    case 1:
        let railY = h * 0.36
        railLine(ctx, y: railY, minX: 90, maxX: w - 90, rand: rand)
        let bodyRect = CGRect(x: w * 0.16, y: railY + 16, width: 420, height: 160)
        washFill(ctx, rrect(bodyRect, 14), RGB(r: 0.18, g: 0.36, b: 0.27), rand: rand)
        inkRect(ctx, bodyRect, rand: rand, width: 3)
        let cab = CGRect(x: bodyRect.maxX - 120, y: railY + 16, width: 108, height: 220)
        washFill(ctx, rrect(cab, 10), RGB(r: 0.16, g: 0.32, b: 0.24), rand: rand)
        inkRect(ctx, cab, rand: rand, width: 2.6)
        ctx.setFillColor(RGB(r: 0.95, g: 0.82, b: 0.45).cg(0.9))
        ctx.fill(CGRect(x: cab.minX + 20, y: cab.maxY - 80, width: 66, height: 52))
        let boiler = rrect(CGRect(x: bodyRect.minX - 10, y: railY + 176, width: 320, height: 90), 45)
        washFill(ctx, boiler, RGB(r: 0.15, g: 0.3, b: 0.22), rand: rand)
        ctx.addPath(boiler)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
        let chim = CGRect(x: bodyRect.minX + 40, y: railY + 260, width: 40, height: 70)
        washFill(ctx, rrect(chim, 6), inkTone.lighter(0.1), rand: rand)
        inkRect(ctx, chim, rand: rand, width: 2.4)
        drawSmoke(ctx, from: CGPoint(x: chim.midX + 20, y: chim.maxY + 50), rand: rand, count: 6)
        var wagonX = w * 0.16 - 40
        for col in [RGB(r: 0.52, g: 0.22, b: 0.18), RGB(r: 0.45, g: 0.32, b: 0.18)] {
            wagonX -= 260
            let rect = CGRect(x: wagonX, y: railY + 20, width: 240, height: 130)
            washFill(ctx, rrect(rect, 10), col, rand: rand)
            inkRect(ctx, rect, rand: rand, width: 2.6)
            for wx in stride(from: rect.minX + 30, to: rect.maxX - 10, by: 56) {
                ctx.setFillColor(RGB(r: 0.95, g: 0.9, b: 0.78).cg(0.9))
                ctx.fill(CGRect(x: wx, y: rect.midY, width: 34, height: 40))
            }
            for wx in [rect.minX + 50, rect.maxX - 50] {
                smallWheel(ctx, c: CGPoint(x: wx, y: railY - 14), r: 26, rand: rand)
            }
        }
        for wx in [bodyRect.minX + 70, bodyRect.minX + 200, bodyRect.minX + 330] {
            spokedWheel(ctx, c: CGPoint(x: wx, y: railY - 14), r: 46, rand: rand, accent: brassTone)
        }
        let platform = CGRect(x: w * 0.55, y: railY - 90, width: 380, height: 44)
        washFill(ctx, rrect(platform, 8), RGB(r: 0.78, g: 0.72, b: 0.6), rand: rand)
        inkRect(ctx, platform, rand: rand, width: 2.6)
        plateCottage(ctx, x: platform.midX, y: platform.minY - 190, s: 190, rand: rand, red: false)
        let lampX = platform.minX + 40
        ctx.setStrokeColor(pineTone.darker(0.2).cg())
        ctx.setLineWidth(7)
        ctx.move(to: CGPoint(x: lampX, y: platform.maxY))
        ctx.addLine(to: CGPoint(x: lampX, y: platform.maxY + 120))
        ctx.strokePath()
        ctx.setFillColor(RGB(r: 1, g: 0.87, b: 0.5).cg())
        ctx.fillEllipse(in: CGRect(x: lampX - 16, y: platform.maxY + 120, width: 32, height: 40))
        ctx.setStrokeColor(inkTone.cg(0.8))
        ctx.setLineWidth(2.4)
        ctx.strokeEllipse(in: CGRect(x: lampX - 16, y: platform.maxY + 120, width: 32, height: 40))
        drawText(ctx, "PLATE THE SECOND", font: "Georgia-Bold", size: 34, at: CGPoint(x: w / 2, y: h * 0.14), color: inkTone.cg(0.8), tracking: 6)
        drawText(ctx, "steam up, doors shut, away", font: "Georgia-Italic", size: 30, at: CGPoint(x: w / 2, y: h * 0.10), color: inkTone.cg(0.6))
        scenicGround(ctx, w, h, horizon: h * 0.8, rand: rand)
    default:
        let shelfY = [h * 0.68, h * 0.46, h * 0.24]
        for sy in shelfY {
            let shelf = CGRect(x: w * 0.12, y: sy, width: w * 0.76, height: 18)
            washFill(ctx, rrect(shelf, 6), RGB(r: 0.5, g: 0.36, b: 0.22), rand: rand)
            inkRect(ctx, shelf, rand: rand, width: 2.4)
        }
        var bx = w * 0.16
        for col in [redTone, pineTone, RGB(r: 0.3, g: 0.4, b: 0.55), brassTone.darker(0.15)] {
            let book = CGRect(x: bx, y: shelfY[2] + 18, width: 56, height: 180 + rand.range(-20, 30))
            washFill(ctx, rrect(book, 6), col, rand: rand)
            inkRect(ctx, book, rand: rand, width: 2.2)
            ctx.setStrokeColor(brassTone.cg(0.8))
            ctx.setLineWidth(2.4)
            ctx.move(to: CGPoint(x: book.minX + 8, y: book.maxY - 26))
            ctx.addLine(to: CGPoint(x: book.maxX - 8, y: book.maxY - 26))
            ctx.strokePath()
            bx += 66
        }
        let medalX = w * 0.68
        for (i, mc) in [brassTone, steelTone.lighter(0.2), RGB(r: 0.72, g: 0.5, b: 0.32)].enumerated() {
            let c = CGPoint(x: medalX + CGFloat(i % 2) * 90 - 40, y: shelfY[2] + 90 + CGFloat(i / 2) * 40)
            ctx.setFillColor(mc.cg())
            ctx.fillEllipse(in: CGRect(x: c.x - 38, y: c.y - 38, width: 76, height: 76))
            ctx.setStrokeColor(inkTone.cg(0.8))
            ctx.setLineWidth(2.6)
            ctx.strokeEllipse(in: CGRect(x: c.x - 38, y: c.y - 38, width: 76, height: 76))
            let star = CGMutablePath()
            for k in 0..<5 {
                let a = CGFloat(k) / 5 * 2 * .pi - .pi / 2
                let pt = CGPoint(x: c.x + cos(a) * 20, y: c.y + sin(a) * 20)
                if k == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
                let a2 = a + .pi / 5
                star.addLine(to: CGPoint(x: c.x + cos(a2) * 9, y: c.y + sin(a2) * 9))
            }
            star.closeSubpath()
            ctx.addPath(star)
            ctx.setFillColor(inkTone.cg(0.6))
            ctx.fillPath()
        }
        var lx = w * 0.16
        for col in [pineTone, redTone.darker(0.05), RGB(r: 0.13, g: 0.17, b: 0.26)] {
            let loco = CGRect(x: lx, y: shelfY[1] + 18, width: 190, height: 84)
            washFill(ctx, rrect(loco, 10), col, rand: rand)
            inkRect(ctx, loco, rand: rand, width: 2.4)
            ctx.setFillColor(brassTone.cg())
            ctx.fillEllipse(in: CGRect(x: loco.maxX - 40, y: loco.midY - 8, width: 18, height: 18))
            for wx in [loco.minX + 40, loco.maxX - 50] {
                smallWheel(ctx, c: CGPoint(x: wx, y: loco.minY - 2), r: 18, rand: rand)
            }
            lx += 230
        }
        let jarX = w * 0.16
        for i in 0..<3 {
            let jar = CGRect(x: jarX + CGFloat(i) * 130, y: shelfY[0] + 18, width: 100, height: 130)
            ctx.setStrokeColor(inkTone.cg(0.7))
            ctx.setLineWidth(2.6)
            ctx.stroke(rrect(jar, 14).boundingBox)
            for _ in 0..<14 {
                let px = jar.minX + 12 + rand.next() * (jar.width - 24)
                let py = jar.minY + 12 + rand.next() * (jar.height - 40)
                ctx.setFillColor((i == 0 ? pineTone : (i == 1 ? redTone : brassTone)).cg(0.8))
                ctx.fillEllipse(in: CGRect(x: px, y: py, width: 12, height: 12))
            }
            washFill(ctx, rrect(CGRect(x: jar.minX - 4, y: jar.maxY - 6, width: jar.width + 8, height: 20), 6), RGB(r: 0.52, g: 0.37, b: 0.22), rand: rand)
        }
        drawText(ctx, "PLATE THE THIRD", font: "Georgia-Bold", size: 34, at: CGPoint(x: w / 2, y: h * 0.14), color: inkTone.cg(0.8), tracking: 6)
        drawText(ctx, "the workshop shelf fills slowly", font: "Georgia-Italic", size: 30, at: CGPoint(x: w / 2, y: h * 0.10), color: inkTone.cg(0.6))
    }
    saveJPEG(ctx, id)
}

drawOnboarding("onboard_1", 0)
drawOnboarding("onboard_2", 1)
drawOnboarding("onboard_3", 2)

func drawBanner(_ id: String, _ index: Int) {
    let W = 1400, H = 520
    let w = CGFloat(W), h = CGFloat(H)
    let ctx = makeContext(W, H)
    let rand = Rand(UInt64(900 + index))
    paperBase(ctx, w, h, seed: UInt64(77 + index))
    plateFrame(ctx, w, h, inset: 26)
    let railY = h * 0.34
    switch index {
    case 0:
        railLine(ctx, y: railY, minX: 90, maxX: w * 0.6, rand: rand)
        for i in 0..<4 {
            let sx = w * 0.62 + CGFloat(i) * 90
            ctx.setFillColor(RGB(r: 0.42, g: 0.32, b: 0.22).cg(0.8))
            ctx.saveGState()
            ctx.translateBy(x: sx, y: railY - 4)
            ctx.rotate(by: rand.range(-0.5, 0.5))
            ctx.fill(CGRect(x: -34, y: -7, width: 68, height: 14))
            ctx.restoreGState()
        }
        let hammerC = CGPoint(x: w * 0.82, y: h * 0.6)
        ctx.setStrokeColor(RGB(r: 0.5, g: 0.38, b: 0.24).cg())
        ctx.setLineWidth(12)
        ctx.move(to: CGPoint(x: hammerC.x - 90, y: hammerC.y - 60))
        ctx.addLine(to: CGPoint(x: hammerC.x + 60, y: hammerC.y + 60))
        ctx.strokePath()
        washFill(ctx, rrect(CGRect(x: hammerC.x + 30, y: hammerC.y + 30, width: 90, height: 60), 8), steelTone, rand: rand)
        drawText(ctx, "CH. I", font: "Georgia-Bold", size: 44, at: CGPoint(x: w * 0.14, y: h * 0.66), color: inkTone.cg(0.85), tracking: 4)
    case 1:
        railLine(ctx, y: railY, minX: 90, maxX: w - 90, rand: rand)
        let platform = CGRect(x: w * 0.3, y: railY + 26, width: 460, height: 40)
        washFill(ctx, rrect(platform, 8), RGB(r: 0.78, g: 0.72, b: 0.6), rand: rand)
        inkRect(ctx, platform, rand: rand, width: 2.6)
        plateCottage(ctx, x: platform.midX, y: platform.maxY, s: 150, rand: rand)
        let clockC = CGPoint(x: w * 0.85, y: h * 0.6)
        ctx.setFillColor(RGB(r: 0.95, g: 0.93, b: 0.87).cg())
        ctx.fillEllipse(in: CGRect(x: clockC.x - 60, y: clockC.y - 60, width: 120, height: 120))
        ctx.setStrokeColor(inkTone.cg(0.85))
        ctx.setLineWidth(4)
        ctx.strokeEllipse(in: CGRect(x: clockC.x - 60, y: clockC.y - 60, width: 120, height: 120))
        ctx.setLineWidth(4)
        ctx.move(to: clockC)
        ctx.addLine(to: CGPoint(x: clockC.x + 30, y: clockC.y + 22))
        ctx.move(to: clockC)
        ctx.addLine(to: CGPoint(x: clockC.x - 8, y: clockC.y + 42))
        ctx.strokePath()
        drawText(ctx, "CH. II", font: "Georgia-Bold", size: 44, at: CGPoint(x: w * 0.12, y: h * 0.66), color: inkTone.cg(0.85), tracking: 4)
    case 2:
        scenicGround(ctx, w, h, horizon: h * 0.5, rand: rand)
        railLine(ctx, y: railY, minX: 90, maxX: w - 90, rand: rand)
        plateCottage(ctx, x: w * 0.3, y: h * 0.52, s: 140, rand: rand)
        plateCottage(ctx, x: w * 0.52, y: h * 0.55, s: 110, rand: rand, red: true)
        plateTree(ctx, x: w * 0.68, y: h * 0.52, s: 130, rand: rand, pine: true)
        plateTree(ctx, x: w * 0.80, y: h * 0.55, s: 110, rand: rand, pine: false)
        drawText(ctx, "CH. III", font: "Georgia-Bold", size: 44, at: CGPoint(x: w * 0.12, y: h * 0.7), color: inkTone.cg(0.85), tracking: 4)
    case 3:
        railLine(ctx, y: h * 0.55, minX: 90, maxX: w - 90, rand: rand)
        railLine(ctx, y: h * 0.22, minX: 90, maxX: w - 90, rand: rand)
        for (locoX, col, dir) in [(w * 0.3, pineTone, 1.0), (w * 0.72, redTone, -1.0)] {
            let rect = CGRect(x: locoX - 130, y: (dir > 0 ? h * 0.55 : h * 0.22) + 12, width: 260, height: 90)
            washFill(ctx, rrect(rect, 12), col, rand: rand)
            inkRect(ctx, rect, rand: rand, width: 2.6)
            drawSmoke(ctx, from: CGPoint(x: rect.midX + CGFloat(dir) * 70, y: rect.maxY + 26), rand: rand, count: 3, drift: CGFloat(dir))
            for wx in [rect.minX + 50, rect.midX, rect.maxX - 50] {
                smallWheel(ctx, c: CGPoint(x: wx, y: rect.minY - 10), r: 22, rand: rand)
            }
        }
        drawText(ctx, "CH. IV", font: "Georgia-Bold", size: 44, at: CGPoint(x: w * 0.12, y: h * 0.82), color: inkTone.cg(0.85), tracking: 4)
    case 4:
        ctx.setFillColor(RGB(r: 0.16, g: 0.18, b: 0.3).cg(0.5))
        ctx.fill(CGRect(x: 26, y: 26, width: w - 52, height: h - 52))
        railLine(ctx, y: railY, minX: 90, maxX: w - 90, rand: rand)
        for i in 0..<3 {
            let lampX = w * 0.3 + CGFloat(i) * w * 0.2
            ctx.setStrokeColor(inkTone.cg(0.9))
            ctx.setLineWidth(6)
            ctx.move(to: CGPoint(x: lampX, y: railY + 20))
            ctx.addLine(to: CGPoint(x: lampX, y: railY + 150))
            ctx.strokePath()
            let glow = CGGradient(colorsSpace: nil, colors: [RGB(r: 1, g: 0.85, b: 0.5).cg(0.7), RGB(r: 1, g: 0.85, b: 0.5).cg(0.0)] as CFArray, locations: [0, 1])!
            ctx.drawRadialGradient(glow, startCenter: CGPoint(x: lampX, y: railY + 165), startRadius: 0, endCenter: CGPoint(x: lampX, y: railY + 165), endRadius: 90, options: [])
            ctx.setFillColor(RGB(r: 1, g: 0.88, b: 0.55).cg())
            ctx.fillEllipse(in: CGRect(x: lampX - 14, y: railY + 150, width: 28, height: 34))
        }
        let moonC = CGPoint(x: w * 0.85, y: h * 0.68)
        ctx.setFillColor(RGB(r: 0.96, g: 0.94, b: 0.82).cg(0.9))
        ctx.fillEllipse(in: CGRect(x: moonC.x - 44, y: moonC.y - 44, width: 88, height: 88))
        ctx.setFillColor(RGB(r: 0.16, g: 0.18, b: 0.3).cg(0.5))
        ctx.fillEllipse(in: CGRect(x: moonC.x - 60, y: moonC.y - 30, width: 70, height: 70))
        drawText(ctx, "CH. V", font: "Georgia-Bold", size: 44, at: CGPoint(x: w * 0.12, y: h * 0.72), color: RGB(r: 0.92, g: 0.88, b: 0.78).cg(0.9), tracking: 4)
    default:
        railLine(ctx, y: h * 0.5, minX: 90, maxX: w - 90, rand: rand)
        let curve = CGMutablePath()
        curve.move(to: CGPoint(x: w * 0.4, y: h * 0.5))
        curve.addQuadCurve(to: CGPoint(x: w - 90, y: h * 0.18), control: CGPoint(x: w * 0.7, y: h * 0.5))
        ctx.addPath(curve)
        ctx.setStrokeColor(steelTone.cg())
        ctx.setLineWidth(5)
        ctx.strokePath()
        let laurelC = CGPoint(x: w * 0.16, y: h * 0.5)
        for side in [-1.0, 1.0] {
            let branch = CGMutablePath()
            branch.move(to: CGPoint(x: laurelC.x, y: laurelC.y - 80))
            branch.addQuadCurve(to: CGPoint(x: laurelC.x + CGFloat(side) * 70, y: laurelC.y + 80), control: CGPoint(x: laurelC.x + CGFloat(side) * 90, y: laurelC.y - 20))
            ctx.addPath(branch)
            ctx.setStrokeColor(pineTone.cg(0.85))
            ctx.setLineWidth(4)
            ctx.strokePath()
            for t in stride(from: 0.15, through: 0.95, by: 0.13) {
                let bx = laurelC.x + CGFloat(side) * 80 * CGFloat(sin(t * 2.4)) * CGFloat(t)
                let by = laurelC.y - 80 + CGFloat(t) * 160
                let leaf = CGPath(ellipseIn: CGRect(x: bx - 4, y: by - 14, width: 18, height: 30), transform: nil)
                ctx.addPath(leaf)
                ctx.setFillColor(pineTone.cg(0.7))
                ctx.fillPath()
            }
        }
        ctx.setFillColor(brassTone.cg())
        ctx.fillEllipse(in: CGRect(x: laurelC.x - 34, y: laurelC.y - 34, width: 68, height: 68))
        ctx.setStrokeColor(inkTone.cg(0.85))
        ctx.setLineWidth(3)
        ctx.strokeEllipse(in: CGRect(x: laurelC.x - 34, y: laurelC.y - 34, width: 68, height: 68))
        drawText(ctx, "CH. VI", font: "Georgia-Bold", size: 44, at: CGPoint(x: w * 0.5, y: h * 0.72), color: inkTone.cg(0.85), tracking: 4)
    }
    saveJPEG(ctx, id)
}

for i in 0..<6 {
    drawBanner("banner_ch\(i + 1)", i)
}

print("ALL ART DONE")

struct WagonSpec {
    var id: String
    var name: String
    var sub: String
    var kind: String
    var body: RGB
    var roof: RGB
    var accent: RGB
    var seed: UInt64
}

let wagonSpecs: [WagonSpec] = [
    WagonSpec(id: "coach_cherry", name: "Cherry Coach", sub: "Passenger Coach", kind: "coach", body: RGB(r: 0.52, g: 0.22, b: 0.18), roof: RGB(r: 0.82, g: 0.79, b: 0.72), accent: RGB(r: 0.85, g: 0.70, b: 0.35), seed: 201),
    WagonSpec(id: "coach_teak", name: "Teak Coach", sub: "Passenger Coach", kind: "coach", body: RGB(r: 0.45, g: 0.32, b: 0.18), roof: RGB(r: 0.75, g: 0.73, b: 0.68), accent: RGB(r: 0.80, g: 0.68, b: 0.40), seed: 202),
    WagonSpec(id: "boxcar", name: "Goods Van", sub: "Covered Van", kind: "van", body: RGB(r: 0.42, g: 0.30, b: 0.22), roof: RGB(r: 0.30, g: 0.28, b: 0.26), accent: RGB(r: 0.20, g: 0.18, b: 0.16), seed: 203),
    WagonSpec(id: "hopper", name: "Coal Hopper", sub: "Open Hopper", kind: "hopper", body: RGB(r: 0.24, g: 0.24, b: 0.26), roof: RGB(r: 0.15, g: 0.15, b: 0.16), accent: RGB(r: 0.50, g: 0.48, b: 0.46), seed: 204),
    WagonSpec(id: "flatbed", name: "Timber Flat", sub: "Flat Wagon", kind: "flat", body: RGB(r: 0.50, g: 0.38, b: 0.24), roof: RGB(r: 0.55, g: 0.42, b: 0.28), accent: RGB(r: 0.35, g: 0.26, b: 0.16), seed: 205),
    WagonSpec(id: "tanker", name: "Milk Tanker", sub: "Tank Wagon", kind: "tank", body: RGB(r: 0.80, g: 0.80, b: 0.78), roof: RGB(r: 0.60, g: 0.60, b: 0.58), accent: RGB(r: 0.30, g: 0.40, b: 0.50), seed: 206),
    WagonSpec(id: "mailvan", name: "Mail Van", sub: "Mail Van", kind: "van", body: RGB(r: 0.55, g: 0.16, b: 0.14), roof: RGB(r: 0.35, g: 0.30, b: 0.28), accent: RGB(r: 0.85, g: 0.72, b: 0.30), seed: 207),
    WagonSpec(id: "fridge", name: "Ice Van", sub: "Refrigerated Van", kind: "van", body: RGB(r: 0.78, g: 0.82, b: 0.80), roof: RGB(r: 0.55, g: 0.58, b: 0.57), accent: RGB(r: 0.25, g: 0.45, b: 0.50), seed: 208),
    WagonSpec(id: "gondola", name: "Gravel Gondola", sub: "Open Wagon", kind: "hopper", body: RGB(r: 0.35, g: 0.38, b: 0.32), roof: RGB(r: 0.25, g: 0.27, b: 0.23), accent: RGB(r: 0.60, g: 0.58, b: 0.52), seed: 209),
    WagonSpec(id: "observation", name: "Observation Car", sub: "Observation Coach", kind: "coach", body: RGB(r: 0.30, g: 0.38, b: 0.36), roof: RGB(r: 0.80, g: 0.77, b: 0.70), accent: RGB(r: 0.85, g: 0.68, b: 0.32), seed: 210),
    WagonSpec(id: "caboose", name: "Guard's Van", sub: "Brake Van", kind: "guard", body: RGB(r: 0.48, g: 0.28, b: 0.16), roof: RGB(r: 0.28, g: 0.24, b: 0.20), accent: RGB(r: 0.72, g: 0.32, b: 0.22), seed: 211),
    WagonSpec(id: "wellwagon", name: "Well Wagon", sub: "Heavy Hauler", kind: "well", body: RGB(r: 0.30, g: 0.30, b: 0.32), roof: RGB(r: 0.22, g: 0.22, b: 0.24), accent: RGB(r: 0.65, g: 0.55, b: 0.30), seed: 212),
]

func drawWagonPlate(_ spec: WagonSpec) {
    let W = 1400, H = 900
    let w = CGFloat(W), h = CGFloat(H)
    let ctx = makeContext(W, H)
    let rand = Rand(spec.seed)
    paperBase(ctx, w, h, seed: spec.seed)
    plateFrame(ctx, w, h, inset: 42)
    let railY: CGFloat = 300
    railLine(ctx, y: railY - 30, minX: 150, maxX: w - 150, rand: rand)
    groundShadow(ctx, cx: w / 2, y: railY - 46, w: 640, rand: rand)
    let cx = w / 2
    let bodyW: CGFloat = 560

    func wheels(_ xs: [CGFloat]) {
        for x in xs { smallWheel(ctx, c: CGPoint(x: x, y: railY - 14), r: 34, rand: rand) }
    }
    func chassis() {
        let frame = rrect(CGRect(x: cx - bodyW / 2, y: railY, width: bodyW, height: 22), 4)
        washFill(ctx, frame, inkTone.lighter(0.15), rand: rand)
        for dy in [24.0, 60.0] {
            for dir in [-1.0, 1.0] {
                ctx.setStrokeColor(inkTone.cg(0.9))
                ctx.setLineWidth(5)
                ctx.move(to: CGPoint(x: cx + CGFloat(dir) * bodyW / 2, y: railY + CGFloat(dy)))
                ctx.addLine(to: CGPoint(x: cx + CGFloat(dir) * (bodyW / 2 + 24), y: railY + CGFloat(dy)))
                ctx.strokePath()
                ctx.setFillColor(steelTone.cg())
                ctx.fill(CGRect(x: cx + CGFloat(dir) * (bodyW / 2 + 24) - (dir < 0 ? 8 : 0), y: railY + CGFloat(dy) - 13, width: 8, height: 26))
            }
        }
    }

    chassis()
    wheels([cx - bodyW / 2 + 70, cx + bodyW / 2 - 70])

    switch spec.kind {
    case "coach":
        let rect = CGRect(x: cx - bodyW / 2 + 8, y: railY + 22, width: bodyW - 16, height: 190)
        washFill(ctx, rrect(rect, 16), spec.body, rand: rand)
        inkRect(ctx, rect, rand: rand, width: 3)
        ctx.setStrokeColor(spec.accent.cg(0.9))
        ctx.setLineWidth(4)
        ctx.stroke(rect.insetBy(dx: 10, dy: 10))
        for wx in stride(from: rect.minX + 50, to: rect.maxX - 60, by: 96) {
            let win = CGRect(x: wx, y: rect.midY - 6, width: 56, height: 66)
            washFill(ctx, rrect(win, 8), RGB(r: 0.93, g: 0.88, b: 0.72), rand: rand)
            inkRect(ctx, win, rand: rand, width: 2.2)
        }
        let roof = CGMutablePath()
        roof.move(to: CGPoint(x: rect.minX - 10, y: rect.maxY))
        roof.addQuadCurve(to: CGPoint(x: rect.maxX + 10, y: rect.maxY), control: CGPoint(x: cx, y: rect.maxY + 52))
        roof.closeSubpath()
        washFill(ctx, roof, spec.roof, rand: rand)
        ctx.addPath(roof)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
        if spec.id == "observation" {
            let deck = CGRect(x: rect.maxX + 10, y: railY + 22, width: 64, height: 120)
            inkRect(ctx, deck, rand: rand, width: 2.6)
            for bx in stride(from: deck.minX + 8, to: deck.maxX, by: 14) {
                ctx.setStrokeColor(inkTone.cg(0.6))
                ctx.setLineWidth(2.4)
                ctx.move(to: CGPoint(x: bx, y: deck.minY))
                ctx.addLine(to: CGPoint(x: bx, y: deck.maxY))
                ctx.strokePath()
            }
        }
    case "van":
        let rect = CGRect(x: cx - bodyW / 2 + 8, y: railY + 22, width: bodyW - 16, height: 200)
        washFill(ctx, rrect(rect, 10), spec.body, rand: rand)
        inkRect(ctx, rect, rand: rand, width: 3)
        for px in stride(from: rect.minX + 26, to: rect.maxX, by: 34) {
            ctx.setStrokeColor(inkTone.cg(0.4))
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: px, y: rect.minY + 8))
            ctx.addLine(to: CGPoint(x: px, y: rect.maxY - 8))
            ctx.strokePath()
        }
        let door = CGRect(x: cx - 70, y: rect.minY + 12, width: 140, height: rect.height - 24)
        inkRect(ctx, door, rand: rand, width: 2.8)
        ctx.setStrokeColor(inkTone.cg(0.7))
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: cx, y: door.minY))
        ctx.addLine(to: CGPoint(x: cx, y: door.maxY))
        ctx.strokePath()
        let roofR = CGRect(x: rect.minX - 8, y: rect.maxY, width: rect.width + 16, height: 26)
        washFill(ctx, rrect(roofR, 12), spec.roof, rand: rand)
        inkRect(ctx, roofR, rand: rand, width: 2.4)
        if spec.id == "mailvan" {
            drawText(ctx, "ROYAL MAIL", font: "Georgia-Bold", size: 34, at: CGPoint(x: cx, y: rect.maxY - 60), color: spec.accent.cg(0.95), tracking: 3)
        }
        if spec.id == "fridge" {
            drawText(ctx, "ICE", font: "Georgia-Bold", size: 44, at: CGPoint(x: cx, y: rect.midY - 14), color: spec.accent.cg(0.9), tracking: 6)
            hatchRect(ctx, rect, rand: rand, angle: 0.8, gap: 18, alpha: 0.06)
        }
        if spec.id == "boxcar" {
            drawText(ctx, "GOODS", font: "Georgia-Bold", size: 34, at: CGPoint(x: rect.minX + 90, y: rect.maxY - 56), color: RGB(r: 0.9, g: 0.86, b: 0.76).cg(0.9), tracking: 2)
        }
    case "hopper":
        let top = railY + 200
        let hopperP = CGMutablePath()
        hopperP.move(to: CGPoint(x: cx - bodyW / 2 + 10, y: top))
        hopperP.addLine(to: CGPoint(x: cx + bodyW / 2 - 10, y: top))
        hopperP.addLine(to: CGPoint(x: cx + bodyW / 2 - 60, y: railY + 40))
        hopperP.addLine(to: CGPoint(x: cx + 60, y: railY + 22))
        hopperP.addLine(to: CGPoint(x: cx - 60, y: railY + 22))
        hopperP.addLine(to: CGPoint(x: cx - bodyW / 2 + 60, y: railY + 40))
        hopperP.closeSubpath()
        washFill(ctx, hopperP, spec.body, rand: rand)
        ctx.addPath(hopperP)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
        for rx in stride(from: cx - bodyW / 2 + 60, to: cx + bodyW / 2 - 40, by: 90) {
            ctx.setStrokeColor(inkTone.cg(0.5))
            ctx.setLineWidth(2.6)
            ctx.move(to: CGPoint(x: rx, y: railY + 40))
            ctx.addLine(to: CGPoint(x: rx + 24, y: top))
            ctx.strokePath()
        }
        let heap = CGMutablePath()
        heap.move(to: CGPoint(x: cx - bodyW / 2 + 20, y: top))
        for i in 0...8 {
            heap.addLine(to: CGPoint(x: cx - bodyW / 2 + 20 + CGFloat(i) * (bodyW - 40) / 8, y: top + rand.range(8, 44)))
        }
        heap.addLine(to: CGPoint(x: cx + bodyW / 2 - 20, y: top))
        heap.closeSubpath()
        washFill(ctx, heap, spec.id == "hopper" ? inkTone : RGB(r: 0.58, g: 0.55, b: 0.48), rand: rand, alpha: 0.95)
        for _ in 0..<40 {
            let px = cx - bodyW / 2 + 30 + rand.next() * (bodyW - 60)
            let py = top + rand.range(2, 34)
            ctx.setFillColor(RGB(r: 1, g: 1, b: 1).cg(rand.range(0.1, 0.3)))
            ctx.fillEllipse(in: CGRect(x: px, y: py, width: 4, height: 4))
        }
    case "flat":
        let deck = CGRect(x: cx - bodyW / 2 + 8, y: railY + 22, width: bodyW - 16, height: 40)
        washFill(ctx, rrect(deck, 6), spec.body, rand: rand)
        inkRect(ctx, deck, rand: rand, width: 2.8)
        var logY = deck.maxY
        var logCount = 5
        while logCount > 1 {
            let logW = (bodyW - 60) * CGFloat(logCount) / 5
            var lx = cx - logW / 2
            for _ in 0..<logCount {
                let log = rrect(CGRect(x: lx, y: logY, width: logW / CGFloat(logCount) - 6, height: 54), 27)
                washFill(ctx, log, RGB(r: 0.55, g: 0.42, b: 0.26).mix(RGB(r: 0.4, g: 0.3, b: 0.18), rand.next() * 0.5), rand: rand)
                ctx.addPath(log)
                ctx.setStrokeColor(inkTone.cg(0.85))
                ctx.setLineWidth(2.6)
                ctx.strokePath()
                let endR = CGRect(x: lx + 6, y: logY + 12, width: 30, height: 30)
                ctx.setFillColor(RGB(r: 0.78, g: 0.65, b: 0.45).cg())
                ctx.fillEllipse(in: endR)
                ctx.setStrokeColor(inkTone.cg(0.7))
                ctx.setLineWidth(2)
                ctx.strokeEllipse(in: endR)
                ctx.strokeEllipse(in: endR.insetBy(dx: 7, dy: 7))
                lx += logW / CGFloat(logCount)
            }
            logY += 56
            logCount -= 1
        }
        for tx in [cx - 160, cx + 160] {
            ctx.setStrokeColor(inkTone.cg(0.8))
            ctx.setLineWidth(3)
            ctx.move(to: CGPoint(x: tx - 60, y: deck.maxY))
            ctx.addLine(to: CGPoint(x: tx + 60, y: deck.maxY + 160))
            ctx.strokePath()
        }
    case "tank":
        let tank = rrect(CGRect(x: cx - bodyW / 2 + 14, y: railY + 40, width: bodyW - 28, height: 170), 85)
        washFill(ctx, tank, spec.body, rand: rand)
        ctx.addPath(tank)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3.4)
        ctx.strokePath()
        for bx in [cx - 130, cx, cx + 130] {
            ctx.setStrokeColor(steelTone.cg(0.8))
            ctx.setLineWidth(7)
            ctx.move(to: CGPoint(x: bx, y: railY + 44))
            ctx.addLine(to: CGPoint(x: bx, y: railY + 206))
            ctx.strokePath()
        }
        let dome = CGRect(x: cx - 40, y: railY + 200, width: 80, height: 40)
        washFill(ctx, rrect(dome, 14), spec.body.darker(0.1), rand: rand)
        inkRect(ctx, dome, rand: rand, width: 2.6)
        drawText(ctx, "FRESH MILK", font: "Georgia-Bold", size: 34, at: CGPoint(x: cx, y: railY + 110), color: spec.accent.cg(0.9), tracking: 4)
        for sx in [cx - bodyW / 2 + 60, cx + bodyW / 2 - 100] {
            ctx.setStrokeColor(inkTone.cg(0.75))
            ctx.setLineWidth(3)
            ctx.move(to: CGPoint(x: sx, y: railY + 22))
            ctx.addLine(to: CGPoint(x: sx + 40, y: railY + 60))
            ctx.strokePath()
        }
    case "guard":
        let rect = CGRect(x: cx - bodyW / 2 + 40, y: railY + 22, width: bodyW - 80, height: 180)
        washFill(ctx, rrect(rect, 10), spec.body, rand: rand)
        inkRect(ctx, rect, rand: rand, width: 3)
        let veranda = CGRect(x: rect.maxX, y: railY + 22, width: 70, height: 140)
        inkRect(ctx, veranda, rand: rand, width: 2.6)
        for bx in stride(from: veranda.minX + 10, to: veranda.maxX, by: 16) {
            ctx.setStrokeColor(inkTone.cg(0.6))
            ctx.setLineWidth(2.4)
            ctx.move(to: CGPoint(x: bx, y: veranda.minY))
            ctx.addLine(to: CGPoint(x: bx, y: veranda.maxY))
            ctx.strokePath()
        }
        let win = CGRect(x: rect.minX + 40, y: rect.midY, width: 60, height: 60)
        washFill(ctx, rrect(win, 8), RGB(r: 0.95, g: 0.85, b: 0.55), rand: rand)
        inkRect(ctx, win, rand: rand, width: 2.4)
        let stovepipe = CGRect(x: rect.minX + 130, y: rect.maxY + 24, width: 18, height: 60)
        washFill(ctx, rrect(stovepipe, 4), inkTone.lighter(0.1), rand: rand)
        drawSmoke(ctx, from: CGPoint(x: stovepipe.midX, y: stovepipe.maxY + 26), rand: rand, count: 3)
        let roofR = CGRect(x: rect.minX - 10, y: rect.maxY, width: rect.width + 90, height: 24)
        washFill(ctx, rrect(roofR, 10), spec.roof, rand: rand)
        inkRect(ctx, roofR, rand: rand, width: 2.4)
        let lampR = CGRect(x: veranda.maxX - 6, y: veranda.midY - 14, width: 22, height: 28)
        ctx.setFillColor(RGB(r: 0.95, g: 0.6, b: 0.3).cg())
        ctx.fillEllipse(in: lampR)
        ctx.setStrokeColor(inkTone.cg(0.85))
        ctx.setLineWidth(2.2)
        ctx.strokeEllipse(in: lampR)
    default:
        let well = CGMutablePath()
        well.move(to: CGPoint(x: cx - bodyW / 2 + 10, y: railY + 60))
        well.addLine(to: CGPoint(x: cx - bodyW / 2 + 120, y: railY + 60))
        well.addLine(to: CGPoint(x: cx - bodyW / 2 + 150, y: railY + 16))
        well.addLine(to: CGPoint(x: cx + bodyW / 2 - 150, y: railY + 16))
        well.addLine(to: CGPoint(x: cx + bodyW / 2 - 120, y: railY + 60))
        well.addLine(to: CGPoint(x: cx + bodyW / 2 - 10, y: railY + 60))
        well.addLine(to: CGPoint(x: cx + bodyW / 2 - 10, y: railY + 22))
        well.addLine(to: CGPoint(x: cx - bodyW / 2 + 10, y: railY + 22))
        well.closeSubpath()
        washFill(ctx, well, spec.body, rand: rand)
        ctx.addPath(well)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
        let boiler = rrect(CGRect(x: cx - 170, y: railY + 30, width: 340, height: 120), 60)
        washFill(ctx, boiler, RGB(r: 0.5, g: 0.34, b: 0.28), rand: rand)
        ctx.addPath(boiler)
        ctx.setStrokeColor(inkTone.cg(0.9))
        ctx.setLineWidth(3)
        ctx.strokePath()
        for bx in [cx - 90, cx, cx + 90] {
            ctx.setStrokeColor(brassTone.cg(0.9))
            ctx.setLineWidth(5)
            ctx.move(to: CGPoint(x: bx, y: railY + 34))
            ctx.addLine(to: CGPoint(x: bx, y: railY + 146))
            ctx.strokePath()
        }
        for rx in [cx - 130, cx + 130] {
            ctx.setStrokeColor(inkTone.cg(0.8))
            ctx.setLineWidth(3.4)
            ctx.move(to: CGPoint(x: rx - 40, y: railY + 30))
            ctx.addLine(to: CGPoint(x: rx + 40, y: railY + 150))
            ctx.strokePath()
        }
        wheels([cx - bodyW / 2 + 130, cx + bodyW / 2 - 130])
    }
    titleBlock(ctx, w: w, name: spec.name, sub: spec.sub, y: 82)
    saveJPEG(ctx, "wagon_\(spec.id)")
}

for spec in wagonSpecs {
    drawWagonPlate(spec)
}
print("WAGONS DONE")
