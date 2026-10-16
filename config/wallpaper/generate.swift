// Generates abstract Catppuccin Mocha wallpapers: layered translucent waves in
// the palette's accents over its dark base, one or two soft glows, a gentle
// vignette, and fine grain (dark gradients band visibly without it). Each variant has a landscape layout for
// the Mac and a portrait one for the phone, so neither is a crop of the other.
// Deterministic: the same variant and size always give the same image.
//
// Usage (via the `wallpapers` script):
//   generate <variant> <width> <height> <out.png>
//   generate --sheet <out.png> [variant…]   one preview image of the variants

import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

typealias RGB = (r: Double, g: Double, b: Double)

func hex(_ s: String) -> RGB {
    let v = Int(s, radix: 16)!
    return (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
}

// Catppuccin Mocha
let base = hex("1e1e2e"), crust = hex("11111b")
let mauve = hex("cba6f7"), blue = hex("89b4fa"), pink = hex("f5c2e7"), lavender = hex("b4befe")
let sapphire = hex("74c7ec"), teal = hex("94e2d5"), peach = hex("fab387"), maroon = hex("eba0ac")

// A glow: color, center (fractions of width/height, from the top-left),
// radius (fraction of the longer side), peak opacity
struct Glow { let color: RGB; let x: Double; let y: Double; let r: Double; let a: Double }
// A wave band, filled from its crest line down to the bottom edge: mean height
// (fraction from the top), amplitude (fraction of the height), cycles across
// the width, phase (fraction of a cycle), opacity. Listed back to front.
struct Wave { let color: RGB; let y: Double; let amp: Double; let cycles: Double; let phase: Double; let a: Double }
// Thin wavy lines, top to bottom between y0 and y1 (fractions from the top),
// colors interpolated across `colors`, opacity from a0 to a1
struct Lines { let count: Int; let y0: Double; let y1: Double; let amp: Double; let cycles: Double
               let colors: [RGB]; let a0: Double; let a1: Double; let width: Double }
// Concentric rings around (x, y), `spacing` apart (fractions of the longer side)
struct Rings { let x: Double; let y: Double; let count: Int; let spacing: Double
               let colors: [RGB]; let a0: Double; let a1: Double; let width: Double }
// A mountain ridgeline at mean height y with peaks up to `height`, filled down
struct Ridge { let color: RGB; let y: Double; let height: Double; let peaks: Int; let seed: UInt64; let a: Double }
// Soft out-of-focus dots, scattered by a seeded PRNG within the y band
struct Bokeh { let count: Int; let seed: UInt64; let y0: Double; let y1: Double
               let r0: Double; let r1: Double; let colors: [RGB]; let a: Double }
// Geometry. All sizes are fractions of the longer side, so cell counts adapt to
// the shape; `y0` is where the pattern starts (fraction from the top) and
// opacity ramps from a0 there to a1 at the bottom.
struct LowPoly { let cell: Double; let jitter: Double; let seed: UInt64; let y0: Double
                 let colors: [RGB]; let a0: Double; let a1: Double }
struct Hexes { let radius: Double; let seed: UInt64; let y0: Double; let colors: [RGB]
               let line: Double; let fill: Double }
struct Shards { let count: Int; let seed: UInt64; let y0: Double; let size: Double; let colors: [RGB]; let a: Double }
struct Halftone { let spacing: Double; let y0: Double; let maxDot: Double; let colors: [RGB]; let a: Double }
// Facet patterns share LowPoly's fields: cell size, jitter, seed, start height,
// colors along the height, opacity from a0 to a1
typealias Facets = LowPoly
// Faceted mountains: `layers` ridgelines from y0 down, each split into triangles
struct Peaks { let layers: Int; let seed: UInt64; let y0: Double; let height: Double
               let colors: [RGB]; let a0: Double; let a1: Double }
struct Layout {
    var glows: [Glow] = []; var waves: [Wave] = []; var lines: [Lines] = []
    var rings: [Rings] = []; var ridges: [Ridge] = []; var bokeh: [Bokeh] = []
    var lowpoly: [LowPoly] = []; var hexes: [Hexes] = []; var shards: [Shards] = []; var halftone: [Halftone] = []
    var crystal: [Facets] = []; var lattice: [Facets] = []; var blocks: [Facets] = []; var peaks: [Peaks] = []
}

// Deterministic PRNG (xorshift64*), so the same seed always gives the same scatter
struct Random {
    var state: UInt64
    mutating func next() -> Double {
        state ^= state >> 12; state ^= state << 25; state ^= state >> 27
        return Double((state &* 2685821657736338717) >> 11) / Double(1 << 53)
    }
}

func mix(_ colors: [RGB], _ t: Double) -> RGB {
    if colors.count == 1 { return colors[0] }
    let x = max(0, min(1, t)) * Double(colors.count - 1)
    let i = min(Int(x), colors.count - 2), f = x - Double(i)
    let a = colors[i], b = colors[i + 1]
    return (a.r + (b.r - a.r) * f, a.g + (b.g - a.g) * f, a.b + (b.b - a.b) * f)
}
struct Variant { let landscape: Layout; let portrait: Layout }

let variants: [String: Variant] = [
    "aurora": Variant(
        landscape: Layout(
            glows: [Glow(color: mauve, x: 0.22, y: 0.18, r: 0.38, a: 0.30)],
            waves: [Wave(color: lavender, y: 0.52, amp: 0.05, cycles: 0.9, phase: 0.10, a: 0.10),
                    Wave(color: mauve, y: 0.62, amp: 0.06, cycles: 1.1, phase: 0.55, a: 0.16),
                    Wave(color: blue, y: 0.74, amp: 0.05, cycles: 0.8, phase: 0.30, a: 0.20),
                    Wave(color: pink, y: 0.86, amp: 0.04, cycles: 1.3, phase: 0.80, a: 0.16)]),
        portrait: Layout(
            glows: [Glow(color: mauve, x: 0.25, y: 0.14, r: 0.40, a: 0.30)],
            waves: [Wave(color: lavender, y: 0.55, amp: 0.025, cycles: 0.7, phase: 0.10, a: 0.10),
                    Wave(color: mauve, y: 0.66, amp: 0.030, cycles: 0.9, phase: 0.55, a: 0.16),
                    Wave(color: blue, y: 0.77, amp: 0.025, cycles: 0.6, phase: 0.30, a: 0.20),
                    Wave(color: pink, y: 0.88, amp: 0.020, cycles: 1.0, phase: 0.80, a: 0.16)])),
    "deepsea": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.80, y: 0.20, r: 0.35, a: 0.22)],
            waves: [Wave(color: lavender, y: 0.55, amp: 0.04, cycles: 1.2, phase: 0.40, a: 0.08),
                    Wave(color: sapphire, y: 0.65, amp: 0.05, cycles: 0.9, phase: 0.05, a: 0.16),
                    Wave(color: teal, y: 0.76, amp: 0.05, cycles: 1.1, phase: 0.65, a: 0.18),
                    Wave(color: blue, y: 0.88, amp: 0.04, cycles: 0.7, phase: 0.25, a: 0.18)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.80, y: 0.15, r: 0.40, a: 0.22)],
            waves: [Wave(color: lavender, y: 0.58, amp: 0.020, cycles: 0.9, phase: 0.40, a: 0.08),
                    Wave(color: sapphire, y: 0.68, amp: 0.025, cycles: 0.7, phase: 0.05, a: 0.16),
                    Wave(color: teal, y: 0.79, amp: 0.025, cycles: 0.8, phase: 0.65, a: 0.18),
                    Wave(color: blue, y: 0.90, amp: 0.020, cycles: 0.6, phase: 0.25, a: 0.18)])),
    "night": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.85, y: 0.12, r: 0.28, a: 0.18)],
            waves: [Wave(color: blue, y: 0.60, amp: 0.08, cycles: 0.7, phase: 0.15, a: 0.14),
                    Wave(color: sapphire, y: 0.73, amp: 0.07, cycles: 0.9, phase: 0.60, a: 0.20),
                    Wave(color: teal, y: 0.86, amp: 0.05, cycles: 0.6, phase: 0.35, a: 0.24)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.80, y: 0.10, r: 0.32, a: 0.18)],
            waves: [Wave(color: blue, y: 0.63, amp: 0.035, cycles: 0.6, phase: 0.15, a: 0.14),
                    Wave(color: sapphire, y: 0.76, amp: 0.030, cycles: 0.7, phase: 0.60, a: 0.20),
                    Wave(color: teal, y: 0.88, amp: 0.025, cycles: 0.5, phase: 0.35, a: 0.24)])),
    "tide": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.18, r: 0.30, a: 0.14)],
            waves: [Wave(color: lavender, y: 0.52, amp: 0.025, cycles: 1.6, phase: 0.10, a: 0.06),
                    Wave(color: blue, y: 0.60, amp: 0.025, cycles: 1.8, phase: 0.45, a: 0.08),
                    Wave(color: sapphire, y: 0.68, amp: 0.025, cycles: 1.5, phase: 0.80, a: 0.10),
                    Wave(color: teal, y: 0.76, amp: 0.025, cycles: 1.9, phase: 0.25, a: 0.11),
                    Wave(color: sapphire, y: 0.84, amp: 0.020, cycles: 1.7, phase: 0.60, a: 0.12),
                    Wave(color: blue, y: 0.92, amp: 0.020, cycles: 1.5, phase: 0.95, a: 0.13)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.12, r: 0.34, a: 0.14)],
            waves: [Wave(color: lavender, y: 0.56, amp: 0.012, cycles: 1.2, phase: 0.10, a: 0.06),
                    Wave(color: blue, y: 0.63, amp: 0.012, cycles: 1.4, phase: 0.45, a: 0.08),
                    Wave(color: sapphire, y: 0.70, amp: 0.012, cycles: 1.1, phase: 0.80, a: 0.10),
                    Wave(color: teal, y: 0.77, amp: 0.012, cycles: 1.5, phase: 0.25, a: 0.11),
                    Wave(color: sapphire, y: 0.84, amp: 0.010, cycles: 1.3, phase: 0.60, a: 0.12),
                    Wave(color: blue, y: 0.91, amp: 0.010, cycles: 1.1, phase: 0.95, a: 0.13)])),
    "swell": Variant(
        landscape: Layout(
            glows: [Glow(color: teal, x: 0.12, y: 0.88, r: 0.40, a: 0.16)],
            waves: [Wave(color: sapphire, y: 0.70, amp: 0.10, cycles: 0.5, phase: 0.75, a: 0.16),
                    Wave(color: blue, y: 0.84, amp: 0.04, cycles: 1.0, phase: 0.30, a: 0.14),
                    Wave(color: teal, y: 0.93, amp: 0.03, cycles: 1.2, phase: 0.65, a: 0.14)]),
        portrait: Layout(
            glows: [Glow(color: teal, x: 0.10, y: 0.90, r: 0.45, a: 0.16)],
            waves: [Wave(color: sapphire, y: 0.72, amp: 0.045, cycles: 0.4, phase: 0.75, a: 0.16),
                    Wave(color: blue, y: 0.85, amp: 0.020, cycles: 0.8, phase: 0.30, a: 0.14),
                    Wave(color: teal, y: 0.93, amp: 0.015, cycles: 0.9, phase: 0.65, a: 0.14)])),
    "contours": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.78, y: 0.20, r: 0.30, a: 0.12)],
            lines: [Lines(count: 32, y0: 0.42, y1: 0.98, amp: 0.035, cycles: 1.4,
                          colors: [lavender, sapphire, teal], a0: 0.10, a1: 0.34, width: 0.0011)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.78, y: 0.12, r: 0.34, a: 0.12)],
            lines: [Lines(count: 30, y0: 0.50, y1: 0.98, amp: 0.016, cycles: 1.0,
                          colors: [lavender, sapphire, teal], a0: 0.10, a1: 0.34, width: 0.0016)])),
    "ripples": Variant(
        landscape: Layout(
            glows: [Glow(color: teal, x: 0.74, y: 0.78, r: 0.25, a: 0.14)],
            rings: [Rings(x: 0.74, y: 0.78, count: 22, spacing: 0.035,
                          colors: [teal, sapphire, blue, lavender], a0: 0.32, a1: 0.04, width: 0.0012)]),
        portrait: Layout(
            glows: [Glow(color: teal, x: 0.70, y: 0.82, r: 0.30, a: 0.14)],
            rings: [Rings(x: 0.70, y: 0.82, count: 22, spacing: 0.040,
                          colors: [teal, sapphire, blue, lavender], a0: 0.32, a1: 0.04, width: 0.0016)])),
    "ridges": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.30, y: 0.22, r: 0.32, a: 0.14)],
            ridges: [Ridge(color: lavender, y: 0.56, height: 0.10, peaks: 7, seed: 11, a: 0.08),
                     Ridge(color: blue, y: 0.65, height: 0.09, peaks: 9, seed: 23, a: 0.11),
                     Ridge(color: sapphire, y: 0.74, height: 0.08, peaks: 11, seed: 37, a: 0.14),
                     Ridge(color: teal, y: 0.83, height: 0.07, peaks: 13, seed: 41, a: 0.16),
                     Ridge(color: sapphire, y: 0.92, height: 0.05, peaks: 15, seed: 53, a: 0.18)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.30, y: 0.14, r: 0.36, a: 0.14)],
            ridges: [Ridge(color: lavender, y: 0.60, height: 0.05, peaks: 4, seed: 11, a: 0.08),
                     Ridge(color: blue, y: 0.68, height: 0.045, peaks: 5, seed: 23, a: 0.11),
                     Ridge(color: sapphire, y: 0.76, height: 0.04, peaks: 6, seed: 37, a: 0.14),
                     Ridge(color: teal, y: 0.84, height: 0.035, peaks: 7, seed: 41, a: 0.16),
                     Ridge(color: sapphire, y: 0.92, height: 0.025, peaks: 8, seed: 53, a: 0.18)])),
    "bokeh": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.70, y: 0.70, r: 0.45, a: 0.10)],
            bokeh: [Bokeh(count: 46, seed: 7, y0: 0.30, y1: 1.00, r0: 0.010, r1: 0.055,
                          colors: [sapphire, teal, blue, lavender], a: 0.16)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.65, y: 0.75, r: 0.50, a: 0.10)],
            bokeh: [Bokeh(count: 30, seed: 7, y0: 0.40, y1: 1.00, r0: 0.012, r1: 0.06,
                          colors: [sapphire, teal, blue, lavender], a: 0.16)])),
    "lowpoly": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.15, r: 0.30, a: 0.10)],
            lowpoly: [LowPoly(cell: 0.075, jitter: 0.42, seed: 5, y0: 0.30,
                              colors: [lavender, blue, sapphire, teal], a0: 0.02, a1: 0.30)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.10, r: 0.34, a: 0.10)],
            lowpoly: [LowPoly(cell: 0.065, jitter: 0.42, seed: 5, y0: 0.38,
                              colors: [lavender, blue, sapphire, teal], a0: 0.02, a1: 0.30)])),
    "hex": Variant(
        landscape: Layout(
            glows: [Glow(color: teal, x: 0.20, y: 0.85, r: 0.35, a: 0.10)],
            hexes: [Hexes(radius: 0.022, seed: 9, y0: 0.35, colors: [blue, sapphire, teal], line: 0.10, fill: 0.26)]),
        portrait: Layout(
            glows: [Glow(color: teal, x: 0.20, y: 0.88, r: 0.40, a: 0.10)],
            hexes: [Hexes(radius: 0.026, seed: 9, y0: 0.45, colors: [blue, sapphire, teal], line: 0.10, fill: 0.26)])),
    "shards": Variant(
        landscape: Layout(
            shards: [Shards(count: 16, seed: 3, y0: 0.30, size: 0.42, colors: [blue, sapphire, teal, lavender], a: 0.09)]),
        portrait: Layout(
            shards: [Shards(count: 12, seed: 3, y0: 0.40, size: 0.42, colors: [blue, sapphire, teal, lavender], a: 0.09)])),
    "halftone": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.70, y: 0.85, r: 0.40, a: 0.10)],
            halftone: [Halftone(spacing: 0.014, y0: 0.35, maxDot: 0.42, colors: [lavender, sapphire, teal], a: 0.30)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.65, y: 0.88, r: 0.45, a: 0.10)],
            halftone: [Halftone(spacing: 0.016, y0: 0.45, maxDot: 0.42, colors: [lavender, sapphire, teal], a: 0.30)])),
    "crystal": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.15, r: 0.30, a: 0.10)],
            crystal: [Facets(cell: 0.07, jitter: 0.9, seed: 13, y0: 0.30,
                             colors: [lavender, blue, sapphire, teal], a0: 0.02, a1: 0.30)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.10, r: 0.34, a: 0.10)],
            crystal: [Facets(cell: 0.06, jitter: 0.9, seed: 13, y0: 0.38,
                             colors: [lavender, blue, sapphire, teal], a0: 0.02, a1: 0.30)])),
    "lattice": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.15, r: 0.30, a: 0.10)],
            lattice: [Facets(cell: 0.06, jitter: 0, seed: 17, y0: 0.30,
                             colors: [lavender, blue, sapphire, teal], a0: 0.02, a1: 0.30)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.10, r: 0.34, a: 0.10)],
            lattice: [Facets(cell: 0.055, jitter: 0, seed: 17, y0: 0.38,
                             colors: [lavender, blue, sapphire, teal], a0: 0.02, a1: 0.30)])),
    "blocks": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.15, r: 0.30, a: 0.10)],
            blocks: [Facets(cell: 0.035, jitter: 0, seed: 19, y0: 0.35,
                            colors: [blue, sapphire, teal], a0: 0.0, a1: 0.30)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.75, y: 0.10, r: 0.34, a: 0.10)],
            blocks: [Facets(cell: 0.035, jitter: 0, seed: 19, y0: 0.45,
                            colors: [blue, sapphire, teal], a0: 0.0, a1: 0.30)])),
    "peaks": Variant(
        landscape: Layout(
            glows: [Glow(color: sapphire, x: 0.30, y: 0.20, r: 0.32, a: 0.12)],
            peaks: [Peaks(layers: 4, seed: 29, y0: 0.50, height: 0.16,
                          colors: [lavender, blue, sapphire, teal], a0: 0.08, a1: 0.28)]),
        portrait: Layout(
            glows: [Glow(color: sapphire, x: 0.30, y: 0.12, r: 0.36, a: 0.12)],
            peaks: [Peaks(layers: 4, seed: 29, y0: 0.58, height: 0.08,
                          colors: [lavender, blue, sapphire, teal], a0: 0.08, a1: 0.28)])),
    "ember": Variant(
        landscape: Layout(
            glows: [Glow(color: peach, x: 0.78, y: 0.22, r: 0.32, a: 0.20)],
            waves: [Wave(color: mauve, y: 0.55, amp: 0.05, cycles: 1.0, phase: 0.70, a: 0.10),
                    Wave(color: maroon, y: 0.66, amp: 0.06, cycles: 0.8, phase: 0.20, a: 0.15),
                    Wave(color: peach, y: 0.77, amp: 0.05, cycles: 1.2, phase: 0.50, a: 0.16),
                    Wave(color: pink, y: 0.89, amp: 0.04, cycles: 0.9, phase: 0.05, a: 0.13)]),
        portrait: Layout(
            glows: [Glow(color: peach, x: 0.75, y: 0.15, r: 0.38, a: 0.20)],
            waves: [Wave(color: mauve, y: 0.57, amp: 0.025, cycles: 0.8, phase: 0.70, a: 0.10),
                    Wave(color: maroon, y: 0.68, amp: 0.030, cycles: 0.6, phase: 0.20, a: 0.15),
                    Wave(color: peach, y: 0.79, amp: 0.025, cycles: 0.9, phase: 0.50, a: 0.16),
                    Wave(color: pink, y: 0.90, amp: 0.020, cycles: 0.7, phase: 0.05, a: 0.13)])),
]
let order = ["aurora", "deepsea", "night", "tide", "swell", "contours", "ripples", "ridges", "bokeh",
             "lowpoly", "hex", "shards", "halftone", "crystal", "lattice", "blocks", "peaks", "ember"]

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func cg(_ c: RGB, _ a: Double) -> CGColor { CGColor(red: c.r, green: c.g, blue: c.b, alpha: a) }

