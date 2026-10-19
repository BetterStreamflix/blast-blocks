import SpriteKit

final class TileNode: SKSpriteNode {
    var pos: Pos
    var piece: Piece
    private let tileSize: CGFloat

    init(piece: Piece, pos: Pos, tileSize: CGFloat) {
        self.piece = piece
        self.pos = pos
        self.tileSize = tileSize
        super.init(texture: TileArt.texture(for: piece, size: tileSize),
                   color: .clear,
                   size: CGSize(width: tileSize, height: tileSize))
    }

    required init?(coder: NSCoder) { fatalError() }

    func become(_ piece: Piece) {
        self.piece = piece
        texture = TileArt.texture(for: piece, size: tileSize)
    }

    func refresh() {
        texture = TileArt.texture(for: piece, size: tileSize)
    }

    func setSelected(_ on: Bool) {
        removeAction(forKey: "sel")
        if on {
            let up = SKAction.scale(to: 1.14, duration: 0.1)
            up.timingMode = .easeOut
            run(up, withKey: "sel")
            zPosition = 10
        } else {
            run(SKAction.scale(to: 1.0, duration: 0.12), withKey: "sel")
            zPosition = 1
        }
    }
}
