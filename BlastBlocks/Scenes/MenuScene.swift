import SpriteKit

final class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        addChild(Theme.background(size: size))
        layoutLogo()
        layoutUI()
    }

    private func layoutLogo() {
        let cy = size.height * 0.68
        let t = min(size.width * 0.2, 86)
        let pieces: [Piece] = [
            Piece(kind: .candy, color: .red),
            Piece(kind: .rocketH, color: .blue),
            Piece(kind: .nova, color: nil),
            Piece(kind: .candy, color: .green),
        ]
        for (i, piece) in pieces.enumerated() {
            let node = TileNode(piece: piece, pos: Pos(row: 0, col: i), tileSize: t)
            node.position = CGPoint(x: size.width / 2 + CGFloat(i - 1) * (t * 1.08) - t * 0.54,
                                    y: cy + (i % 2 == 0 ? 10 : -10))
            node.zPosition = 2
            addChild(node)
            let bob = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 8, duration: 0.9 + Double(i) * 0.12),
                SKAction.moveBy(x: 0, y: -8, duration: 0.9 + Double(i) * 0.12),
            ])
            node.run(SKAction.repeatForever(bob))
        }
    }

    private func layoutUI() {
        let cx = size.width / 2
        let title1 = Theme.label("BLAST", size: 64)
        title1.position = CGPoint(x: cx, y: size.height * 0.52)
        addChild(title1)
        let title2 = Theme.label("BLOCKS", size: 64, color: Theme.accent)
        title2.position = CGPoint(x: cx, y: size.height * 0.52 - 62)
        addChild(title2)

        let sub = Theme.label("a match-3 blast", size: 18, color: .white.withAlphaComponent(0.55), font: Theme.fontBold)
        sub.position = CGPoint(x: cx, y: size.height * 0.52 - 108)
        addChild(sub)

        let play = Theme.button(title: "PLAY", name: "btn_play", width: min(size.width * 0.62, 280))
        play.position = CGPoint(x: cx, y: size.height * 0.28)
        addChild(play)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8),
        ])
        play.run(SKAction.repeatForever(pulse))

        let foot = Theme.label("v1.0 • offline", size: 13, color: .white.withAlphaComponent(0.35), font: Theme.fontBold)
        foot.position = CGPoint(x: cx, y: max(40, size.height * 0.06))
        addChild(foot)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        for node in nodes(at: p) {
            var n: SKNode? = node
            while let cur = n {
                if cur.name == "btn_play" {
                    go(MapScene())
                    return
                }
                n = cur.parent
            }
        }
    }
}
