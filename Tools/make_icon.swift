// Generates the app icon at 1024×1024 in the three appearances iOS asks for.
//
//   swift Tools/make_icon.swift light  out.png   full colour on the dark slate
//   swift Tools/make_icon.swift dark   out.png   same artwork, transparent ground
//   swift Tools/make_icon.swift tinted out.png   greyscale, transparent ground
//   swift Tools/make_icon.swift watch  out.png   same artwork on warm birch
//
// The iOS light appearance uses `light`. The dark and tinted variants
// deliberately omit the background: iOS composites its own behind them, and a
// baked-in background is what makes a tinted icon look wrong.
//
// watchOS uses `watch`, which is `light` with the slate ground swapped for a
// warm birch one and the artwork re-weighted to sit on it. watchOS masks the
// icon into a circle and draws it on a black home screen, so the near-black
// ground of `light` made the icon read as loose artwork floating in the void
// rather than as a circle — which is what App Review rejected under
// guideline 4.

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum Appearance: String {
    case light, dark, tinted, watch

    var drawsBackground: Bool { self == .light || self == .watch }
    var isGreyscale: Bool { self == .tinted }
    /// True when the artwork sits on a light ground and has to be darkened
    /// rather than lifted to keep its contrast.
    var isLightGround: Bool { self == .watch }
}

let arguments = CommandLine.arguments
guard arguments.count >= 3, let appearance = Appearance(rawValue: arguments[1]) else {
    FileHandle.standardError.write(Data("usage: make_icon.swift <light|dark|tinted|watch> <output.png>\n".utf8))
    exit(1)
}
let outputPath = arguments[2]

let size = 1024
let cs = CGColorSpaceCreateDeviceRGB()

guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("no ctx") }

/// Colours collapse to their luminance in the tinted appearance, so the
/// artwork still reads once iOS replaces the hue with the user's tint.
func rgb(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    if appearance.isGreyscale {
        let luma = (0.2126 * CGFloat(r) + 0.7152 * CGFloat(g) + 0.0722 * CGFloat(b)) / 255
        return CGColor(colorSpace: cs, components: [luma, luma, luma, a])!
    }
    return CGColor(colorSpace: cs, components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, a])!
}

let W = CGFloat(size)

// Work in top-left origin coordinates, like the layout was designed.
ctx.translateBy(x: 0, y: W)
ctx.scaleBy(x: 1, y: -1)

// ---------- background ----------
// iOS: clean dark slate rather than a brown haze, so the orange reads as heat.
// watchOS: warm birch instead, light enough that the circular mask is visible
// against the black home screen.
if appearance.drawsBackground {
    ctx.saveGState()
    let bgColors = appearance.isLightGround
        ? [rgb(255, 243, 223), rgb(246, 222, 186), rgb(232, 197, 145)] as CFArray
        : [rgb(46, 44, 52), rgb(24, 23, 28), rgb(13, 12, 15)] as CFArray
    let bg = CGGradient(colorsSpace: cs, colors: bgColors, locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(
        bg,
        start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: W),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    ctx.restoreGState()
}

// ---------- warm glow (behind everything, so nothing gets washed out) ----------
// Only meaningful over a background; on a transparent ground it would just
// smear a haze into the alpha channel.
if appearance.drawsBackground {
    ctx.saveGState()
    // A glow that lightens is invisible on the light ground, so there it
    // warms the birch downwards instead of blooming out of it.
    let glowColors = appearance.isLightGround
        ? [rgb(255, 168, 74, 0.42), rgb(255, 150, 60, 0.14), rgb(255, 150, 60, 0)] as CFArray
        : [rgb(255, 116, 32, 0.50), rgb(255, 110, 30, 0.16), rgb(255, 110, 30, 0)] as CFArray
    let glow = CGGradient(
        colorsSpace: cs,
        colors: glowColors,
        locations: [0, 0.45, 1]
    )!
    ctx.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: W*0.5, y: W*0.66), startRadius: 0,
        endCenter: CGPoint(x: W*0.5, y: W*0.66), endRadius: W*0.46,
        options: []
    )
    ctx.restoreGState()
}

// ---------- heat waves ----------
// Thick snaking strokes with round caps, so the silhouette survives being
// scaled down to a watch home screen.
func wavePath(x: CGFloat, bottom: CGFloat, top: CGFloat, amp: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let h = bottom - top
    p.move(to: CGPoint(x: x, y: bottom))
    p.addCurve(
        to: CGPoint(x: x, y: bottom - h*0.5),
        control1: CGPoint(x: x + amp, y: bottom - h*0.16),
        control2: CGPoint(x: x + amp, y: bottom - h*0.34)
    )
    p.addCurve(
        to: CGPoint(x: x, y: top),
        control1: CGPoint(x: x - amp, y: bottom - h*0.66),
        control2: CGPoint(x: x - amp, y: bottom - h*0.84)
    )
    return p
}

struct Wave { let x: CGFloat; let bottom: CGFloat; let top: CGFloat; let amp: CGFloat; let width: CGFloat; let c0: CGColor; let c1: CGColor }

