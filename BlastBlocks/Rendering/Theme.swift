import SpriteKit
import UIKit

enum Theme {
    static let fontHeavy = "AvenirNext-Heavy"
    static let fontBold = "AvenirNext-Bold"

    static let bgTop = UIColor(red: 0.13, green: 0.17, blue: 0.38, alpha: 1)
    static let bgBottom = UIColor(red: 0.05, green: 0.07, blue: 0.17, alpha: 1)
    static let accent = UIColor(red: 1.0, green: 0.84, blue: 0.25, alpha: 1)
    static let accentDark = UIColor(red: 0.85, green: 0.55, blue: 0.08, alpha: 1)

    static func background(size: CGSize) -> SKSpriteNode {
        let w = max(1, size.width.rounded())
        let h = max(1, size.height.rounded())
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(bgBottom.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: w, height: h))
            let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [bgTop.cgColor,
                                           bgTop.withAlphaComponent(0).cgColor] as CFArray,
                                  locations: [0, 1])!
            let center = CGPoint(x: CGFloat(w) / 2, y: CGFloat(h) * 0.38)
            cg.drawRadialGradient(glow, startCenter: center, startRadius: 0,
                                  endCenter: center, endRadius: CGFloat(max(w, h)) * 0.9,
                                  options: [.drawsBeforeStartLocation])
        }
        let node = SKSpriteNode(texture: SKTexture(image: img), size: CGSize(width: w, height: h))
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = -100
        return node
    }

    static func label(_ text: String, size: CGFloat, color: UIColor = .white,
                      font: String = fontHeavy) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: font)
        l.text = text
        l.fontSize = size
        l.fontColor = color
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        return l
    }

    static func button(title: String, name: String, width: CGFloat,
                       color: UIColor = accent, textColor: UIColor = UIColor(red: 0.25, green: 0.15, blue: 0.02, alpha: 1)) -> SKNode {
        let h: CGFloat = 58
        let w = max(1, width.rounded())
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(x: 2, y: 2, width: CGFloat(w) - 4, height: h - 4)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: (h - 4) / 2)
            cg.saveGState()
            path.addClip()
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [color.cgColor, color.darker(0.78).cgColor] as CFArray,
                                  locations: [0, 1])!
            cg.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: h), options: [])
            let gloss = UIBezierPath(roundedRect: CGRect(x: 6, y: 4, width: CGFloat(w) - 12, height: h * 0.4),
                                     cornerRadius: h * 0.2)
            UIColor.white.withAlphaComponent(0.22).setFill()
            gloss.fill()
            cg.restoreGState()
            color.darker(0.55).setStroke()
            path.lineWidth = 3
            path.stroke()
        }
        let sprite = SKSpriteNode(texture: SKTexture(image: img), size: CGSize(width: w, height: h))
        sprite.name = name
        let l = label(title, size: 24, color: textColor)
        sprite.addChild(l)
        return sprite
    }

    static func panel(size: CGSize) -> SKSpriteNode {
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 26)
            UIColor(red: 0.1, green: 0.12, blue: 0.28, alpha: 0.95).setFill()
            path.fill()
            UIColor.white.withAlphaComponent(0.18).setStroke()
            path.lineWidth = 2
            path.stroke()
        }
        return SKSpriteNode(texture: SKTexture(image: img), size: size)
    }
}

enum Haptic {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

extension UIColor {
    func darker(_ factor: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r * factor, green: g * factor, blue: b * factor, alpha: a)
    }
}
