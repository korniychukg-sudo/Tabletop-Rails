import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon-1024.png"
let S: CGFloat = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setAllowsAntialiasing(true)

final class R {
    var state: UInt64 = 421
    func next() -> CGFloat {
        state = state &* 2862933555777941757 &+ 3037000493
        return CGFloat((state >> 33) & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }
    func range(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { lo + next() * (hi - lo) }
}
let rand = R()

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

func grad(_ stops: [(CGFloat, CGColor)]) -> CGGradient {
    CGGradient(colorsSpace: cs, colors: stops.map { $0.1 } as CFArray, locations: stops.map { $0.0 })!
}

func fillPath(_ path: CGPath, _ color: CGColor) {
    ctx.addPath(path)
    ctx.setFillColor(color)
    ctx.fillPath()
}

func gradFillPath(_ path: CGPath, _ g: CGGradient, from: CGPoint, to: CGPoint) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

let bgGrad = grad([
    (0.0, rgb(0.13, 0.09, 0.06)),
    (0.45, rgb(0.24, 0.16, 0.10)),
    (0.75, rgb(0.36, 0.24, 0.14)),
    (1.0, rgb(0.30, 0.20, 0.12)),
])
ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: S), options: [])
let lampGlow = grad([(0.0, rgb(1.0, 0.82, 0.52, 0.34)), (0.55, rgb(1.0, 0.75, 0.42, 0.10)), (1.0, rgb(1.0, 0.75, 0.42, 0.0))])
ctx.drawRadialGradient(lampGlow, startCenter: CGPoint(x: S * 0.5, y: S * 0.78), startRadius: 0, endCenter: CGPoint(x: S * 0.5, y: S * 0.78), endRadius: S * 0.72, options: [])

let tableY = S * 0.235
let tableGrad = grad([
    (0.0, rgb(0.42, 0.28, 0.16)),
    (0.35, rgb(0.51, 0.35, 0.20)),
    (1.0, rgb(0.30, 0.19, 0.11)),
])
ctx.saveGState()
ctx.clip(to: CGRect(x: 0, y: 0, width: S, height: tableY))
ctx.drawLinearGradient(tableGrad, start: CGPoint(x: 0, y: tableY), end: CGPoint(x: 0, y: 0), options: [])
for _ in 0..<26 {
    let gy = rand.next() * tableY
    ctx.setStrokeColor(rgb(0.20, 0.12, 0.06, rand.range(0.12, 0.3)))
    ctx.setLineWidth(rand.range(1.5, 3.5))
    ctx.move(to: CGPoint(x: 0, y: gy))
    var x: CGFloat = 0
    var yy = gy
    while x < S {
        x += rand.range(80, 180)
        yy += rand.range(-5, 5)
        ctx.addLine(to: CGPoint(x: x, y: yy))
    }
    ctx.strokePath()
}
ctx.restoreGState()
ctx.setFillColor(rgb(1.0, 0.85, 0.55, 0.10))
ctx.fill(CGRect(x: 0, y: tableY - 6, width: S, height: 6))

let railY = tableY + 12
ctx.setFillColor(rgb(0.08, 0.05, 0.03, 0.5))
ctx.fillEllipse(in: CGRect(x: S * 0.06, y: railY - 44, width: S * 0.88, height: 74))
for i in 0..<12 {
    let sx = S * 0.04 + CGFloat(i) * S * 0.082
    let sleeper = CGRect(x: sx, y: railY - 14, width: S * 0.062, height: 22)
    ctx.setFillColor(rgb(0.32, 0.21, 0.12))
    ctx.fill(sleeper)
    ctx.setFillColor(rgb(0.45, 0.31, 0.18, 0.6))
    ctx.fill(CGRect(x: sx, y: railY - 14 + 15, width: S * 0.062, height: 6))
}
for ry in [railY + 8, railY - 20] {
    let railGrad = grad([(0.0, rgb(0.55, 0.53, 0.50)), (0.4, rgb(0.82, 0.80, 0.76)), (0.6, rgb(0.62, 0.60, 0.56)), (1.0, rgb(0.38, 0.36, 0.33))])
    ctx.saveGState()
    ctx.clip(to: CGRect(x: 0, y: ry - 7, width: S, height: 14))
    ctx.drawLinearGradient(railGrad, start: CGPoint(x: 0, y: ry + 7), end: CGPoint(x: 0, y: ry - 7), options: [])
    ctx.restoreGState()
}

