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
    var state: UInt64 = 88172645463325252
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

let oakLight = rgb(0.80, 0.62, 0.41)
let oak = rgb(0.68, 0.50, 0.30)
let oakDark = rgb(0.49, 0.34, 0.19)
let ink = rgb(0.17, 0.13, 0.09)

let grad = CGGradient(colorsSpace: cs, colors: [oakLight, oak, oakDark] as CFArray, locations: [0, 0.55, 1])!
ctx.drawRadialGradient(grad, startCenter: CGPoint(x: S * 0.44, y: S * 0.62), startRadius: 0, endCenter: CGPoint(x: S * 0.5, y: S * 0.5), endRadius: S * 0.82, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

for _ in 0..<60 {
    let y = rand.next() * S
    ctx.setStrokeColor(rgb(0.42, 0.28, 0.15, rand.range(0.06, 0.16)))
    ctx.setLineWidth(rand.range(1.6, 4.2))
    ctx.move(to: CGPoint(x: -10, y: y))
    var x: CGFloat = -10
    var yy = y
    while x < S + 10 {
        x += rand.range(60, 140)
        yy += rand.range(-8, 8)
        ctx.addLine(to: CGPoint(x: x, y: yy))
    }
    ctx.strokePath()
}
for _ in 0..<7 {
    let kx = rand.next() * S
    let ky = rand.next() * S
    let kr = rand.range(14, 30)
    ctx.setStrokeColor(rgb(0.40, 0.26, 0.14, 0.5))
    ctx.setLineWidth(3)
    ctx.strokeEllipse(in: CGRect(x: kx - kr, y: ky - kr * 0.7, width: kr * 2, height: kr * 1.4))
    ctx.setLineWidth(2)
    ctx.strokeEllipse(in: CGRect(x: kx - kr * 0.5, y: ky - kr * 0.35, width: kr, height: kr * 0.7))
}

let c = CGPoint(x: S / 2, y: S / 2)
let matR: CGFloat = S * 0.335
ctx.setFillColor(rgb(0, 0, 0, 0.22))
ctx.fillEllipse(in: CGRect(x: c.x - matR - 14, y: c.y - matR - 26, width: (matR + 14) * 2, height: (matR + 14) * 2))
let matGrad = CGGradient(colorsSpace: cs, colors: [rgb(0.66, 0.75, 0.49), rgb(0.53, 0.63, 0.38)] as CFArray, locations: [0, 1])!
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: c.x - matR, y: c.y - matR, width: matR * 2, height: matR * 2))
ctx.clip()
ctx.drawLinearGradient(matGrad, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])
for _ in 0..<240 {
    let a = rand.next() * 2 * .pi
    let rr = sqrt(rand.next()) * matR
    let x = c.x + cos(a) * rr
    let y = c.y + sin(a) * rr
    ctx.setStrokeColor(rgb(0.42, 0.52, 0.29, rand.range(0.2, 0.5)))
    ctx.setLineWidth(2)
    ctx.move(to: CGPoint(x: x, y: y))
    ctx.addLine(to: CGPoint(x: x + rand.range(-5, 5), y: y + rand.range(6, 14)))
    ctx.strokePath()
}
ctx.restoreGState()
ctx.setStrokeColor(rgb(0.45, 0.31, 0.17))
ctx.setLineWidth(10)
ctx.strokeEllipse(in: CGRect(x: c.x - matR, y: c.y - matR, width: matR * 2, height: matR * 2))

let trackR: CGFloat = matR * 0.74
ctx.setStrokeColor(rgb(0.66, 0.62, 0.55, 0.9))
ctx.setLineWidth(46)
ctx.strokeEllipse(in: CGRect(x: c.x - trackR, y: c.y - trackR, width: trackR * 2, height: trackR * 2))
let sleeperCount = 34
for i in 0..<sleeperCount {
    let a = CGFloat(i) / CGFloat(sleeperCount) * 2 * .pi
    ctx.saveGState()
    ctx.translateBy(x: c.x + cos(a) * trackR, y: c.y + sin(a) * trackR)
    ctx.rotate(by: a)
    ctx.setFillColor(rgb(0.40, 0.29, 0.18))
    ctx.fill(CGRect(x: -30, y: -7, width: 60, height: 14))
    ctx.restoreGState()
}
for gauge in [-15.0, 15.0] {
    ctx.setStrokeColor(rgb(0.36, 0.34, 0.31))
    ctx.setLineWidth(9)
    ctx.strokeEllipse(in: CGRect(x: c.x - trackR - CGFloat(gauge), y: c.y - trackR - CGFloat(gauge), width: (trackR + CGFloat(gauge)) * 2, height: (trackR + CGFloat(gauge)) * 2))
}