// Paint one variant into ctx's rect (origin bottom-left, as CoreGraphics has it)
func paint(_ v: Variant, in ctx: CGContext, rect: CGRect) {
    let w = Double(rect.width), h = Double(rect.height), long = max(w, h)
    ctx.saveGState()
    ctx.clip(to: rect)
    ctx.setFillColor(cg(base, 1))
    ctx.fill(rect)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let layout = w >= h ? v.landscape : v.portrait
    for g in layout.glows {
        // Three stops for a soft, gaussian-ish falloff instead of a hard disc
        let colors = [cg(g.color, g.a), cg(g.color, g.a * 0.45), cg(g.color, 0)] as CFArray
        let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.4, 1])!
        let center = CGPoint(x: rect.minX + g.x * w, y: rect.minY + (1 - g.y) * h)
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                               endCenter: center, endRadius: g.r * long, options: [])
    }
    // Waves: each band fades from its color at the crest to half of it lower down
    for wave in layout.waves {
        let path = CGMutablePath()
        let steps = 200
        for i in 0...steps {
            let fx = Double(i) / Double(steps)
            let fy = wave.y + wave.amp * sin(2 * Double.pi * (wave.cycles * fx + wave.phase))
            let p = CGPoint(x: rect.minX + fx * w, y: rect.minY + (1 - fy) * h)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let fill = CGGradient(colorsSpace: space, colors: [cg(wave.color, wave.a), cg(wave.color, wave.a * 0.5)] as CFArray,
                              locations: [0, 1])!
        let crest = rect.minY + (1 - (wave.y - wave.amp)) * h
        ctx.drawLinearGradient(fill, start: CGPoint(x: rect.midX, y: crest), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
        ctx.restoreGState()
    }
    func point(_ fx: Double, _ fy: Double) -> CGPoint { CGPoint(x: rect.minX + fx * w, y: rect.minY + (1 - fy) * h) }
    // Ridges: jagged peaks (seeded), back to front, filled down like the waves
    for ridge in layout.ridges {
        // Midpoint displacement: split every segment, nudge each midpoint by a
        // random amount that halves with each round — natural, not a zigzag.
        // `peaks` sets the roughness (more rounds = finer detail).
        var rng = Random(state: ridge.seed &* 0x9E3779B97F4A7C15 | 1)
        var heights = [rng.next(), rng.next()]
        var spread = 1.0
        for _ in 0..<(4 + ridge.peaks / 3) {
            var next: [Double] = []
            for i in 0..<(heights.count - 1) {
                next.append(heights[i])
                next.append((heights[i] + heights[i + 1]) / 2 + (rng.next() - 0.5) * spread)
            }
            next.append(heights.last!)
            heights = next
            spread *= 0.55
        }
        let lo = heights.min()!, hi = heights.max()!
        let path = CGMutablePath()
        for (i, v) in heights.enumerated() {
            let fx = Double(i) / Double(heights.count - 1)
            let up = ridge.height * (v - lo) / max(hi - lo, 1e-9)
            let p = point(fx, ridge.y - up + ridge.height * 0.5)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        ctx.saveGState()
        ctx.addPath(path); ctx.clip()
        let fill = CGGradient(colorsSpace: space, colors: [cg(ridge.color, ridge.a), cg(ridge.color, ridge.a * 0.5)] as CFArray,
                              locations: [0, 1])!
        ctx.drawLinearGradient(fill, start: point(0.5, ridge.y - ridge.height), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
        ctx.restoreGState()
    }
    // Lines: thin strokes; each line's phase and amplitude drift slightly
    for set in layout.lines {
        for i in 0..<set.count {
            let t = set.count > 1 ? Double(i) / Double(set.count - 1) : 0
            let y = set.y0 + (set.y1 - set.y0) * t
            let amp = set.amp * (0.7 + 0.3 * sin(Double(i) * 0.9))
            let path = CGMutablePath()
            for step in 0...240 {
                let fx = Double(step) / 240
                let p = point(fx, y + amp * sin(2 * Double.pi * (set.cycles * fx + Double(i) * 0.035)))
                if step == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            ctx.addPath(path)
            ctx.setStrokeColor(cg(mix(set.colors, t), set.a0 + (set.a1 - set.a0) * t))
            ctx.setLineWidth(max(1, set.width * long))
            ctx.strokePath()
        }
    }
    // Rings: concentric circles fading outward
    for set in layout.rings {
        for i in 0..<set.count {
            let t = set.count > 1 ? Double(i) / Double(set.count - 1) : 0
            let r = Double(i + 1) * set.spacing * long
            let c = point(set.x, set.y)
            ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
            ctx.setStrokeColor(cg(mix(set.colors, t), set.a0 + (set.a1 - set.a0) * t))
            ctx.setLineWidth(max(1, set.width * long))
            ctx.strokePath()
        }
    }
    // Bokeh: soft discs (a radial gradient each), scattered by a seeded PRNG
    for set in layout.bokeh {
        var rng = Random(state: set.seed &* 0x9E3779B97F4A7C15 | 1)
        for _ in 0..<set.count {
            let fx = rng.next(), fy = set.y0 + (set.y1 - set.y0) * rng.next()
            let r = (set.r0 + (set.r1 - set.r0) * pow(rng.next(), 2)) * long
            let color = set.colors[Int(rng.next() * Double(set.colors.count)) % set.colors.count]
            let a = set.a * (0.5 + 0.5 * rng.next())
            let disc = CGGradient(colorsSpace: space, colors: [cg(color, a), cg(color, a * 0.85), cg(color, 0)] as CFArray,
                                  locations: [0, 0.75, 1])!
            let c = point(fx, fy)
            ctx.drawRadialGradient(disc, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
        }
    }
    // Ramp from 0 at y0 to 1 at the bottom (smoothstep), for "richer toward the bottom"
    func ramp(_ fy: Double, _ y0: Double) -> Double {
        let t = max(0, min(1, (fy - y0) / (1 - y0))); return t * t * (3 - 2 * t)
    }
    // Low-poly: a jittered point grid split into triangles, each shaded by height
    for mesh in layout.lowpoly {
        var rng = Random(state: mesh.seed &* 0x9E3779B97F4A7C15 | 1)
        let step = mesh.cell * long
        let cols = Int(w / step) + 2, rows = Int(h / step) + 2
        var pts: [[CGPoint]] = []
        for r in 0...rows {
            var row: [CGPoint] = []
            for c in 0...cols {
                let edge = r == 0 || r == rows || c == 0 || c == cols
                let jx = edge ? 0 : (rng.next() - 0.5) * mesh.jitter * step
                let jy = edge ? 0 : (rng.next() - 0.5) * mesh.jitter * step
                row.append(CGPoint(x: rect.minX + Double(c) * step - step / 2 + jx,
                                   y: rect.minY + Double(r) * step - step / 2 + jy))
            }
            pts.append(row)
        }
        for r in 0..<rows {
            for c in 0..<cols {
                let a = pts[r][c], b = pts[r][c + 1], d = pts[r + 1][c], e = pts[r + 1][c + 1]
                for tri in ((r + c) % 2 == 0 ? [[a, b, e], [a, e, d]] : [[a, b, d], [b, e, d]]) {
                    let cy = Double(tri[0].y + tri[1].y + tri[2].y) / 3
                    let fy = 1 - (cy - Double(rect.minY)) / h
                    let t = ramp(fy, mesh.y0)
                    let alpha = mesh.a0 + (mesh.a1 - mesh.a0) * t * (0.6 + 0.4 * rng.next())
                    ctx.beginPath(); ctx.move(to: tri[0]); ctx.addLine(to: tri[1]); ctx.addLine(to: tri[2]); ctx.closePath()
                    ctx.setFillColor(cg(mix(mesh.colors, t * (0.8 + 0.2 * rng.next())), alpha))
                    ctx.fillPath()
                }
            }
        }
    }
    // Hexagons: faint outlines everywhere below y0, cells filled more often lower down
    for grid in layout.hexes {
        var rng = Random(state: grid.seed &* 0x9E3779B97F4A7C15 | 1)
        let r = grid.radius * long, dx = sqrt(3) * r, dy = 1.5 * r
        var row = 0
        var cy = Double(rect.maxY) + r
        while cy > Double(rect.minY) - r {
            var cx = Double(rect.minX) + (row % 2 == 0 ? 0 : dx / 2)
            while cx < Double(rect.maxX) + dx {
                let fy = 1 - (cy - Double(rect.minY)) / h
                let t = ramp(fy, grid.y0)
                if t > 0 {
                    let path = CGMutablePath()
                    for k in 0..<6 {
                        let ang = Double.pi / 180 * (60 * Double(k) - 30)
                        let p = CGPoint(x: cx + r * 0.92 * cos(ang), y: cy + r * 0.92 * sin(ang))
                        if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                    path.closeSubpath()
                    let color = mix(grid.colors, (cx - Double(rect.minX)) / w)
                    if rng.next() < t * 0.55 {
                        ctx.addPath(path); ctx.setFillColor(cg(color, grid.fill * t * (0.5 + 0.5 * rng.next()))); ctx.fillPath()
                    }
                    ctx.addPath(path); ctx.setStrokeColor(cg(color, grid.line * t)); ctx.setLineWidth(max(1, 0.0008 * long)); ctx.strokePath()
                }
                cx += dx
            }
            cy -= dy; row += 1
        }
    }
    // Shards: large translucent triangles, overlapping like stained glass
    for set in layout.shards {
        var rng = Random(state: set.seed &* 0x9E3779B97F4A7C15 | 1)
        for i in 0..<set.count {
            let cx = rng.next(), cy = set.y0 + (1 - set.y0) * (0.15 + 0.85 * rng.next())
            let size = set.size * (0.4 + 0.6 * rng.next())
            let rot = rng.next() * 2 * Double.pi
            ctx.beginPath()
            for k in 0..<3 {
                let ang = rot + Double(k) * 2 * Double.pi / 3 + (rng.next() - 0.5) * 0.8
                let rad = size * (0.6 + 0.4 * rng.next()) * long
                let p = point(cx, cy)
                let q = CGPoint(x: p.x + rad * cos(ang), y: p.y + rad * sin(ang))
                if k == 0 { ctx.move(to: q) } else { ctx.addLine(to: q) }
            }
            ctx.closePath()
            ctx.setFillColor(cg(set.colors[i % set.colors.count], set.a * (0.6 + 0.4 * ramp(cy, set.y0))))
            ctx.fillPath()
        }
    }
    // Halftone: a dot grid whose dots grow toward the bottom
    for ht in layout.halftone {
        let step = ht.spacing * long
        var cy = Double(rect.minY) + step / 2
        while cy < Double(rect.maxY) {
            let fy = 1 - (cy - Double(rect.minY)) / h
            let t = ramp(fy, ht.y0)
            if t > 0.02 {
                var cx = Double(rect.minX) + step / 2
                while cx < Double(rect.maxX) {
                    let rr = ht.maxDot * step * t
                    ctx.setFillColor(cg(mix(ht.colors, (cx - Double(rect.minX)) / w), ht.a * (0.4 + 0.6 * t)))
                    ctx.fillEllipse(in: CGRect(x: cx - rr, y: cy - rr, width: 2 * rr, height: 2 * rr))
                    cx += step
                }
            }
            cy += step
        }
    }
    func fill(_ poly: [CGPoint], _ color: RGB, _ alpha: Double) {
        guard poly.count >= 3 else { return }
        ctx.beginPath(); ctx.move(to: poly[0]); for p in poly.dropFirst() { ctx.addLine(to: p) }; ctx.closePath()
        ctx.setFillColor(cg(color, alpha)); ctx.fillPath()
    }
    func heightT(_ poly: [CGPoint], _ y0: Double) -> Double {
        let cy = poly.reduce(0) { $0 + Double($1.y) } / Double(poly.count)
        return ramp(1 - (cy - Double(rect.minY)) / h, y0)
    }
    // Crystal: Voronoi cells of a jittered grid — each cell is the rect clipped by
    // the bisector with every nearby site (Sutherland–Hodgman against half-planes)
    for f in layout.crystal {
        var rng = Random(state: f.seed &* 0x9E3779B97F4A7C15 | 1)
        let step = f.cell * long
        let cols = Int(w / step) + 3, rows = Int(h / step) + 3
        var sites: [[CGPoint]] = []
        for r in 0..<rows {
            sites.append((0..<cols).map { c in
                CGPoint(x: rect.minX + (Double(c) - 1 + 0.5 + (rng.next() - 0.5) * f.jitter) * step,
                        y: rect.minY + (Double(r) - 1 + 0.5 + (rng.next() - 0.5) * f.jitter) * step)
            })
        }
        for r in 0..<rows {
            for c in 0..<cols {
                let s0 = sites[r][c]
                var poly = [CGPoint(x: s0.x - 2 * step, y: s0.y - 2 * step), CGPoint(x: s0.x + 2 * step, y: s0.y - 2 * step),
                            CGPoint(x: s0.x + 2 * step, y: s0.y + 2 * step), CGPoint(x: s0.x - 2 * step, y: s0.y + 2 * step)]
                for rr in max(0, r - 2)...min(rows - 1, r + 2) {
                    for cc in max(0, c - 2)...min(cols - 1, c + 2) where !(rr == r && cc == c) {
                        let s1 = sites[rr][cc]
                        let mx = (s0.x + s1.x) / 2, my = (s0.y + s1.y) / 2, nx = s1.x - s0.x, ny = s1.y - s0.y
                        func inside(_ p: CGPoint) -> Bool { (p.x - mx) * nx + (p.y - my) * ny <= 0 }
                        var out: [CGPoint] = []
                        for i in 0..<poly.count {
                            let a = poly[i], b = poly[(i + 1) % poly.count]
                            let ia = inside(a), ib = inside(b)
                            if ia { out.append(a) }
                            if ia != ib {
                                let da = (a.x - mx) * nx + (a.y - my) * ny, db = (b.x - mx) * nx + (b.y - my) * ny
                                let t = da / (da - db)
                                out.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
                            }
                        }
                        poly = out
                    }
                }
                let t = heightT(poly, f.y0)
                fill(poly, mix(f.colors, t * (0.8 + 0.2 * rng.next())), f.a0 + (f.a1 - f.a0) * t * (0.6 + 0.4 * rng.next()))
            }
        }
    }
    // Lattice: equilateral triangles in rows, each shaded individually
    for f in layout.lattice {
        var rng = Random(state: f.seed &* 0x9E3779B97F4A7C15 | 1)
        let side = f.cell * long, rowH = side * sqrt(3) / 2
        var y = Double(rect.minY), row = 0
        while y < Double(rect.maxY) {
            var x = Double(rect.minX) - side - (row % 2 == 0 ? 0 : side / 2)
            while x < Double(rect.maxX) + side {
                let up = [CGPoint(x: x, y: y), CGPoint(x: x + side, y: y), CGPoint(x: x + side / 2, y: y + rowH)]
                let down = [CGPoint(x: x + side / 2, y: y + rowH), CGPoint(x: x + side, y: y), CGPoint(x: x + 1.5 * side, y: y + rowH)]
                for tri in [up, down] {
                    let t = heightT(tri, f.y0)
                    fill(tri, mix(f.colors, t * (0.8 + 0.2 * rng.next())), f.a0 + (f.a1 - f.a0) * t * (0.6 + 0.4 * rng.next()))
                }
                x += side
            }
            y += rowH; row += 1
        }
    }
    // Blocks: isometric cubes — each a light top and two shaded sides
    for f in layout.blocks {
        let s = f.cell * long, dx = s * sqrt(3) / 2
        var row = 0
        var cy = Double(rect.minY)
        while cy < Double(rect.maxY) + s {
            var cx = Double(rect.minX) + (row % 2 == 0 ? 0 : dx)
            while cx < Double(rect.maxX) + dx {
                let c = CGPoint(x: cx, y: cy)
                let top = [c, CGPoint(x: cx + dx, y: cy + s / 2), CGPoint(x: cx, y: cy + s), CGPoint(x: cx - dx, y: cy + s / 2)]
                let left = [c, CGPoint(x: cx - dx, y: cy + s / 2), CGPoint(x: cx - dx, y: cy - s / 2), CGPoint(x: cx, y: cy - s)]
                let right = [c, CGPoint(x: cx, y: cy - s), CGPoint(x: cx + dx, y: cy - s / 2), CGPoint(x: cx + dx, y: cy + s / 2)]
                let t = heightT(top + left + right, f.y0)
                let color = mix(f.colors, (cx - Double(rect.minX)) / w)
                let a = f.a0 + (f.a1 - f.a0) * t
                fill(top, color, a); fill(left, color, a * 0.6); fill(right, color, a * 0.35)
                cx += 2 * dx
            }
            cy += 1.5 * s; row += 1
        }
    }
    // Peaks: layered midpoint-displacement ridgelines, each band cut into triangles
    // between its crest and the next ridge down, lit from the left
    for f in layout.peaks {
        var rng = Random(state: f.seed &* 0x9E3779B97F4A7C15 | 1)
        func ridgeline(_ n: Int) -> [Double] {
            var hts = [rng.next(), rng.next()], spread = 1.0
            for _ in 0..<n {
                var next: [Double] = []
                for i in 0..<(hts.count - 1) { next.append(hts[i]); next.append((hts[i] + hts[i + 1]) / 2 + (rng.next() - 0.5) * spread) }
                next.append(hts.last!); hts = next; spread *= 0.55
            }
            let lo = hts.min()!, hi = hts.max()!
            return hts.map { ($0 - lo) / max(hi - lo, 1e-9) }
        }
        let bandH = (1 - f.y0) / Double(f.layers)
        for layer in 0..<f.layers {
            let crestY = f.y0 + Double(layer) * bandH
            let crest = ridgeline(4).enumerated().map { (i, v) in point(Double(i) / 16, crestY - v * f.height + f.height / 2) }
            let baseY = crestY + bandH + f.height * 0.4
            let base = (0...16).map { i in point(Double(i) / 16, baseY + (rng.next() - 0.5) * f.height * 0.3) }
            let t = Double(layer) / Double(max(1, f.layers - 1))
            let color = mix(f.colors, t)
            for i in 0..<16 {
                let quads = [[crest[i], crest[i + 1], base[i + 1]], [crest[i], base[i + 1], base[i]]]
                for (k, tri) in quads.enumerated() {
                    // Facets facing the light (rising to the right) are brighter
                    let slope = Double(crest[i + 1].y - crest[i].y)
                    let lit = k == 0 ? (slope > 0 ? 1.0 : 0.65) : 0.8
                    fill(tri, color, (f.a0 + (f.a1 - f.a0) * t) * lit * (0.85 + 0.15 * rng.next()))
                }
            }
        }
    }
    // Vignette: edges ease toward Mocha's crust
    let vignette = CGGradient(colorsSpace: space, colors: [cg(crust, 0), cg(crust, 0.55)] as CFArray,
                              locations: [0.45, 1])!
    let mid = CGPoint(x: rect.midX, y: rect.midY)
    ctx.drawRadialGradient(vignette, startCenter: mid, startRadius: 0, endCenter: mid,
                           endRadius: sqrt(w * w + h * h) / 2, options: [.drawsAfterEndLocation])
    ctx.restoreGState()
}

// Fine grain (±3 of 255) from a fixed-seed PRNG, so output is repeatable
func addGrain(_ ctx: CGContext) {
    guard let data = ctx.data?.assumingMemoryBound(to: UInt8.self) else { return }
    var state: UInt64 = 0x9E3779B97F4A7C15
    let count = ctx.height * ctx.bytesPerRow
    var i = 0
    while i < count {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        let n = Int(state % 7) - 3
        for c in 0..<3 { data[i + c] = UInt8(max(0, min(255, Int(data[i + c]) + n))) }
        i += 4
    }
}

func render(width: Int, height: Int, draw: (CGContext) -> Void) -> CGImage {
    guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fail("no bitmap context") }
    draw(ctx)
    addGrain(ctx)
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
        fail("cannot write \(path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fail("cannot write \(path)") }
}

let args = CommandLine.arguments
if args.count >= 3 && args[1] == "--sheet" {
    // One row per variant (all, or the ones named): a 16:9 desktop and a phone side by side
    let names = args.count > 3 ? Array(args[3...]) : order
    for name in names where variants[name] == nil { fail("no variant \(name)") }
    let dw = 1280, dh = 720, pw = 331, ph = 720, gap = 24
    let sheetW = gap + dw + gap + pw + gap, sheetH = gap + names.count * (dh + gap)
    let image = render(width: sheetW, height: sheetH) { ctx in
        ctx.setFillColor(cg(crust, 1))
        ctx.fill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))
        for (row, name) in names.enumerated() {
            let y = sheetH - gap - (row + 1) * (dh + gap) + gap
            paint(variants[name]!, in: ctx, rect: CGRect(x: gap, y: y, width: dw, height: dh))
            paint(variants[name]!, in: ctx, rect: CGRect(x: gap + dw + gap, y: y, width: pw, height: ph))
        }
    }
    writePNG(image, to: args[2])
} else if args.count == 5, let v = variants[args[1]], let w = Int(args[2]), let h = Int(args[3]) {
    writePNG(render(width: w, height: h) { paint(v, in: $0, rect: CGRect(x: 0, y: 0, width: w, height: h)) },
             to: args[4])
} else {
    fail("usage: generate <\(order.joined(separator: "|"))> <width> <height> <out.png> | --sheet <out.png>")
}