let bodyGreenTop = rgb(0.30, 0.52, 0.36)
let bodyGreen = rgb(0.16, 0.38, 0.25)
let bodyGreenDeep = rgb(0.07, 0.22, 0.13)
let brassHi = rgb(0.98, 0.86, 0.52)
let brass = rgb(0.82, 0.62, 0.28)
let brassLo = rgb(0.48, 0.33, 0.12)
let inkDark = rgb(0.06, 0.05, 0.04)

let baseY = railY + 4
let locoLeft = S * 0.115
let locoRight = S * 0.885
let frameH: CGFloat = 34

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 34, color: rgb(0, 0, 0, 0.55))
ctx.setFillColor(rgb(0.12, 0.10, 0.08))
ctx.fill(CGRect(x: locoLeft - 14, y: baseY + 26, width: locoRight - locoLeft + 28, height: frameH))
ctx.restoreGState()
let frameGrad = grad([(0.0, rgb(0.30, 0.26, 0.22)), (0.5, rgb(0.16, 0.13, 0.11)), (1.0, rgb(0.08, 0.07, 0.06))])
gradFillPath(CGPath(rect: CGRect(x: locoLeft - 14, y: baseY + 26, width: locoRight - locoLeft + 28, height: frameH), transform: nil), frameGrad, from: CGPoint(x: 0, y: baseY + 26 + frameH), to: CGPoint(x: 0, y: baseY + 26))
ctx.setFillColor(rgb(0.72, 0.28, 0.20))
ctx.fill(CGRect(x: locoLeft - 14, y: baseY + 26 + frameH - 7, width: locoRight - locoLeft + 28, height: 7))

func spokedWheel(_ c: CGPoint, _ radius: CGFloat) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: rgb(0, 0, 0, 0.5))
    ctx.setFillColor(rgb(0.10, 0.08, 0.07))
    ctx.fillEllipse(in: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
    ctx.restoreGState()
    let tyre = grad([(0.0, rgb(0.30, 0.28, 0.26)), (0.35, rgb(0.55, 0.52, 0.48)), (0.65, rgb(0.30, 0.28, 0.26)), (1.0, rgb(0.14, 0.12, 0.11))])
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
    ctx.clip()
    ctx.drawLinearGradient(tyre, start: CGPoint(x: c.x - radius, y: c.y + radius), end: CGPoint(x: c.x + radius, y: c.y - radius), options: [])
    ctx.restoreGState()
    let innerR = radius * 0.82
    let hub = grad([(0.0, rgb(0.88, 0.42, 0.30)), (0.5, rgb(0.66, 0.24, 0.16)), (1.0, rgb(0.38, 0.12, 0.08))])
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - innerR, y: c.y - innerR, width: innerR * 2, height: innerR * 2))
    ctx.clip()
    ctx.drawRadialGradient(hub, startCenter: CGPoint(x: c.x - innerR * 0.4, y: c.y + innerR * 0.4), startRadius: 0, endCenter: c, endRadius: innerR * 1.4, options: [])
    ctx.restoreGState()
    for i in 0..<10 {
        let a = CGFloat(i) / 10 * 2 * .pi + 0.12
        ctx.setStrokeColor(rgb(0.30, 0.10, 0.06, 0.9))
        ctx.setLineWidth(9)
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: c.x + cos(a) * innerR * 0.2, y: c.y + sin(a) * innerR * 0.2))
        ctx.addLine(to: CGPoint(x: c.x + cos(a) * innerR * 0.86, y: c.y + sin(a) * innerR * 0.86))
        ctx.strokePath()
        ctx.setStrokeColor(rgb(0.92, 0.52, 0.38, 0.5))
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: c.x + cos(a) * innerR * 0.24, y: c.y + sin(a) * innerR * 0.24))
        ctx.addLine(to: CGPoint(x: c.x + cos(a) * innerR * 0.8, y: c.y + sin(a) * innerR * 0.8))
        ctx.strokePath()
    }
    let hubR = radius * 0.2
    let hubGrad = grad([(0.0, brassHi), (0.5, brass), (1.0, brassLo)])
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - hubR, y: c.y - hubR, width: hubR * 2, height: hubR * 2))
    ctx.clip()
    ctx.drawLinearGradient(hubGrad, start: CGPoint(x: c.x - hubR, y: c.y + hubR), end: CGPoint(x: c.x + hubR, y: c.y - hubR), options: [])
    ctx.restoreGState()
    ctx.setStrokeColor(rgb(0.25, 0.15, 0.05, 0.8))
    ctx.setLineWidth(3)
    ctx.strokeEllipse(in: CGRect(x: c.x - hubR, y: c.y - hubR, width: hubR * 2, height: hubR * 2))
    let glint = grad([(0.0, rgb(1, 1, 1, 0.5)), (1.0, rgb(1, 1, 1, 0))])
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
    ctx.clip()
    ctx.drawRadialGradient(glint, startCenter: CGPoint(x: c.x - radius * 0.45, y: c.y + radius * 0.5), startRadius: 0, endCenter: CGPoint(x: c.x - radius * 0.45, y: c.y + radius * 0.5), endRadius: radius * 0.7, options: [])
    ctx.restoreGState()
}