func pine(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
    ctx.setFillColor(rgb(0, 0, 0, 0.18))
    ctx.fillEllipse(in: CGRect(x: x - s * 0.34, y: y - s * 0.10, width: s * 0.68, height: s * 0.16))
    ctx.setFillColor(rgb(0.35, 0.25, 0.15))
    ctx.fill(CGRect(x: x - s * 0.05, y: y, width: s * 0.1, height: s * 0.18))
    for i in 0..<3 {
        let f = CGFloat(i)
        let tw = s * (0.62 - f * 0.15)
        let ty = y + s * (0.12 + f * 0.24)
        ctx.setFillColor(i == 0 ? rgb(0.16, 0.32, 0.22) : (i == 1 ? rgb(0.20, 0.38, 0.26) : rgb(0.26, 0.45, 0.31)))
        ctx.move(to: CGPoint(x: x, y: ty + s * 0.32))
        ctx.addLine(to: CGPoint(x: x - tw / 2, y: ty))
        ctx.addLine(to: CGPoint(x: x + tw / 2, y: ty))
        ctx.closePath()
        ctx.fillPath()
        ctx.setStrokeColor(ink)
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: x, y: ty + s * 0.32))
        ctx.addLine(to: CGPoint(x: x - tw / 2, y: ty))
        ctx.addLine(to: CGPoint(x: x + tw / 2, y: ty))
        ctx.closePath()
        ctx.strokePath()
    }
}

pine(c.x - matR * 0.30, c.y + matR * 0.10, 190)
pine(c.x + matR * 0.34, c.y + matR * 0.02, 150)

let houseX = c.x + matR * 0.02
let houseY = c.y - matR * 0.44
let hs: CGFloat = 150
ctx.setFillColor(rgb(0, 0, 0, 0.18))
ctx.fillEllipse(in: CGRect(x: houseX - hs * 0.6, y: houseY - hs * 0.1, width: hs * 1.2, height: hs * 0.2))
ctx.setFillColor(rgb(0.92, 0.88, 0.78))
ctx.fill(CGRect(x: houseX - hs / 2, y: houseY, width: hs, height: hs * 0.5))
ctx.setStrokeColor(ink)
ctx.setLineWidth(4)
ctx.stroke(CGRect(x: houseX - hs / 2, y: houseY, width: hs, height: hs * 0.5))
ctx.setFillColor(rgb(0.62, 0.23, 0.17))
ctx.move(to: CGPoint(x: houseX - hs * 0.6, y: houseY + hs * 0.5))
ctx.addLine(to: CGPoint(x: houseX, y: houseY + hs * 0.86))
ctx.addLine(to: CGPoint(x: houseX + hs * 0.6, y: houseY + hs * 0.5))
ctx.closePath()
ctx.fillPath()
ctx.setStrokeColor(ink)
ctx.move(to: CGPoint(x: houseX - hs * 0.6, y: houseY + hs * 0.5))
ctx.addLine(to: CGPoint(x: houseX, y: houseY + hs * 0.86))
ctx.addLine(to: CGPoint(x: houseX + hs * 0.6, y: houseY + hs * 0.5))
ctx.closePath()
ctx.strokePath()
ctx.setFillColor(rgb(0.96, 0.83, 0.45))
ctx.fill(CGRect(x: houseX - hs * 0.3, y: houseY + hs * 0.14, width: hs * 0.2, height: hs * 0.22))
ctx.fill(CGRect(x: houseX + hs * 0.1, y: houseY + hs * 0.14, width: hs * 0.2, height: hs * 0.22))
ctx.setLineWidth(3)
ctx.setStrokeColor(ink)
ctx.stroke(CGRect(x: houseX - hs * 0.3, y: houseY + hs * 0.14, width: hs * 0.2, height: hs * 0.22))
ctx.stroke(CGRect(x: houseX + hs * 0.1, y: houseY + hs * 0.14, width: hs * 0.2, height: hs * 0.22))