// The bright end of each wave is what a dark ground needs and a light one
// cannot carry: cream on birch is nearly invisible, so the light ground gets
// a deeper, more saturated pair that still reads as heat.
let waves: [Wave] = appearance.isLightGround
    ? [
        Wave(x: W*0.295, bottom: W*0.635, top: W*0.255, amp: W*0.090, width: W*0.062,
             c0: rgb(240, 108, 30), c1: rgb(186, 38, 16)),
        Wave(x: W*0.705, bottom: W*0.635, top: W*0.255, amp: -W*0.090, width: W*0.062,
             c0: rgb(240, 108, 30), c1: rgb(186, 38, 16)),
        Wave(x: W*0.50, bottom: W*0.655, top: W*0.150, amp: W*0.112, width: W*0.082,
             c0: rgb(255, 150, 40), c1: rgb(206, 52, 18)),
    ]
    : [
        Wave(x: W*0.295, bottom: W*0.635, top: W*0.255, amp: W*0.090, width: W*0.062,
             c0: rgb(255, 146, 54), c1: rgb(244, 78, 30)),
        Wave(x: W*0.705, bottom: W*0.635, top: W*0.255, amp: -W*0.090, width: W*0.062,
             c0: rgb(255, 146, 54), c1: rgb(244, 78, 30)),
        Wave(x: W*0.50, bottom: W*0.655, top: W*0.150, amp: W*0.112, width: W*0.082,
             c0: rgb(255, 220, 120), c1: rgb(255, 126, 34)),
    ]

for w in waves {
    ctx.saveGState()
    ctx.setLineWidth(w.width)
    ctx.setLineCap(.round)
    ctx.addPath(wavePath(x: w.x, bottom: w.bottom, top: w.top, amp: w.amp))
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    let g = CGGradient(colorsSpace: cs, colors: [w.c1, w.c0] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(
        g,
        start: CGPoint(x: 0, y: w.bottom), end: CGPoint(x: 0, y: w.top),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    ctx.restoreGState()
}

// ---------- sauna stones ----------
// Drawn over the wave roots so the heat reads as rising out of the stones.
struct Stone { let x: CGFloat; let y: CGFloat; let r: CGFloat; let shade: CGFloat }
let stones: [Stone] = [
    Stone(x: W*0.255, y: W*0.700, r: W*0.098, shade: 0.72),
    Stone(x: W*0.745, y: W*0.700, r: W*0.098, shade: 0.72),
    Stone(x: W*0.410, y: W*0.735, r: W*0.115, shade: 1.0),
    Stone(x: W*0.605, y: W*0.730, r: W*0.108, shade: 0.86),
]

// Without a background the stones would sink into whatever iOS puts behind
// them, so they are lifted for the dark and tinted appearances.
let stoneLift: CGFloat = appearance.drawsBackground ? 1.0 : 1.55

for s in stones {
    let top = rgb(
        min(255, Int(126 * s.shade * stoneLift)),
        min(255, Int(124 * s.shade * stoneLift)),
        min(255, Int(134 * s.shade * stoneLift))
    )
    let bottom = rgb(
        min(255, Int(40 * s.shade * stoneLift)),
        min(255, Int(39 * s.shade * stoneLift)),
        min(255, Int(46 * s.shade * stoneLift))
    )
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r*2, height: s.r*2))
    ctx.clip()
    let g = CGGradient(colorsSpace: cs, colors: [bottom, top] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(
        g,
        start: CGPoint(x: 0, y: s.y - s.r), end: CGPoint(x: 0, y: s.y + s.r),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    // warm rim on the upper edge — the stones are the thing that is hot
    ctx.setLineWidth(W*0.007)
    ctx.setStrokeColor(rgb(255, 150, 70, 0.32 * s.shade))
    ctx.addEllipse(in: CGRect(x: s.x - s.r*0.99, y: s.y - s.r*0.99, width: s.r*1.98, height: s.r*1.98))
    ctx.strokePath()
    ctx.restoreGState()
}

// ---------- heater base ----------
let baseRect = CGRect(x: W*0.215, y: W*0.800, width: W*0.57, height: W*0.062)
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: baseRect, cornerWidth: W*0.022, cornerHeight: W*0.022, transform: nil))
ctx.clip()
let baseG = CGGradient(
    colorsSpace: cs,
    colors: [
        rgb(min(255, Int(30 * stoneLift)), min(255, Int(29 * stoneLift)), min(255, Int(35 * stoneLift))),
        rgb(min(255, Int(72 * stoneLift)), min(255, Int(70 * stoneLift)), min(255, Int(80 * stoneLift))),
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    baseG,
    start: CGPoint(x: 0, y: baseRect.minY), end: CGPoint(x: 0, y: baseRect.maxY),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)
ctx.restoreGState()

guard let image = ctx.makeImage() else { fatalError("no image") }
let out = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("no dest")
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(appearance.rawValue) -> \(out.path)")