let wheelY = baseY + 30
let wheelR: CGFloat = 96
let wheelCenters = [CGPoint(x: S * 0.295, y: wheelY), CGPoint(x: S * 0.50, y: wheelY), CGPoint(x: S * 0.705, y: wheelY)]
for c in wheelCenters { spokedWheel(c, wheelR) }
ctx.setStrokeColor(rgb(0.85, 0.34, 0.24))
ctx.setLineWidth(17)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: wheelCenters[0].x, y: wheelY - wheelR * 0.42))
ctx.addLine(to: CGPoint(x: wheelCenters[2].x, y: wheelY - wheelR * 0.42))
ctx.strokePath()
ctx.setStrokeColor(rgb(1.0, 0.62, 0.45, 0.55))
ctx.setLineWidth(5)
ctx.move(to: CGPoint(x: wheelCenters[0].x, y: wheelY - wheelR * 0.42 + 5))
ctx.addLine(to: CGPoint(x: wheelCenters[2].x, y: wheelY - wheelR * 0.42 + 5))
ctx.strokePath()
for c in wheelCenters {
    ctx.setFillColor(inkDark)
    ctx.fillEllipse(in: CGRect(x: c.x - 13, y: wheelY - wheelR * 0.42 - 13, width: 26, height: 26))
    ctx.setFillColor(rgb(0.9, 0.6, 0.45, 0.7))
    ctx.fillEllipse(in: CGRect(x: c.x - 6, y: wheelY - wheelR * 0.42 - 4, width: 9, height: 9))
}

let deckY = baseY + 26 + frameH
let boilerBottom = deckY + 10
let boilerTop = boilerBottom + 240
let boilerLeft = locoLeft + 10
let boilerRight = S * 0.60

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 26, color: rgb(0, 0, 0, 0.45))
let boilerPath = CGPath(roundedRect: CGRect(x: boilerLeft, y: boilerBottom, width: boilerRight - boilerLeft, height: boilerTop - boilerBottom), cornerWidth: 60, cornerHeight: 90, transform: nil)
ctx.addPath(boilerPath)
ctx.setFillColor(rgb(0.1, 0.1, 0.1))
ctx.fillPath()
ctx.restoreGState()
let boilerGrad = grad([
    (0.0, bodyGreenDeep),
    (0.18, bodyGreen),
    (0.52, bodyGreenTop),
    (0.72, rgb(0.45, 0.68, 0.50)),
    (0.86, bodyGreen),
    (1.0, bodyGreenDeep),
])
gradFillPath(boilerPath, boilerGrad, from: CGPoint(x: 0, y: boilerBottom), to: CGPoint(x: 0, y: boilerTop))
ctx.saveGState()
ctx.addPath(boilerPath)
ctx.clip()
let reflect = grad([(0.0, rgb(1.0, 0.85, 0.55, 0.20)), (1.0, rgb(1.0, 0.85, 0.55, 0.0))])
ctx.drawLinearGradient(reflect, start: CGPoint(x: 0, y: boilerBottom), end: CGPoint(x: 0, y: boilerBottom + 60), options: [])
ctx.restoreGState()

