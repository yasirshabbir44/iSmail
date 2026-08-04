//
//  TraceGlyphLibrary.swift
//  iSmail
//
//  Normalized guide paths for letters, numbers, and shapes (unit square 0…1).
//

import CoreGraphics
import Foundation

/// One continuous guide stroke made of control points in unit space.
struct TraceStroke: Hashable, Sendable {
    /// Control points in a 0…1 square (origin top-leading).
    var points: [CGPoint]

    init(points: [CGPoint]) {
        self.points = points
    }
}

/// Multi-stroke glyph definition used by `TraceWriteTaskView`.
struct TraceGlyph: Hashable, Sendable {
    var id: String
    var strokes: [TraceStroke]

    /// Densely sample every stroke for coverage / accuracy scoring.
    func sampledCheckpoints(samplesPerUnit: CGFloat = 28) -> [[CGPoint]] {
        strokes.map { stroke in
            Self.resample(stroke.points, samplesPerUnit: samplesPerUnit)
        }
    }

    private static func resample(_ points: [CGPoint], samplesPerUnit: CGFloat) -> [CGPoint] {
        guard points.count >= 2 else { return points }
        var result: [CGPoint] = [points[0]]
        for index in 1..<points.count {
            let a = points[index - 1]
            let b = points[index]
            let distance = hypot(b.x - a.x, b.y - a.y)
            let steps = max(1, Int((distance * samplesPerUnit).rounded(.up)))
            if steps <= 1 {
                result.append(b)
                continue
            }
            for step in 1...steps {
                let t = CGFloat(step) / CGFloat(steps)
                result.append(
                    CGPoint(
                        x: a.x + (b.x - a.x) * t,
                        y: a.y + (b.y - a.y) * t
                    )
                )
            }
        }
        return result
    }
}

/// Catalog of kid-friendly trace glyphs.
enum TraceGlyphLibrary: Sendable {

    static func glyph(for id: String) -> TraceGlyph? {
        catalog[id]
    }

    static func hasGlyph(_ id: String) -> Bool {
        catalog[id] != nil
    }

    // MARK: - Catalog

    private static let catalog: [String: TraceGlyph] = {
        var map: [String: TraceGlyph] = [:]
        for glyph in uppercase + lowercase + numbers + shapes {
            map[glyph.id] = glyph
        }
        return map
    }()

    // MARK: Uppercase

    private static let uppercase: [TraceGlyph] = [
        TraceGlyph(id: "A", strokes: [
            stroke(0.22, 0.86, 0.50, 0.14),
            stroke(0.50, 0.14, 0.78, 0.86),
            stroke(0.34, 0.56, 0.66, 0.56)
        ]),
        TraceGlyph(id: "B", strokes: [
            stroke(0.28, 0.14, 0.28, 0.86),
            TraceStroke(points: [
                p(0.28, 0.14), p(0.58, 0.14), p(0.70, 0.24), p(0.70, 0.40), p(0.58, 0.48), p(0.28, 0.48)
            ]),
            TraceStroke(points: [
                p(0.28, 0.48), p(0.62, 0.48), p(0.74, 0.58), p(0.74, 0.76), p(0.60, 0.86), p(0.28, 0.86)
            ])
        ]),
        TraceGlyph(id: "C", strokes: [
            TraceStroke(points: arc(cx: 0.54, cy: 0.50, rx: 0.30, ry: 0.36, start: 0.85, end: 5.55, steps: 20))
        ]),
        TraceGlyph(id: "H", strokes: [
            stroke(0.28, 0.14, 0.28, 0.86),
            stroke(0.72, 0.14, 0.72, 0.86),
            stroke(0.28, 0.50, 0.72, 0.50)
        ]),
        TraceGlyph(id: "I", strokes: [
            stroke(0.36, 0.14, 0.64, 0.14),
            stroke(0.50, 0.14, 0.50, 0.86),
            stroke(0.36, 0.86, 0.64, 0.86)
        ]),
        TraceGlyph(id: "L", strokes: [
            stroke(0.30, 0.14, 0.30, 0.86),
            stroke(0.30, 0.86, 0.74, 0.86)
        ]),
        TraceGlyph(id: "O", strokes: [
            TraceStroke(points: oval(cx: 0.50, cy: 0.50, rx: 0.28, ry: 0.36, steps: 28))
        ]),
        TraceGlyph(id: "T", strokes: [
            stroke(0.24, 0.16, 0.76, 0.16),
            stroke(0.50, 0.16, 0.50, 0.86)
        ]),
        TraceGlyph(id: "U", strokes: [
            TraceStroke(points: [
                p(0.26, 0.14), p(0.26, 0.62), p(0.34, 0.82), p(0.50, 0.88),
                p(0.66, 0.82), p(0.74, 0.62), p(0.74, 0.14)
            ])
        ])
    ]

    // MARK: Lowercase