let locoA: CGFloat = -.pi * 0.82
let locoC = CGPoint(x: c.x + cos(locoA) * trackR, y: c.y + sin(locoA) * trackR)
ctx.saveGState()
ctx.translateBy(x: locoC.x, y: locoC.y)
ctx.rotate(by: locoA + .pi / 2)
let bl: CGFloat = 300
let bw: CGFloat = 128
ctx.setFillColor(rgb(0, 0, 0, 0.28))
ctx.fillEllipse(in: CGRect(x: -bl / 2 + 10, y: -bw / 2 - 12, width: bl, height: bw))
let bodyRect = CGRect(x: -bl / 2, y: -bw / 2, width: bl, height: bw)
ctx.setFillColor(rgb(0.16, 0.36, 0.25))
let rr = CGPath(roundedRect: bodyRect, cornerWidth: 34, cornerHeight: 34, transform: nil)
ctx.addPath(rr)
ctx.fillPath()
ctx.setStrokeColor(ink)
ctx.setLineWidth(7)
ctx.addPath(rr)
ctx.strokePath()
ctx.setFillColor(rgb(0.11, 0.26, 0.18))
let cabRect = CGRect(x: -bl / 2 + 18, y: -bw / 2 + 14, width: 88, height: bw - 28)
let cabPath = CGPath(roundedRect: cabRect, cornerWidth: 16, cornerHeight: 16, transform: nil)
ctx.addPath(cabPath)
ctx.fillPath()
ctx.setStrokeColor(rgb(0.9, 0.78, 0.45))
ctx.setLineWidth(5)
ctx.addPath(cabPath)
ctx.strokePath()
ctx.setFillColor(rgb(0.85, 0.68, 0.32))
ctx.fillEllipse(in: CGRect(x: -20, y: -26, width: 52, height: 52))
ctx.setStrokeColor(ink)
ctx.setLineWidth(5)
ctx.strokeEllipse(in: CGRect(x: -20, y: -26, width: 52, height: 52))
ctx.setFillColor(rgb(0.13, 0.10, 0.08))
ctx.fillEllipse(in: CGRect(x: bl / 2 - 82, y: -21, width: 42, height: 42))
ctx.setStrokeColor(rgb(0.85, 0.68, 0.32))
ctx.setLineWidth(5)
ctx.strokeEllipse(in: CGRect(x: bl / 2 - 82, y: -21, width: 42, height: 42))
ctx.setFillColor(rgb(0.94, 0.90, 0.82))
ctx.fillEllipse(in: CGRect(x: bl / 2 - 26, y: -13, width: 26, height: 26))
ctx.restoreGState()

var puffC = CGPoint(x: locoC.x + 130, y: locoC.y + 60)
var puffR: CGFloat = 26
for _ in 0..<3 {
    ctx.setFillColor(rgb(1, 1, 1, 0.55))
    ctx.fillEllipse(in: CGRect(x: puffC.x - puffR, y: puffC.y - puffR, width: puffR * 2, height: puffR * 2))
    ctx.setStrokeColor(rgb(0.25, 0.2, 0.15, 0.4))
    ctx.setLineWidth(4)
    ctx.strokeEllipse(in: CGRect(x: puffC.x - puffR, y: puffC.y - puffR, width: puffR * 2, height: puffR * 2))
    puffC.x += puffR * 1.5
    puffC.y += puffR * 1.7
    puffR *= 1.35
}

let vGrad = CGGradient(colorsSpace: cs, colors: [rgb(0, 0, 0, 0.0), rgb(0.1, 0.05, 0.02, 0.25)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(vGrad, startCenter: c, startRadius: S * 0.35, endCenter: c, endRadius: S * 0.75, options: [.drawsAfterEndLocation])

let img = ctx.makeImage()!
let url = URL(fileURLWithPath: outPath) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("icon written to \(outPath)")
