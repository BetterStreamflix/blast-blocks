import SpriteKit
import UIKit

final class GameViewController: UIViewController {

    override func loadView() {
        view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        (view as? SKView)?.ignoresSiblingOrder = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let skView = view as? SKView, skView.scene == nil, view.bounds.width > 1 else { return }
        let scene = MenuScene()
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        SFX.warmup()
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
}