for bx in [S * 0.335, S * 0.475] {
    let bandGrad = grad([(0.0, brassLo), (0.35, brassHi), (0.6, brass), (1.0, brassLo)])
    ctx.saveGState()
    ctx.clip(to: CGRect(x: bx - 11, y: boilerBottom + 2, width: 22, height: boilerTop - boilerBottom - 4))
    ctx.drawLinearGradient(bandGrad, start: CGPoint(x: bx - 11, y: 0), end: CGPoint(x: bx + 11, y: 0), options: [])
    ctx.restoreGState()
}

let smokeboxLeft = boilerLeft - 6
let smokeboxPath = CGPath(roundedRect: CGRect(x: smokeboxLeft, y: boilerBottom - 4, width: 110, height: boilerTop - boilerBottom + 8, ), cornerWidth: 40, cornerHeight: 60, transform: nil)
let smokeGradient = grad([(0.0, rgb(0.05, 0.05, 0.06)), (0.5, rgb(0.22, 0.22, 0.25)), (0.75, rgb(0.42, 0.42, 0.46)), (1.0, rgb(0.10, 0.10, 0.12))])
gradFillPath(smokeboxPath, smokeGradient, from: CGPoint(x: 0, y: boilerBottom - 4), to: CGPoint(x: 0, y: boilerTop + 4))
let doorC = CGPoint(x: smokeboxLeft + 55, y: (boilerBottom + boilerTop) / 2)
let doorGrad = grad([(0.0, rgb(0.5, 0.5, 0.54)), (0.5, rgb(0.2, 0.2, 0.23)), (1.0, rgb(0.07, 0.07, 0.08))])
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: doorC.x - 44, y: doorC.y - 60, width: 88, height: 120))
ctx.clip()
ctx.drawRadialGradient(doorGrad, startCenter: CGPoint(x: doorC.x - 16, y: doorC.y + 24), startRadius: 0, endCenter: doorC, endRadius: 90, options: [])
ctx.restoreGState()
let hubGrad2 = grad([(0.0, brassHi), (0.5, brass), (1.0, brassLo)])
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: doorC.x - 13, y: doorC.y - 13, width: 26, height: 26))
ctx.clip()
ctx.drawLinearGradient(hubGrad2, start: CGPoint(x: doorC.x - 13, y: doorC.y + 13), end: CGPoint(x: doorC.x + 13, y: doorC.y - 13), options: [])
ctx.restoreGState()

let chimneyX = smokeboxLeft + 55
let chimneyGrad = grad([(0.0, rgb(0.06, 0.06, 0.07)), (0.45, rgb(0.30, 0.30, 0.33)), (0.7, rgb(0.16, 0.16, 0.18)), (1.0, rgb(0.05, 0.05, 0.06))])
ctx.saveGState()
let chimneyPath = CGMutablePath()
chimneyPath.move(to: CGPoint(x: chimneyX - 26, y: boilerTop - 6))
chimneyPath.addLine(to: CGPoint(x: chimneyX - 32, y: boilerTop + 100))
chimneyPath.addLine(to: CGPoint(x: chimneyX + 32, y: boilerTop + 100))
chimneyPath.addLine(to: CGPoint(x: chimneyX + 26, y: boilerTop - 6))
chimneyPath.closeSubpath()
ctx.addPath(chimneyPath)
ctx.clip()
ctx.drawLinearGradient(chimneyGrad, start: CGPoint(x: chimneyX - 32, y: 0), end: CGPoint(x: chimneyX + 32, y: 0), options: [])
ctx.restoreGState()
let capGrad = grad([(0.0, rgb(0.45, 0.22, 0.12)), (0.4, rgb(0.85, 0.48, 0.28)), (0.6, rgb(0.95, 0.62, 0.38)), (1.0, rgb(0.5, 0.25, 0.13))])
let capPath = CGPath(roundedRect: CGRect(x: chimneyX - 42, y: boilerTop + 92, width: 84, height: 30), cornerWidth: 10, cornerHeight: 10, transform: nil)
gradFillPath(capPath, capGrad, from: CGPoint(x: chimneyX - 42, y: 0), to: CGPoint(x: chimneyX + 42, y: 0))

