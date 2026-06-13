import AppKit

// Sudoku app icon — premium blue theme. Royal-blue gradient, glossy white board with
// soft depth, a highlighted "active" cell, and balanced numerals with gold accents.
// 1024×1024. (Flatten the result to drop alpha for the App Store.)
let px = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/AppIcon-1024.png"
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
  colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
let S = CGFloat(px)
let full = NSRect(x: 0, y: 0, width: S, height: S)

// Background: deep royal blue -> bright azure, diagonal.
let deep = NSColor(srgbRed: 0.07, green: 0.16, blue: 0.49, alpha: 1)
let bright = NSColor(srgbRed: 0.16, green: 0.50, blue: 0.98, alpha: 1)
NSGradient(starting: deep, ending: bright)!.draw(in: full, angle: -50)
// Radial glow top-left for a glossy feel.
NSGradient(colors: [NSColor(white: 1, alpha: 0.22), NSColor(white: 1, alpha: 0)])!
    .draw(in: full, relativeCenterPosition: NSPoint(x: -0.4, y: 0.55))
// Subtle vignette bottom-right.
NSGradient(colors: [NSColor(white: 0, alpha: 0), NSColor(red: 0.03, green: 0.07, blue: 0.25, alpha: 0.35)])!
    .draw(in: full, relativeCenterPosition: NSPoint(x: 0.55, y: -0.55))

// Glossy white board card.
let m: CGFloat = S * 0.155
let board = NSRect(x: m, y: m, width: S - 2*m, height: S - 2*m)
ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 52, color: NSColor(white: 0.02, alpha: 0.38).cgColor)
let boardPath = NSBezierPath(roundedRect: board, xRadius: 62, yRadius: 62)
NSColor.white.setFill(); boardPath.fill()
ctx.setShadow(offset: .zero, blur: 0, color: nil)

ctx.saveGState()
boardPath.addClip()
// Faint top gloss on the board.
NSGradient(colors: [NSColor(white: 1, alpha: 0.0), NSColor(srgbRed: 0.90, green: 0.94, blue: 1.0, alpha: 0.5)])!
    .draw(in: board, angle: -90)
NSColor.white.withAlphaComponent(0.0).setFill()

let cell = board.width / 3
// Highlighted active cell (centre) in soft brand blue.
let hlRect = NSRect(x: board.minX + cell, y: board.minY + cell, width: cell, height: cell)
NSColor(srgbRed: 0.16, green: 0.50, blue: 0.98, alpha: 0.16).setFill()
NSBezierPath(rect: hlRect).fill()

// Thin inner grid lines.
NSColor(srgbRed: 0.80, green: 0.85, blue: 0.93, alpha: 1).setStroke()
for i in 1..<3 {
    let p = NSBezierPath(); p.lineWidth = 7
    let x = board.minX + CGFloat(i) * cell
    p.move(to: NSPoint(x: x, y: board.minY)); p.line(to: NSPoint(x: x, y: board.maxY))
    let y = board.minY + CGFloat(i) * cell
    p.move(to: NSPoint(x: board.minX, y: y)); p.line(to: NSPoint(x: board.maxX, y: y))
    p.stroke()
}
ctx.restoreGState()

// Crisp inner border.
let inner = NSBezierPath(roundedRect: board.insetBy(dx: 7, dy: 7), xRadius: 55, yRadius: 55)
inner.lineWidth = 5
NSColor(srgbRed: 0.86, green: 0.90, blue: 0.97, alpha: 1).setStroke()
inner.stroke()

// Numerals (row 0 = TOP). Royal blue with two gold accents; centre highlighted gold.
let blue = NSColor(srgbRed: 0.11, green: 0.34, blue: 0.90, alpha: 1)
let gold = NSColor(srgbRed: 0.98, green: 0.72, blue: 0.11, alpha: 1)
let seeds: [(Int, Int, String, NSColor)] = [
    (0, 0, "5", blue), (0, 1, "3", gold), (0, 2, "8", blue),
    (1, 0, "6", blue), (1, 1, "7", gold), (1, 2, "2", blue),
    (2, 0, "1", gold), (2, 2, "9", blue),
]
let font = NSFont.systemFont(ofSize: cell * 0.58, weight: .bold)
for (row, col, digit, color) in seeds {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let str = NSAttributedString(string: digit, attributes: attrs)
    let sz = str.size()
    let cx = board.minX + (CGFloat(col) + 0.5) * cell
    let cy = board.minY + (CGFloat(2 - row) + 0.5) * cell
    str.draw(at: NSPoint(x: cx - sz.width/2, y: cy - sz.height/2))
}

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