    private static let lowercase: [TraceGlyph] = [
        TraceGlyph(id: "a", strokes: [
            TraceStroke(points: oval(cx: 0.48, cy: 0.58, rx: 0.22, ry: 0.24, steps: 22)),
            stroke(0.70, 0.36, 0.70, 0.86)
        ]),
        TraceGlyph(id: "c", strokes: [
            TraceStroke(points: arc(cx: 0.54, cy: 0.58, rx: 0.24, ry: 0.26, start: 0.9, end: 5.5, steps: 18))
        ]),
        TraceGlyph(id: "i", strokes: [
            stroke(0.50, 0.40, 0.50, 0.86),
            TraceStroke(points: [p(0.50, 0.22)])
        ]),
        TraceGlyph(id: "l", strokes: [
            stroke(0.50, 0.12, 0.50, 0.86)
        ]),
        TraceGlyph(id: "o", strokes: [
            TraceStroke(points: oval(cx: 0.50, cy: 0.58, rx: 0.24, ry: 0.26, steps: 24))
        ]),
        TraceGlyph(id: "u", strokes: [
            TraceStroke(points: [
                p(0.28, 0.36), p(0.28, 0.70), p(0.36, 0.84), p(0.50, 0.88),
                p(0.64, 0.84), p(0.72, 0.70), p(0.72, 0.36)
            ]),
            stroke(0.72, 0.36, 0.72, 0.86)
        ])
    ]

    // MARK: Numbers

    private static let numbers: [TraceGlyph] = [
        TraceGlyph(id: "0", strokes: [
            TraceStroke(points: oval(cx: 0.50, cy: 0.50, rx: 0.24, ry: 0.36, steps: 28))
        ]),
        TraceGlyph(id: "1", strokes: [
            stroke(0.40, 0.28, 0.52, 0.14),
            stroke(0.52, 0.14, 0.52, 0.86),
            stroke(0.36, 0.86, 0.68, 0.86)
        ]),
        TraceGlyph(id: "2", strokes: [
            TraceStroke(points: [
                p(0.28, 0.30), p(0.36, 0.16), p(0.54, 0.14), p(0.70, 0.24),
                p(0.70, 0.38), p(0.30, 0.72), p(0.30, 0.86), p(0.74, 0.86)
            ])
        ]),
        TraceGlyph(id: "3", strokes: [
            TraceStroke(points: [
                p(0.30, 0.22), p(0.48, 0.14), p(0.68, 0.20), p(0.70, 0.36),
                p(0.56, 0.48), p(0.42, 0.50)
            ]),
            TraceStroke(points: [
                p(0.42, 0.50), p(0.60, 0.52), p(0.72, 0.64), p(0.68, 0.80),
                p(0.48, 0.88), p(0.28, 0.80)
            ])
        ]),
        TraceGlyph(id: "4", strokes: [
            stroke(0.62, 0.14, 0.62, 0.86),
            stroke(0.62, 0.14, 0.28, 0.58),
            stroke(0.28, 0.58, 0.76, 0.58)
        ]),
        TraceGlyph(id: "5", strokes: [
            stroke(0.68, 0.14, 0.32, 0.14),
            stroke(0.32, 0.14, 0.30, 0.46),
            TraceStroke(points: [
                p(0.30, 0.46), p(0.52, 0.42), p(0.70, 0.52), p(0.70, 0.72),
                p(0.54, 0.88), p(0.30, 0.80)
            ])
        ]),
        TraceGlyph(id: "8", strokes: [
            TraceStroke(points: oval(cx: 0.50, cy: 0.32, rx: 0.20, ry: 0.18, steps: 18)),
            TraceStroke(points: oval(cx: 0.50, cy: 0.68, rx: 0.24, ry: 0.20, steps: 20))
        ])
    ]

    // MARK: Shapes

    private static let shapes: [TraceGlyph] = [
        TraceGlyph(id: "circle", strokes: [
            TraceStroke(points: oval(cx: 0.50, cy: 0.50, rx: 0.34, ry: 0.34, steps: 32))
        ]),
        TraceGlyph(id: "square", strokes: [
            TraceStroke(points: [
                p(0.22, 0.22), p(0.78, 0.22), p(0.78, 0.78), p(0.22, 0.78), p(0.22, 0.22)
            ])
        ]),
        TraceGlyph(id: "triangle", strokes: [
            TraceStroke(points: [
                p(0.50, 0.16), p(0.82, 0.84), p(0.18, 0.84), p(0.50, 0.16)
            ])
        ]),
        TraceGlyph(id: "star", strokes: [
            TraceStroke(points: starPoints(cx: 0.50, cy: 0.50, outer: 0.36, inner: 0.16))
        ])
    ]

    // MARK: Geometry helpers

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }

    private static func stroke(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) -> TraceStroke {
        TraceStroke(points: [p(x1, y1), p(x2, y2)])
    }

    private static func oval(
        cx: CGFloat,
        cy: CGFloat,
        rx: CGFloat,
        ry: CGFloat,
        steps: Int
    ) -> [CGPoint] {
        (0...steps).map { step in
            let angle = (-.pi / 2) + (2 * .pi * CGFloat(step) / CGFloat(steps))
            return CGPoint(x: cx + cos(angle) * rx, y: cy + sin(angle) * ry)
        }
    }

    private static func arc(
        cx: CGFloat,
        cy: CGFloat,
        rx: CGFloat,
        ry: CGFloat,
        start: CGFloat,
        end: CGFloat,
        steps: Int
    ) -> [CGPoint] {
        (0...steps).map { step in
            let t = CGFloat(step) / CGFloat(steps)
            let angle = start + (end - start) * t
            return CGPoint(x: cx + cos(angle) * rx, y: cy + sin(angle) * ry)
        }
    }

    private static func starPoints(
        cx: CGFloat,
        cy: CGFloat,
        outer: CGFloat,
        inner: CGFloat
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        for i in 0..<10 {
            let angle = (-.pi / 2) + (CGFloat(i) * .pi / 5)
            let radius = i.isMultiple(of: 2) ? outer : inner
            points.append(CGPoint(x: cx + cos(angle) * radius, y: cy + sin(angle) * radius))
        }
        points.append(points[0])
        return points
    }
}