let domeX = S * 0.405
ctx.saveGState()
let domePath = CGMutablePath()
domePath.addArc(center: CGPoint(x: domeX, y: boilerTop - 8), radius: 52, startAngle: 0, endAngle: .pi, clockwise: false)
domePath.closeSubpath()
ctx.addPath(domePath)
ctx.clip()
let domeGrad = grad([(0.0, brassLo), (0.35, brass), (0.55, brassHi), (0.8, brass), (1.0, brassLo)])
ctx.drawLinearGradient(domeGrad, start: CGPoint(x: domeX - 52, y: 0), end: CGPoint(x: domeX + 52, y: 0), options: [])
ctx.restoreGState()
ctx.setFillColor(rgb(1, 1, 0.9, 0.5))
ctx.fillEllipse(in: CGRect(x: domeX - 18, y: boilerTop + 14, width: 16, height: 22))

let cabLeft = S * 0.60
let cabRight = locoRight - 6
let cabTop = boilerBottom + 330
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 22, color: rgb(0, 0, 0, 0.4))
let cabPath = CGPath(roundedRect: CGRect(x: cabLeft, y: deckY + 4, width: cabRight - cabLeft, height: cabTop - deckY - 4, ), cornerWidth: 26, cornerHeight: 26, transform: nil)
ctx.addPath(cabPath)
ctx.setFillColor(rgb(0.1, 0.1, 0.1))
ctx.fillPath()
ctx.restoreGState()
let cabGrad = grad([
    (0.0, bodyGreenDeep),
    (0.25, bodyGreen),
    (0.6, rgb(0.22, 0.45, 0.30)),
    (1.0, rgb(0.30, 0.54, 0.38)),
])
gradFillPath(cabPath, cabGrad, from: CGPoint(x: cabLeft, y: 0), to: CGPoint(x: cabRight, y: 0))
ctx.setStrokeColor(rgb(0.92, 0.78, 0.44, 0.85))
ctx.setLineWidth(5)
ctx.addPath(CGPath(roundedRect: CGRect(x: cabLeft + 16, y: deckY + 20, width: cabRight - cabLeft - 32, height: cabTop - deckY - 40), cornerWidth: 18, cornerHeight: 18, transform: nil))
ctx.strokePath()
let winRect = CGRect(x: cabLeft + 44, y: cabTop - 148, width: cabRight - cabLeft - 88, height: 104)
let winGrad = grad([(0.0, rgb(1.0, 0.72, 0.32)), (0.5, rgb(1.0, 0.85, 0.52)), (1.0, rgb(1.0, 0.93, 0.72))])
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 30, color: rgb(1.0, 0.8, 0.45, 0.8))
ctx.addPath(CGPath(roundedRect: winRect, cornerWidth: 16, cornerHeight: 16, transform: nil))
ctx.setFillColor(rgb(1.0, 0.85, 0.5))
ctx.fillPath()
ctx.restoreGState()
gradFillPath(CGPath(roundedRect: winRect, cornerWidth: 16, cornerHeight: 16, transform: nil), winGrad, from: CGPoint(x: 0, y: winRect.minY), to: CGPoint(x: 0, y: winRect.maxY))
ctx.setStrokeColor(rgb(0.06, 0.16, 0.10, 0.9))
ctx.setLineWidth(6)
ctx.addPath(CGPath(roundedRect: winRect, cornerWidth: 16, cornerHeight: 16, transform: nil))
ctx.strokePath()

