import SpriteKit

final class MapScene: SKScene {

    private let content = SKNode()
    private var contentHeight: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var dragDistance: CGFloat = 0
    private var dragging = false

    private let rowSpacing: CGFloat = 104
    private let nodeRadius: CGFloat = 34

    override func didMove(to view: SKView) {
        addChild(Theme.background(size: size))
        buildHeader()
        buildLevelNodes()
        addChild(content)
        scrollToUnlocked()
    }

    private func buildHeader() {
        let back = Theme.button(title: "‹ BACK", name: "btn_back", width: 108,
                                color: UIColor.white.withAlphaComponent(0.16),
                                textColor: .white)
        back.position = CGPoint(x: 70, y: size.height - 70)
        addChild(back)

        let title = Theme.label("LEVELS", size: 30)
        title.position = CGPoint(x: size.width / 2, y: size.height - 70)
        addChild(title)
    }

    private func buttonX(for index: Int) -> CGFloat {
        let cx = size.width / 2
        let amp = min(size.width * 0.27, 110)
        let phase = CGFloat(index) * 0.85
        return cx + sin(phase) * amp
    }

    private func buildLevelNodes() {
        contentHeight = CGFloat(LevelCatalog.count) * rowSpacing + 200
        let unlocked = SaveManager.unlockedMax()

        let path = UIBezierPath()
        for i in 0..<LevelCatalog.count {
            let y = 120 + CGFloat(i) * rowSpacing
            let x = buttonX(for: i)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        let line = SKShapeNode(path: path.cgPath)
        line.strokeColor = .white.withAlphaComponent(0.14)
        line.lineWidth = 10
        line.lineCap = .round
        line.zPosition = 0
        content.addChild(line)

        for i in 0..<LevelCatalog.count {
            let levelId = i + 1
            let y = 120 + CGFloat(i) * rowSpacing
            let x = buttonX(for: i)
            let isOpen = levelId <= unlocked

            let node = levelButton(id: levelId, unlocked: isOpen)
            node.position = CGPoint(x: x, y: y)
            content.addChild(node)
        }
    }

    private func levelButton(id: Int, unlocked: Bool) -> SKNode {
        let r = nodeRadius
        let container = SKNode()
        container.name = unlocked ? "lv_\(id)" : "lv_locked"

        let circle = SKShapeNode(circleOfRadius: r)
        if unlocked {
            circle.fillColor = UIColor(red: 0.98, green: 0.62, blue: 0.2, alpha: 1)
            circle.strokeColor = UIColor(red: 0.75, green: 0.42, blue: 0.1, alpha: 1)
        } else {
            circle.fillColor = UIColor.white.withAlphaComponent(0.12)
            circle.strokeColor = UIColor.white.withAlphaComponent(0.2)
        }
        circle.lineWidth = 4
        container.addChild(circle)

        if unlocked {
            let num = Theme.label("\(id)", size: 26, color: UIColor(red: 0.3, green: 0.15, blue: 0.02, alpha: 1))
            num.position = CGPoint(x: 0, y: -1)
            container.addChild(num)

            let stars = SaveManager.stars(for: id)
            for s in 0..<3 {
                let star = SKSpriteNode(texture: TileArt.starTexture(filled: s < stars, size: 18),
                                        size: CGSize(width: 18, height: 18))
                star.position = CGPoint(x: CGFloat(s - 1) * 20, y: -r - 16)
                container.addChild(star)
            }
        } else {
            let lock = SKSpriteNode(texture: TileArt.lockTexture(size: 26),
                                    size: CGSize(width: 26, height: 26))
            lock.alpha = 0.7
            container.addChild(lock)
        }
        return container
    }

    private func scrollToUnlocked() {
        let unlocked = SaveManager.unlockedMax()
        let targetY = 120 + CGFloat(unlocked - 1) * rowSpacing
        content.position.y = -max(0, targetY - size.height * 0.45)
        clampContent()
    }

    private func clampContent() {
        let maxScroll = max(0, contentHeight - size.height + 140)
        content.position.y = min(0, max(-maxScroll, content.position.y))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        lastTouchY = t.location(in: self).y
        dragDistance = 0
        dragging = true
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard dragging, let t = touches.first else { return }
        let y = t.location(in: self).y
        let dy = y - lastTouchY
        lastTouchY = y
        dragDistance += abs(dy)
        content.position.y += dy
        clampContent()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { dragging = false }
        guard let t = touches.first, dragDistance < 14 else { return }
        let p = t.location(in: self)
        for node in nodes(at: p) {
            var n: SKNode? = node
            while let cur = n {
                if let name = cur.name {
                    if name == "btn_back" {
                        go(MenuScene())
                        return
                    }
                    if name.hasPrefix("lv_"), name != "lv_locked",
                       let id = Int(name.dropFirst(3)) {
                        go(GameScene(level: LevelCatalog.make(id)))
                        return
                    }
                }
                n = cur.parent
            }
        }
    }
}
