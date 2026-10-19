import SpriteKit
import UIKit

final class GameScene: SKScene {

    private let level: Level
    private var board: Board!
    private var goals: [Goal]
    private var movesLeft: Int
    private var score = 0

    private var nodes = [Pos: TileNode]()
    private let boardLayer = SKNode()
    private let crop = SKCropNode()
    private let fxLayer = SKNode()
    private let hudLayer = SKNode()
    private var tileSize: CGFloat = 44
    private var boardOrigin = CGPoint.zero
    private var boardPixelSize = CGSize.zero

    private var movesLabel: SKLabelNode?
    private var scoreLabel: SKLabelNode?
    private var goalLabels = [SKLabelNode]()

    private var busy = true
    private var selected: Pos?
    private var touchStartPos: Pos?
    private var touchStartPoint = CGPoint.zero
    private var overlay: SKNode?

    init(level: Level) {
        self.level = level
        self.goals = level.goals
        self.movesLeft = level.moves
        super.init(size: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        board = Board(level: level)
        addChild(Theme.background(size: size))
        addChild(hudLayer)
        crop.zPosition = 2
        addChild(crop)
        fxLayer.zPosition = 50
        addChild(fxLayer)
        layout()
        buildHUD()
        buildBoardTray()
        spawnAllTiles()
    }

    private func layout() {
        let safeTop = view?.safeAreaInsets.top ?? 0
        let hudTop = size.height - safeTop - 34
        let goalY = hudTop - 52
        let boardTop = goalY - 46
        let boardBottom: CGFloat = 30
        let availW = size.width - 28
        let availH = boardTop - boardBottom
        tileSize = floor(min(availW / CGFloat(level.cols), availH / CGFloat(level.rows)))
        boardPixelSize = CGSize(width: tileSize * CGFloat(level.cols),
                                height: tileSize * CGFloat(level.rows))
        boardOrigin = CGPoint(x: (size.width - boardPixelSize.width) / 2,
                              y: boardBottom + (availH - boardPixelSize.height) / 2)
        boardLayer.position = boardOrigin

        let mask = SKSpriteNode(color: .white, size: boardPixelSize)
        mask.anchorPoint = .zero
        crop.maskNode = mask
        crop.position = boardOrigin
        crop.addChild(boardLayer)
        boardLayer.position = .zero

        goalChipY = goalY
    }

    private var goalChipY: CGFloat = 0

    private func buildHUD() {
        let safeTop = view?.safeAreaInsets.top ?? 0
        let y = size.height - safeTop - 34
        let goalY = goalChipY

        let cap1 = Theme.label("MOVES", size: 12, color: .white.withAlphaComponent(0.5), font: Theme.fontBold)
        cap1.position = CGPoint(x: 44, y: y + 12)
        hudLayer.addChild(cap1)
        let ml = Theme.label("\(movesLeft)", size: 34)
        ml.position = CGPoint(x: 44, y: y - 12)
        hudLayer.addChild(ml)
        movesLabel = ml

        let cap2 = Theme.label("SCORE", size: 12, color: .white.withAlphaComponent(0.5), font: Theme.fontBold)
        cap2.position = CGPoint(x: size.width - 52, y: y + 12)
        hudLayer.addChild(cap2)
        let sl = Theme.label("0", size: 30)
        sl.position = CGPoint(x: size.width - 52, y: y - 12)
        hudLayer.addChild(sl)
        scoreLabel = sl

        let chipW: CGFloat = 92
        let total = chipW * CGFloat(goals.count)
        var x = size.width / 2 - total / 2 + chipW / 2
        for goal in goals {
            let chip = SKNode()
            chip.position = CGPoint(x: x, y: goalY)
            x += chipW

            let bg = SKShapeNode(rectOf: CGSize(width: chipW - 10, height: 42), cornerRadius: 14)
            bg.fillColor = .white.withAlphaComponent(0.1)
            bg.strokeColor = .white.withAlphaComponent(0.16)
            bg.lineWidth = 1.5
            chip.addChild(bg)

            let iconPiece = Piece(kind: goal.color == nil ? .crate : .candy, color: goal.color)
            let icon = SKSpriteNode(texture: TileArt.texture(for: iconPiece, size: 30),
                                    size: CGSize(width: 30, height: 30))
            icon.position = CGPoint(x: -chipW / 2 + 22, y: 0)
            chip.addChild(icon)

            let count = Theme.label("\(goal.remaining)", size: 20)
            count.position = CGPoint(x: 14, y: 0)
            chip.addChild(count)
            goalLabels.append(count)

            hudLayer.addChild(chip)
        }
    }

    private func buildBoardTray() {
        let pad: CGFloat = 14
        let w = boardPixelSize.width + pad * 2
        let h = boardPixelSize.height + pad * 2
        let img = UIGraphicsImageRenderer(size: CGSize(width: max(1, w), height: max(1, h))).image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(x: 1.5, y: 1.5, width: w - 3, height: h - 3)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 24)
            cg.saveGState()
            cg.setShadow(offset: .zero, blur: 18,
                         color: UIColor.black.withAlphaComponent(0.5).cgColor)
            UIColor(red: 0.03, green: 0.05, blue: 0.13, alpha: 0.62).setFill()
            path.fill()
            cg.restoreGState()
            UIColor.white.withAlphaComponent(0.1).setStroke()
            path.lineWidth = 2
            path.stroke()
        }
        let tray = SKSpriteNode(texture: SKTexture(image: img), size: CGSize(width: w, height: h))
        tray.position = CGPoint(x: boardOrigin.x + boardPixelSize.width / 2,
                                y: boardOrigin.y + boardPixelSize.height / 2)
        tray.zPosition = 1
        addChild(tray)
    }

    private func spawnAllTiles() {
        var maxDelay: TimeInterval = 0
        for r in 0..<level.rows {
            for c in 0..<level.cols {
                let p = Pos(row: r, col: c)
                guard let piece = board.piece(at: p) else { continue }
                let node = TileNode(piece: piece, pos: p, tileSize: tileSize)
                let target = point(for: p)
                node.position = CGPoint(x: target.x, y: boardPixelSize.height + tileSize * 2)
                node.zPosition = 1
                boardLayer.addChild(node)
                nodes[p] = node
                let delay = 0.02 * Double(r) + 0.15
                maxDelay = max(maxDelay, delay + 0.4)
                node.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.move(to: target, duration: 0.4),
                ]))
            }
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: maxDelay),
            SKAction.run { [weak self] in self?.busy = false },
        ]))
    }

    // MARK: - Coordinates

    private func point(for p: Pos) -> CGPoint {
        CGPoint(x: CGFloat(p.col) * tileSize + tileSize / 2,
                y: CGFloat(p.row) * tileSize + tileSize / 2)
    }

    private func pos(at scenePoint: CGPoint) -> Pos? {
        let local = convert(scenePoint, to: boardLayer)
        let c = Int(floor(local.x / tileSize))
        let r = Int(floor(local.y / tileSize))
        let p = Pos(row: r, col: c)
        return board.inBounds(p) ? p : nil
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard overlay == nil, !busy, let t = touches.first else { return }
        let p = t.location(in: self)
        touchStartPoint = p
        touchStartPos = pos(at: p)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard overlay == nil, !busy,
              let start = touchStartPos, let t = touches.first else { return }
        let loc = t.location(in: self)
        let dx = loc.x - touchStartPoint.x
        let dy = loc.y - touchStartPoint.y
        guard max(abs(dx), abs(dy)) > tileSize * 0.55 else { return }
        let target: Pos
        if abs(dx) > abs(dy) {
            target = Pos(row: start.row, col: start.col + (dx > 0 ? 1 : -1))
        } else {
            target = Pos(row: start.row + (dy > 0 ? 1 : -1), col: start.col)
        }
        touchStartPos = nil
        deselect()
        trySwap(start, target)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let ov = overlay {
            handleOverlayTap(touches, overlay: ov)
            return
        }
        defer { touchStartPos = nil }
        guard !busy, let t = touches.first else { return }
        guard let p = pos(at: t.location(in: self)) else {
            deselect()
            return
        }
        guard let piece = board.piece(at: p), !piece.isCrate else {
            deselect()
            return
        }
        if let sel = selected {
            if sel == p {
                if piece.isSpecial {
                    deselect()
                    activateSingle(at: p)
                } else {
                    deselect()
                }
            } else if abs(sel.row - p.row) + abs(sel.col - p.col) == 1 {
                deselect()
                trySwap(sel, p)
            } else {
                deselect()
                select(p)
            }
        } else {
            select(p)
        }
    }

    private func select(_ p: Pos) {
        selected = p
        SFX.select()
        nodes[p]?.setSelected(true)
    }

    private func deselect() {
        if let sel = selected { nodes[sel]?.setSelected(false) }
        selected = nil
    }

    // MARK: - Swap & resolution

    private func trySwap(_ a: Pos, _ b: Pos) {
        guard board.canSwap(a, b) else {
            nodes[a]?.run(SKAction.sequence([
                SKAction.scale(to: 0.85, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.12),
            ]))
            return
        }
        busy = true
        Haptic.light()
        SFX.swap()
        let pa = board.piece(at: a)!
        let pb = board.piece(at: b)!
        board.swap(a, b)

        guard let na = nodes[a], let nb = nodes[b] else {
            board.swap(a, b)
            busy = false
            return
        }
        nodes[b] = na
        nodes[a] = nb
        na.pos = b
        nb.pos = a

        let dur = 0.16
        na.run(SKAction.move(to: point(for: b), duration: dur))
        nb.run(SKAction.move(to: point(for: a), duration: dur))

        run(SKAction.sequence([
            SKAction.wait(forDuration: dur),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                if pa.isSpecial || pb.isSpecial {
                    let plan = MatchEngine.activation(pieceA: pa, at: b, pieceB: pb, at: a, board: self.board)
                    self.movesLeft -= 1
                    self.apply(plan: plan, depth: 0)
                } else if !MatchEngine.clusters(on: self.board).isEmpty {
                    self.movesLeft -= 1
                    self.runCascade(preferred: b, depth: 0)
                } else {
                    self.swapBack(a, b)
                }
                self.updateHUD()
            },
        ]))
    }

    private func swapBack(_ a: Pos, _ b: Pos) {
        board.swap(a, b)
        guard let na = nodes[b], let nb = nodes[a] else {
            busy = false
            return
        }
        nodes[a] = na
        nodes[b] = nb
        na.pos = a
        nb.pos = b
        let dur = 0.16
        na.run(SKAction.move(to: point(for: a), duration: dur))
        nb.run(SKAction.move(to: point(for: b), duration: dur))
        run(SKAction.sequence([
            SKAction.wait(forDuration: dur),
            SKAction.run { [weak self] in self?.busy = false },
        ]))
    }

    private func activateSingle(at p: Pos) {
        busy = true
        movesLeft -= 1
        let plan = MatchEngine.singleActivation(at: p, board: board)
        updateHUD()
        apply(plan: plan, depth: 0)
    }

    // MARK: - Cascade

    private func runCascade(preferred: Pos?, depth: Int) {
        let clusters = MatchEngine.clusters(on: board)
        if clusters.isEmpty {
            stabilize()
            return
        }
        let plan = MatchEngine.resolve(matches: clusters, preferred: preferred, board: board)
        apply(plan: plan, depth: depth)
    }

    private func apply(plan: RemovalPlan, depth: Int) {
        var removedPieces = [Pos: Piece]()
        for p in plan.removed {
            if let piece = board.piece(at: p) {
                removedPieces[p] = piece
            }
        }
        var cratePieces = [Pos: Piece]()
        for p in plan.crateHits {
            if let piece = board.piece(at: p) {
                cratePieces[p] = piece
            }
        }

        score += removedPieces.count * 10 * (depth + 1) + plan.crateHits.count * 60 + plan.spawned.count * 150
        for (_, piece) in removedPieces {
            if let color = piece.color {
                for i in goals.indices where goals[i].color == color && goals[i].remaining > 0 {
                    goals[i].remaining -= 1
                }
            }
        }
        for i in goals.indices where goals[i].color == nil {
            goals[i].remaining -= plan.crateHits.count
        }
        updateHUD()

        let removeDur = 0.26
        var emitterBudget = 14
        var anySpecial = false
        for (p, piece) in removedPieces {
            if let node = nodes[p] {
                nodes.removeValue(forKey: p)
                node.zPosition = 6
                let squash = SKAction.group([
                    SKAction.scaleX(to: 1.22, duration: 0.07),
                    SKAction.scaleY(to: 0.8, duration: 0.07),
                ])
                node.run(SKAction.sequence([
                    squash,
                    SKAction.group([SKAction.scale(to: 0.05, duration: removeDur - 0.07),
                                    SKAction.fadeOut(withDuration: removeDur - 0.07)]),
                    SKAction.removeFromParent(),
                ]))
            }
            if piece.isSpecial {
                anySpecial = true
                fireEffect(kind: piece.kind, at: p)
                Haptic.medium()
            }
            if emitterBudget > 0 {
                emitterBudget -= 1
                burst(at: p, color: piece.color)
            }
            board.set(p, nil)
        }
        if anySpecial {
            SFX.blast()
        } else {
            SFX.pop(depth: depth)
        }

        for p in plan.crateHits {
            if let node = nodes[p] {
                nodes.removeValue(forKey: p)
                node.run(SKAction.sequence([
                    SKAction.group([SKAction.scale(to: 1.25, duration: 0.1),
                                    SKAction.fadeOut(withDuration: 0.18)]),
                    SKAction.removeFromParent(),
                ]))
            }
            board.set(p, nil)
        }

        for (p, kind) in plan.spawned {
            let oldColor = removedPieces[p]?.color ?? board.piece(at: p)?.color
            let newPiece = Piece(kind: kind, color: kind == .nova ? nil : oldColor)
            board.set(p, newPiece)
            if let node = nodes[p] {
                node.become(newPiece)
                node.setScale(0.2)
                node.run(SKAction.sequence([
                    SKAction.scale(to: 1.25, duration: 0.18),
                    SKAction.scale(to: 1.0, duration: 0.1),
                ]))
            }
        }

        if depth >= 1 {
            comboLabel(depth: depth)
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: removeDur + 0.06),
            SKAction.run { [weak self] in self?.applyGravityStep(depth: depth) },
        ]))
    }

    private func applyGravityStep(depth: Int) {
        let g = MatchEngine.applyGravity(board: board)
        var updates = [(TileNode, Pos)]()
        for m in g.moves {
            if let n = nodes[m.from] {
                updates.append((n, m.to))
            }
        }
        for m in g.moves { nodes.removeValue(forKey: m.from) }
        for (node, to) in updates {
            nodes[to] = node
            node.pos = to
            node.run(SKAction.move(to: point(for: to), duration: 0.18))
        }
        for s in g.spawns {
            let node = TileNode(piece: s.piece, pos: s.at, tileSize: tileSize)
            node.position = point(for: s.from)
            node.zPosition = 1
            boardLayer.addChild(node)
            nodes[s.at] = node
            node.run(SKAction.move(to: point(for: s.at), duration: 0.22))
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.24),
            SKAction.run { [weak self] in self?.runCascade(preferred: nil, depth: depth + 1) },
        ]))
    }

    // MARK: - Stabilize / end conditions

    private func stabilize() {
        if goals.allSatisfy({ $0.remaining <= 0 }) {
            score += movesLeft * 100
            let stars = score >= level.starScores.three ? 3 : (score >= level.starScores.two ? 2 : 1)
            SaveManager.record(level: level.id, stars: stars)
            updateHUD()
            Haptic.success()
            SFX.win()
            showEnd(win: true, stars: stars)
        } else if movesLeft <= 0 {
            Haptic.error()
            SFX.lose()
            showEnd(win: false, stars: 0)
        } else if !MatchEngine.hasPossibleMove(on: board) {
            reshuffle()
        } else {
            busy = false
        }
    }

    private func reshuffle() {
        let label = Theme.label("SHUFFLE!", size: 34, color: Theme.accent)
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 60
        label.alpha = 0
        fxLayer.addChild(label)
        label.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 0.7),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent(),
        ]))
        for (_, node) in nodes where !node.piece.isCrate {
            node.run(SKAction.fadeOut(withDuration: 0.25))
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                MatchEngine.reshuffle(board: self.board)
                for r in 0..<self.level.rows {
                    for c in 0..<self.level.cols {
                        let p = Pos(row: r, col: c)
                        if let piece = self.board.piece(at: p), !piece.isCrate {
                            if let node = self.nodes[p] {
                                node.become(piece)
                                node.run(SKAction.fadeIn(withDuration: 0.25))
                            } else {
                                let node = TileNode(piece: piece, pos: p, tileSize: self.tileSize)
                                node.position = self.point(for: p)
                                node.alpha = 0
                                self.boardLayer.addChild(node)
                                self.nodes[p] = node
                                node.run(SKAction.fadeIn(withDuration: 0.25))
                            }
                        }
                    }
                }
                self.busy = false
            },
        ]))
    }

    // MARK: - Effects

    private func burst(at p: Pos, color: TileColor?) {
        let e = SKEmitterNode()
        e.particleTexture = TileArt.sparkTexture()
        e.numParticlesToEmit = 10
        e.particleBirthRate = 600
        e.particleLifetime = 0.5
        e.particleLifetimeRange = 0.2
        e.particleSpeed = 140
        e.particleSpeedRange = 60
        e.emissionAngleRange = .pi * 2
        e.particleScale = 0.16
        e.particleScaleRange = 0.1
        e.particleScaleSpeed = -0.25
        e.particleAlpha = 0.9
        e.particleAlphaSpeed = -1.8
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .add
        if let color = color {
            e.particleColor = TileArt.paletteForEffect(color)
        }
        e.position = boardLayer.convert(point(for: p), to: self)
        e.zPosition = 40
        fxLayer.addChild(e)
        e.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.removeFromParent(),
        ]))
    }

    private func fireEffect(kind: PieceKind, at p: Pos) {
        let center = boardLayer.convert(point(for: p), to: self)
        switch kind {
        case .rocketH, .rocketV:
            let beam = SKSpriteNode(color: .white,
                                    size: kind == .rocketH
                                        ? CGSize(width: boardPixelSize.width, height: 10)
                                        : CGSize(width: 10, height: boardPixelSize.height))
            beam.position = center
            beam.alpha = 0.95
            beam.zPosition = 45
            fxLayer.addChild(beam)
            beam.run(SKAction.sequence([
                SKAction.group([SKAction.fadeOut(withDuration: 0.3),
                                SKAction.scaleX(to: kind == .rocketH ? 1 : 3, duration: 0.3),
                                SKAction.scaleY(to: kind == .rocketH ? 3 : 1, duration: 0.3)]),
                SKAction.removeFromParent(),
            ]))
        case .bomb:
            let ring = SKShapeNode(circleOfRadius: tileSize * 0.5)
            ring.strokeColor = .white
            ring.lineWidth = 6
            ring.position = center
            ring.zPosition = 45
            fxLayer.addChild(ring)
            ring.run(SKAction.sequence([
                SKAction.group([SKAction.scale(to: 4.5, duration: 0.35),
                                SKAction.fadeOut(withDuration: 0.35)]),
                SKAction.removeFromParent(),
            ]))
        case .nova:
            let flash = SKSpriteNode(color: .white, size: size)
            flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
            flash.alpha = 0
            flash.zPosition = 48
            fxLayer.addChild(flash)
            flash.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.85, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.removeFromParent(),
            ]))
        default:
            break
        }
    }

    private func comboLabel(depth: Int) {
        let texts = ["NICE!", "GREAT!", "SWEET!", "INSANE!"]
        let l = Theme.label(texts[min(depth - 1, texts.count - 1)], size: 30, color: Theme.accent)
        l.alpha = 0
        l.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        l.zPosition = 60
        fxLayer.addChild(l)
        l.run(SKAction.sequence([
            SKAction.group([SKAction.moveBy(x: 0, y: 44, duration: 0.7),
                            SKAction.sequence([SKAction.fadeIn(withDuration: 0.1),
                                               SKAction.wait(forDuration: 0.4),
                                               SKAction.fadeOut(withDuration: 0.2)])]),
            SKAction.removeFromParent(),
        ]))
    }

    // MARK: - HUD / overlays

    private func updateHUD() {
        movesLabel?.text = "\(max(0, movesLeft))"
        movesLabel?.fontColor = movesLeft <= 5 ? UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1) : .white
        scoreLabel?.text = "\(score)"
        for (i, goal) in goals.enumerated() where i < goalLabels.count {
            goalLabels[i].text = "\(max(0, goal.remaining))"
            goalLabels[i].alpha = goal.remaining <= 0 ? 0.35 : 1
        }
    }

    private func showEnd(win: Bool, stars: Int) {
        busy = true
        let ov = SKNode()
        ov.zPosition = 200

        let dim = SKSpriteNode(color: .black.withAlphaComponent(0.65), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        ov.addChild(dim)

        let panelSize = CGSize(width: min(size.width - 48, 340), height: win ? 360 : 300)
        let panel = Theme.panel(size: panelSize)
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        ov.addChild(panel)

        let title = Theme.label(win ? "LEVEL CLEAR!" : "OUT OF MOVES", size: 30,
                                color: win ? Theme.accent : .white)
        title.position = CGPoint(x: 0, y: panelSize.height / 2 - 52)
        panel.addChild(title)

        if win {
            let lvl = Theme.label("Level \(level.id)", size: 16,
                                  color: .white.withAlphaComponent(0.55), font: Theme.fontBold)
            lvl.position = CGPoint(x: 0, y: panelSize.height / 2 - 84)
            panel.addChild(lvl)
            for s in 0..<3 {
                let star = SKSpriteNode(texture: TileArt.starTexture(filled: s < stars, size: 54),
                                        size: CGSize(width: 54, height: 54))
                star.position = CGPoint(x: CGFloat(s - 1) * 62, y: 14)
                star.setScale(0)
                panel.addChild(star)
                star.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.35 + Double(s) * 0.25),
                    SKAction.scale(to: 1.0, duration: 0.28),
                ]))
            }
            let sc = Theme.label("Score \(score)", size: 18,
                                 color: .white.withAlphaComponent(0.75), font: Theme.fontBold)
            sc.position = CGPoint(x: 0, y: -52)
            panel.addChild(sc)

            let next = Theme.button(title: "NEXT", name: "ov_next", width: 200)
            next.position = CGPoint(x: 0, y: -104)
            panel.addChild(next)
            let map = Theme.button(title: "MAP", name: "ov_map", width: 200,
                                   color: UIColor.white.withAlphaComponent(0.16), textColor: .white)
            map.position = CGPoint(x: 0, y: -150)
            panel.addChild(map)
        } else {
            let hint = Theme.label("so close — try again", size: 16,
                                   color: .white.withAlphaComponent(0.55), font: Theme.fontBold)
            hint.position = CGPoint(x: 0, y: 10)
            panel.addChild(hint)
            let retry = Theme.button(title: "RETRY", name: "ov_retry", width: 200)
            retry.position = CGPoint(x: 0, y: -66)
            panel.addChild(retry)
            let map = Theme.button(title: "MAP", name: "ov_map", width: 200,
                                   color: UIColor.white.withAlphaComponent(0.16), textColor: .white)
            map.position = CGPoint(x: 0, y: -118)
            panel.addChild(map)
        }

        ov.alpha = 0
        addChild(ov)
        overlay = ov
        ov.run(SKAction.fadeIn(withDuration: 0.3))
    }

    private func handleOverlayTap(_ touches: Set<UITouch>, overlay: SKNode) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        for node in nodes(at: p) {
            var n: SKNode? = node
            while let cur = n {
                switch cur.name {
                case "ov_next":
                    let nextId = min(level.id + 1, LevelCatalog.count)
                    go(GameScene(level: LevelCatalog.make(nextId)))
                    return
                case "ov_retry":
                    go(GameScene(level: level))
                    return
                case "ov_map":
                    go(MapScene())
                    return
                default:
                    break
                }
                n = cur.parent
            }
        }
    }
}