let roofPath = CGMutablePath()
roofPath.move(to: CGPoint(x: cabLeft - 30, y: cabTop - 10))
roofPath.addQuadCurve(to: CGPoint(x: cabRight + 30, y: cabTop - 10), control: CGPoint(x: (cabLeft + cabRight) / 2, y: cabTop + 58))
roofPath.addLine(to: CGPoint(x: cabRight + 30, y: cabTop - 26))
roofPath.addLine(to: CGPoint(x: cabLeft - 30, y: cabTop - 26))
roofPath.closeSubpath()
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 16, color: rgb(0, 0, 0, 0.4))
ctx.addPath(roofPath)
ctx.setFillColor(rgb(0.1, 0.1, 0.1))
ctx.fillPath()
ctx.restoreGState()
let roofGrad = grad([(0.0, rgb(0.13, 0.12, 0.11)), (0.42, rgb(0.36, 0.34, 0.32)), (0.58, rgb(0.44, 0.42, 0.40)), (1.0, rgb(0.14, 0.13, 0.12))])
gradFillPath(roofPath, roofGrad, from: CGPoint(x: cabLeft - 30, y: 0), to: CGPoint(x: cabRight + 30, y: 0))
ctx.setFillColor(rgb(1.0, 0.9, 0.7, 0.18))
ctx.fill(CGRect(x: cabLeft - 30, y: cabTop + 20, width: cabRight - cabLeft + 60, height: 5))

let bufferGrad = grad([(0.0, rgb(0.3, 0.28, 0.26)), (0.5, rgb(0.6, 0.58, 0.54)), (1.0, rgb(0.2, 0.18, 0.17))])
for (bx, dir) in [(locoLeft - 14, CGFloat(-1)), (locoRight + 14, CGFloat(1))] {
    ctx.setStrokeColor(rgb(0.15, 0.13, 0.11))
    ctx.setLineWidth(14)
    ctx.move(to: CGPoint(x: bx, y: deckY - 12))
    ctx.addLine(to: CGPoint(x: bx + dir * 24, y: deckY - 12))
    ctx.strokePath()
    ctx.saveGState()
    ctx.clip(to: CGRect(x: bx + dir * 24 - (dir < 0 ? 12 : 0), y: deckY - 34, width: 12, height: 44))
    ctx.drawLinearGradient(bufferGrad, start: CGPoint(x: 0, y: deckY - 34), end: CGPoint(x: 0, y: deckY + 10), options: [])
    ctx.restoreGState()
}

var puffC = CGPoint(x: chimneyX + 30, y: boilerTop + 170)
var puffR: CGFloat = 44
for k in 0..<4 {
    let cloud = grad([(0.0, rgb(0.98, 0.96, 0.92, 0.85 - CGFloat(k) * 0.16)), (0.7, rgb(0.92, 0.88, 0.82, 0.5 - CGFloat(k) * 0.1)), (1.0, rgb(0.9, 0.86, 0.8, 0.0))])
    ctx.drawRadialGradient(cloud, startCenter: CGPoint(x: puffC.x - puffR * 0.2, y: puffC.y + puffR * 0.2), startRadius: 0, endCenter: puffC, endRadius: puffR, options: [])
    puffC.x += puffR * 0.9
    puffC.y += puffR * 0.95
    puffR *= 1.35
}

for _ in 0..<28 {
    let x = rand.next() * S
    let y = S * 0.3 + rand.next() * S * 0.65
    let r = rand.range(2, 5)
    ctx.setFillColor(rgb(1.0, 0.88, 0.6, rand.range(0.06, 0.22)))
    ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
}

let vin = grad([(0.0, rgb(0, 0, 0, 0)), (1.0, rgb(0.05, 0.02, 0.0, 0.4))])
ctx.drawRadialGradient(vin, startCenter: CGPoint(x: S / 2, y: S / 2), startRadius: S * 0.42, endCenter: CGPoint(x: S / 2, y: S / 2), endRadius: S * 0.75, options: [.drawsAfterEndLocation])

let img = ctx.makeImage()!
let url = URL(fileURLWithPath: outPath) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("icon written")
