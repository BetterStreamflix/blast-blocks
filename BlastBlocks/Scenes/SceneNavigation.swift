import SpriteKit

extension SKScene {
    func go(_ next: SKScene) {
        next.size = size
        next.scaleMode = .resizeFill
        view?.presentScene(next, transition: SKTransition.fade(withDuration: 0.3))
    }
}
