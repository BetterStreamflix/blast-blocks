import SpriteKit
import UIKit

enum TileArt {

    private static var cache = [String: SKTexture]()

    static func texture(for piece: Piece, size: CGFloat) -> SKTexture {
        let s = max(8, Int(size.rounded()))
        let key = "\(piece.kind)_\(piece.color?.rawValue ?? -1)_\(s)"
        if let t = cache[key] { return t }
        let img = render(piece: piece, side: CGFloat(s))
        let t = SKTexture(image: img)
        t.filteringMode = .linear
        cache[key] = t
        return t
    }

    static func candyTexture(color: TileColor, size: CGFloat) -> SKTexture {
        texture(for: Piece(kind: .candy, color: color), size: size)
    }

    static func cellTexture(size: CGFloat) -> SKTexture {
        let s = max(8, Int(size.rounded()))
        let key = "cell_\(s)"
        if let t = cache[key] { return t }
        let img = UIGraphicsImageRenderer(size: CGSize(width: s, height: s)).image { ctx in
            let rect = CGRect(x: 1, y: 1, width: CGFloat(s) - 2, height: CGFloat(s) - 2)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(s) * 0.2)
            UIColor.white.withAlphaComponent(0.07).setFill()
            path.fill()
        }
        let t = SKTexture(image: img)
        cache[key] = t
        return t
    }

    static func sparkTexture() -> SKTexture {
        if let t = cache["spark"] { return t }
        let s: CGFloat = 64
        let img = UIGraphicsImageRenderer(size: CGSize(width: s, height: s)).image { ctx in
            let colors = [UIColor.white.cgColor,
                          UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors, locations: [0, 1])!
            ctx.cgContext.drawRadialGradient(grad,
                                             startCenter: CGPoint(x: s / 2, y: s / 2), startRadius: 0,
                                             endCenter: CGPoint(x: s / 2, y: s / 2), endRadius: s / 2,
                                             options: [])
        }
        let t = SKTexture(image: img)
        cache["spark"] = t
        return t
    }

    static func starTexture(filled: Bool, size: CGFloat) -> SKTexture {
        let s = max(8, Int(size.rounded()))
        let key = "star_\(filled)_\(s)"
        if let t = cache[key] { return t }
        let img = UIGraphicsImageRenderer(size: CGSize(width: s, height: s)).image { ctx in
            let path = starPath(center: CGPoint(x: CGFloat(s) / 2, y: CGFloat(s) / 2),
                                outer: CGFloat(s) * 0.46, inner: CGFloat(s) * 0.2)
            if filled {
                UIColor(red: 1.0, green: 0.8, blue: 0.15, alpha: 1).setFill()
                path.fill()
            } else {
                UIColor.white.withAlphaComponent(0.35).setStroke()
                path.lineWidth = CGFloat(s) * 0.07
                path.stroke()
            }
        }
        let t = SKTexture(image: img)
        cache[key] = t
        return t
    }

    static func lockTexture(size: CGFloat) -> SKTexture {
        let s = max(8, Int(size.rounded()))
        let key = "lock_\(s)"
        if let t = cache[key] { return t }
        let img = UIGraphicsImageRenderer(size: CGSize(width: s, height: s)).image { ctx in
            let w = CGFloat(s)
            let body = CGRect(x: w * 0.24, y: w * 0.18, width: w * 0.52, height: w * 0.44)
            let bodyPath = UIBezierPath(roundedRect: body, cornerRadius: w * 0.08)
            UIColor.white.withAlphaComponent(0.9).setFill()
            bodyPath.fill()
            let shackle = UIBezierPath(arcCenter: CGPoint(x: w * 0.5, y: w * 0.52),
                                       radius: w * 0.17,
                                       startAngle: .pi, endAngle: 0, clockwise: true)
            UIColor.white.withAlphaComponent(0.9).setStroke()
            shackle.lineWidth = w * 0.09
            shackle.stroke()
        }
        let t = SKTexture(image: img)
        cache[key] = t
        return t
    }

    static func paletteForEffect(_ color: TileColor) -> UIColor {
        palette(color).base
    }

    // MARK: - Piece rendering

    private static func spriteName(for color: TileColor) -> String {
        switch color {
        case .red: return "tile_parrot"
        case .orange: return "tile_giraffe"
        case .yellow: return "tile_rabbit"
        case .green: return "tile_snake"
        case .blue: return "tile_hippo"
        case .purple: return "tile_pig"
        }
    }

    private static func render(piece: Piece, side s: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: s, height: s)).image { ctx in
            let cg = ctx.cgContext
            switch piece.kind {
            case .crate:
                drawCrate(cg, s)
            case .nova:
                drawNova(cg, s)
            default:
                drawAnimal(cg, s, piece)
                if piece.isSpecial {
                    drawBadge(cg, s, piece.kind)
                }
            }
        }
    }

    private static func drawAnimal(_ cg: CGContext, _ s: CGFloat, _ piece: Piece) {
        guard let img = UIImage(named: spriteName(for: piece.color ?? .blue)) else {
            drawCandyBase(cg, s, piece.color ?? .blue)
            drawGlyphOverlay(cg, s, piece)
            return
        }
        let iw = img.size.width, ih = img.size.height
        let scale = min(s * 0.98 / iw, s * 0.98 / ih)
        let w = iw * scale, h = ih * scale
        let rect = CGRect(x: (s - w) / 2, y: (s - h) / 2, width: w, height: h)

        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -s * 0.02), blur: s * 0.04,
                     color: UIColor.black.withAlphaComponent(0.35).cgColor)
        img.draw(in: rect)
        cg.restoreGState()
    }

    private static func drawBadge(_ cg: CGContext, _ s: CGFloat, _ kind: PieceKind) {
        let r = s * 0.21
        let c = CGPoint(x: s * 0.72, y: s * 0.28)
        let circle = UIBezierPath(ovalIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        UIColor(red: 0.08, green: 0.1, blue: 0.24, alpha: 0.92).setFill()
        circle.fill()
        UIColor.white.withAlphaComponent(0.9).setStroke()
        circle.lineWidth = s * 0.02
        circle.stroke()

        UIColor.white.setFill()
        switch kind {
        case .rocketH:
            arrow(center: CGPoint(x: c.x - r * 0.3, y: c.y), pointing: .pi, s: s * 0.55).fill()
            arrow(center: CGPoint(x: c.x + r * 0.3, y: c.y), pointing: 0, s: s * 0.55).fill()
        case .rocketV:
            arrow(center: CGPoint(x: c.x, y: c.y - r * 0.3), pointing: -.pi / 2, s: s * 0.55).fill()
            arrow(center: CGPoint(x: c.x, y: c.y + r * 0.3), pointing: .pi / 2, s: s * 0.55).fill()
        case .bomb:
            UIBezierPath(ovalIn: CGRect(x: c.x - r * 0.5, y: c.y - r * 0.3, width: r, height: r)).fill()
            let fuse = UIBezierPath()
            fuse.move(to: CGPoint(x: c.x + r * 0.28, y: c.y - r * 0.25))
            fuse.addQuadCurve(to: CGPoint(x: c.x + r * 0.6, y: c.y - r * 0.55),
                              controlPoint: CGPoint(x: c.x + r * 0.62, y: c.y - r * 0.3))
            UIColor.white.setStroke()
            fuse.lineWidth = s * 0.028
            fuse.stroke()
        default:
            break
        }
    }

    private static func palette(_ color: TileColor) -> (base: UIColor, light: UIColor) {
        switch color {
        case .red:    return (UIColor(red: 1.00, green: 0.34, blue: 0.43, alpha: 1), UIColor(red: 1.00, green: 0.55, blue: 0.62, alpha: 1))
        case .orange: return (UIColor(red: 1.00, green: 0.60, blue: 0.22, alpha: 1), UIColor(red: 1.00, green: 0.74, blue: 0.44, alpha: 1))
        case .yellow: return (UIColor(red: 0.98, green: 0.80, blue: 0.18, alpha: 1), UIColor(red: 1.00, green: 0.90, blue: 0.48, alpha: 1))
        case .green:  return (UIColor(red: 0.22, green: 0.78, blue: 0.48, alpha: 1), UIColor(red: 0.44, green: 0.90, blue: 0.64, alpha: 1))
        case .blue:   return (UIColor(red: 0.28, green: 0.62, blue: 1.00, alpha: 1), UIColor(red: 0.52, green: 0.76, blue: 1.00, alpha: 1))
        case .purple: return (UIColor(red: 0.68, green: 0.42, blue: 1.00, alpha: 1), UIColor(red: 0.81, green: 0.61, blue: 1.00, alpha: 1))
        }
    }

    private static func basePath(_ s: CGFloat) -> UIBezierPath {
        UIBezierPath(roundedRect: CGRect(x: s * 0.05, y: s * 0.05, width: s * 0.9, height: s * 0.9),
                     cornerRadius: s * 0.3)
    }

    private static func drawCandyBase(_ cg: CGContext, _ s: CGFloat, _ color: TileColor) {
        let (base, light) = palette(color)
        let path = basePath(s)

        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -s * 0.035), blur: s * 0.05,
                     color: UIColor.black.withAlphaComponent(0.4).cgColor)
        base.setFill()
        path.fill()
        cg.restoreGState()

        cg.saveGState()
        path.addClip()
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: [light.cgColor, base.darker(0.88).cgColor] as CFArray,
                              locations: [0, 1])!
        cg.drawLinearGradient(grad, start: CGPoint(x: s / 2, y: s), end: CGPoint(x: s / 2, y: 0), options: [])

        let spec = UIBezierPath(ovalIn: CGRect(x: s * 0.13, y: s * 0.60, width: s * 0.52, height: s * 0.26))
        UIColor.white.withAlphaComponent(0.38).setFill()
        spec.fill()
        let dot = UIBezierPath(ovalIn: CGRect(x: s * 0.62, y: s * 0.68, width: s * 0.12, height: s * 0.12))
        UIColor.white.withAlphaComponent(0.55).setFill()
        dot.fill()

        let shade = UIBezierPath(ovalIn: CGRect(x: s * 0.08, y: s * 0.86, width: s * 0.84, height: s * 0.3))
        UIColor.black.withAlphaComponent(0.12).setFill()
        shade.fill()
        cg.restoreGState()

        base.darker(0.7).setStroke()
        path.lineWidth = s * 0.028
        path.stroke()
    }

    private static func drawGlyphOverlay(_ cg: CGContext, _ s: CGFloat, _ piece: Piece) {
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -s * 0.02), blur: s * 0.03,
                     color: UIColor.black.withAlphaComponent(0.3).cgColor)
        UIColor.white.withAlphaComponent(0.95).setFill()

        let c = CGPoint(x: s / 2, y: s / 2)
        switch piece.kind {
        case .candy:
            glyphPath(for: piece.color ?? .blue, center: c, s: s).fill()
        case .rocketH:
            arrow(center: CGPoint(x: c.x - s * 0.16, y: c.y), pointing: .pi, s: s).fill()
            arrow(center: CGPoint(x: c.x + s * 0.16, y: c.y), pointing: 0, s: s).fill()
        case .rocketV:
            arrow(center: CGPoint(x: c.x, y: c.y + s * 0.16), pointing: .pi / 2, s: s).fill()
            arrow(center: CGPoint(x: c.x, y: c.y - s * 0.16), pointing: -.pi / 2, s: s).fill()
        case .bomb:
            UIBezierPath(ovalIn: CGRect(x: c.x - s * 0.2, y: c.y - s * 0.16, width: s * 0.4, height: s * 0.4)).fill()
            let fuse = UIBezierPath()
            fuse.move(to: CGPoint(x: c.x + s * 0.12, y: c.y + s * 0.2))
            fuse.addQuadCurve(to: CGPoint(x: c.x + s * 0.26, y: c.y + s * 0.34),
                              controlPoint: CGPoint(x: c.x + s * 0.3, y: c.y + s * 0.22))
            UIColor.white.withAlphaComponent(0.95).setStroke()
            fuse.lineWidth = s * 0.05
            fuse.stroke()
        default:
            break
        }
        cg.restoreGState()
    }

    private static func glyphPath(for color: TileColor, center c: CGPoint, s: CGFloat) -> UIBezierPath {
        let r = s * 0.25
        switch color {
        case .red:
            return UIBezierPath(ovalIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        case .orange:
            let p = UIBezierPath()
            p.move(to: CGPoint(x: c.x, y: c.y - r))
            p.addLine(to: CGPoint(x: c.x + r, y: c.y + r * 0.8))
            p.addLine(to: CGPoint(x: c.x - r, y: c.y + r * 0.8))
            p.close()
            return p
        case .yellow:
            return UIBezierPath(roundedRect: CGRect(x: c.x - r * 0.9, y: c.y - r * 0.9,
                                                    width: r * 1.8, height: r * 1.8),
                                cornerRadius: r * 0.25)
        case .green:
            return starPath(center: c, outer: r * 1.15, inner: r * 0.5)
        case .blue:
            let p = UIBezierPath()
            p.move(to: CGPoint(x: c.x, y: c.y - r * 1.1))
            p.addLine(to: CGPoint(x: c.x + r * 0.85, y: c.y))
            p.addLine(to: CGPoint(x: c.x, y: c.y + r * 1.1))
            p.addLine(to: CGPoint(x: c.x - r * 0.85, y: c.y))
            p.close()
            return p
        case .purple:
            return polygonPath(center: c, radius: r, sides: 6)
        }
    }

    private static func arrow(center: CGPoint, pointing angle: CGFloat, s: CGFloat) -> UIBezierPath {
        let r = s * 0.16
        let p = UIBezierPath()
        p.move(to: CGPoint(x: r, y: 0))
        p.addLine(to: CGPoint(x: -r * 0.6, y: -r * 0.85))
        p.addLine(to: CGPoint(x: -r * 0.6, y: r * 0.85))
        p.close()
        let t = CGAffineTransform(rotationAngle: angle)
        p.apply(t)
        p.apply(CGAffineTransform(translationX: center.x, y: center.y))
        return p
    }

    private static func drawNova(_ cg: CGContext, _ s: CGFloat) {
        let dark = UIBezierPath(roundedRect: CGRect(x: s * 0.04, y: s * 0.04, width: s * 0.92, height: s * 0.92),
                                cornerRadius: s * 0.22)
        UIColor(red: 0.13, green: 0.14, blue: 0.3, alpha: 1).setFill()
        dark.fill()

        let c = CGPoint(x: s / 2, y: s / 2)
        let colors = TileColor.allCases.map { palette($0).base }
        let r = s * 0.34
        cg.saveGState()
        dark.addClip()
        for (i, col) in colors.enumerated() {
            let a0 = CGFloat(i) * (.pi * 2 / CGFloat(colors.count)) - .pi / 2
            let a1 = CGFloat(i + 1) * (.pi * 2 / CGFloat(colors.count)) - .pi / 2
            let wedge = UIBezierPath()
            wedge.move(to: c)
            wedge.addArc(withCenter: c, radius: r, startAngle: a0, endAngle: a1, clockwise: true)
            wedge.close()
            col.setFill()
            wedge.fill()
        }
        cg.restoreGState()

        UIColor.white.withAlphaComponent(0.95).setFill()
        starPath(center: c, outer: s * 0.26, inner: s * 0.11).fill()
    }

    private static func drawCrate(_ cg: CGContext, _ s: CGFloat) {
        let box = basePath(s)
        UIColor(red: 0.55, green: 0.37, blue: 0.2, alpha: 1).setFill()
        box.fill()
        UIColor(red: 0.38, green: 0.24, blue: 0.12, alpha: 1).setStroke()
        box.lineWidth = s * 0.06
        box.stroke()

        UIColor(red: 0.38, green: 0.24, blue: 0.12, alpha: 1).setStroke()
        let cross1 = UIBezierPath()
        cross1.move(to: CGPoint(x: s * 0.14, y: s * 0.14))
        cross1.addLine(to: CGPoint(x: s * 0.86, y: s * 0.86))
        cross1.lineWidth = s * 0.07
        cross1.stroke()
        let cross2 = UIBezierPath()
        cross2.move(to: CGPoint(x: s * 0.86, y: s * 0.14))
        cross2.addLine(to: CGPoint(x: s * 0.14, y: s * 0.86))
        cross2.lineWidth = s * 0.07
        cross2.stroke()

        UIColor.black.withAlphaComponent(0.25).setFill()
        for (nx, ny) in [(0.18, 0.18), (0.82, 0.18), (0.18, 0.82), (0.82, 0.82)] {
            UIBezierPath(ovalIn: CGRect(x: s * nx - s * 0.035, y: s * ny - s * 0.035,
                                        width: s * 0.07, height: s * 0.07)).fill()
        }
    }

    // MARK: - Path helpers

    private static func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat) -> UIBezierPath {
        let p = UIBezierPath()
        for i in 0..<10 {
            let r = i % 2 == 0 ? outer : inner
            let a = CGFloat(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.close()
        return p
    }

    private static func polygonPath(center: CGPoint, radius: CGFloat, sides: Int) -> UIBezierPath {
        let p = UIBezierPath()
        for i in 0..<sides {
            let a = CGFloat(i) * .pi * 2 / CGFloat(sides) - .pi / 2
            let pt = CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.close()
        return p
    }
}
