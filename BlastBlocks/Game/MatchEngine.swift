import Foundation

struct RemovalPlan {
    var removed = Set<Pos>()
    var crateHits = Set<Pos>()
    var spawned = [Pos: PieceKind]()
}

struct SpawnInfo {
    let at: Pos
    let from: Pos
    let piece: Piece
}

struct GravityResult {
    var moves = [(from: Pos, to: Pos)]()
    var spawns = [SpawnInfo]()
}

enum MatchEngine {

    struct Run {
        let color: TileColor
        let cells: [Pos]
        let horizontal: Bool
    }

    struct Cluster {
        var color: TileColor
        var cells = Set<Pos>()
        var runs = [Run]()
    }

    // MARK: - Run / cluster detection

    static func findRuns(on board: Board) -> [Run] {
        var runs = [Run]()
        for r in 0..<board.rows {
            var c = 0
            while c < board.cols {
                if let p = board.grid[r][c], p.isCandy, let color = p.color {
                    var end = c + 1
                    while end < board.cols,
                          let q = board.grid[r][end], q.isCandy, q.color == color {
                        end += 1
                    }
                    if end - c >= 3 {
                        runs.append(Run(color: color,
                                        cells: (c..<end).map { Pos(row: r, col: $0) },
                                        horizontal: true))
                    }
                    c = end
                } else {
                    c += 1
                }
            }
        }
        for c in 0..<board.cols {
            var r = 0
            while r < board.rows {
                if let p = board.grid[r][c], p.isCandy, let color = p.color {
                    var end = r + 1
                    while end < board.rows,
                          let q = board.grid[end][c], q.isCandy, q.color == color {
                        end += 1
                    }
                    if end - r >= 3 {
                        runs.append(Run(color: color,
                                        cells: (r..<end).map { Pos(row: $0, col: c) },
                                        horizontal: false))
                    }
                    r = end
                } else {
                    r += 1
                }
            }
        }
        return runs
    }

    static func clusters(on board: Board) -> [Cluster] {
        let runs = findRuns(on: board)
        var parent = Array(0..<max(runs.count, 1))

        func root(_ i: Int) -> Int {
            var i = i
            while parent[i] != i {
                parent[i] = parent[parent[i]]
                i = parent[i]
            }
            return i
        }

        var owner = [Pos: Int]()
        for (i, run) in runs.enumerated() {
            for cell in run.cells {
                if let j = owner[cell] {
                    let ri = root(i), rj = root(j)
                    if ri != rj { parent[ri] = rj }
                } else {
                    owner[cell] = i
                }
            }
        }

        var map = [Int: Cluster]()
        for (i, run) in runs.enumerated() {
            let k = root(i)
            var cl = map[k] ?? Cluster(color: run.color)
            cl.cells.formUnion(run.cells)
            cl.runs.append(run)
            map[k] = cl
        }
        return Array(map.values)
    }

    static func spawn(for cluster: Cluster, preferred: Pos?) -> (pos: Pos, kind: PieceKind)? {
        let hasH = cluster.runs.contains { $0.horizontal }
        let hasV = cluster.runs.contains { !$0.horizontal }
        let longest = cluster.runs.max { $0.cells.count < $1.cells.count }

        let kind: PieceKind
        if hasH && hasV {
            kind = .bomb
        } else if let l = longest, l.cells.count >= 5 {
            kind = .nova
        } else if let l = longest, l.cells.count == 4 {
            kind = l.horizontal ? .rocketH : .rocketV
        } else {
            return nil
        }

        let pos: Pos
        if let p = preferred, cluster.cells.contains(p) {
            pos = p
        } else if hasH && hasV,
                  let h = cluster.runs.first(where: { $0.horizontal }),
                  let v = cluster.runs.first(where: { !$0.horizontal }),
                  let x = h.cells.first(where: { v.cells.contains($0) }) {
            pos = x
        } else if let l = longest {
            pos = l.cells[l.cells.count / 2]
        } else {
            pos = cluster.cells.first!
        }
        return (pos, kind)
    }

    // MARK: - Removal planning

    static func resolve(matches: [Cluster], preferred: Pos?, board: Board) -> RemovalPlan {
        var plan = RemovalPlan()
        var matchCells = Set<Pos>()
        for cl in matches {
            matchCells.formUnion(cl.cells)
            if let s = spawn(for: cl, preferred: preferred) {
                plan.spawned[s.pos] = s.kind
            }
        }
        matchCells.subtract(plan.spawned.keys)
        plan.removed = matchCells

        for p in matchCells {
            for n in board.neighbors(of: p) where board.piece(at: n)?.isCrate == true {
                plan.crateHits.insert(n)
            }
        }
        chainBlasts(&plan, board: board)
        plan.removed.subtract(plan.spawned.keys)
        return plan
    }

    static func activation(pieceA pa: Piece, at a: Pos, pieceB pb: Piece, at b: Pos, board: Board) -> RemovalPlan {
        var plan = RemovalPlan()

        if pa.isSpecial || pb.isSpecial {
            if pa.kind == .nova && pb.kind == .nova {
                for r in 0..<board.rows {
                    for c in 0..<board.cols {
                        let p = Pos(row: r, col: c)
                        if board.grid[r][c]?.isCrate == true {
                            plan.crateHits.insert(p)
                        } else if board.grid[r][c] != nil {
                            plan.removed.insert(p)
                        }
                    }
                }
            } else if pa.kind == .nova || pb.kind == .nova {
                let other = pa.kind == .nova ? pb : pa
                let target = other.color ?? dominantColor(on: board)
                for r in 0..<board.rows {
                    for c in 0..<board.cols {
                        if board.grid[r][c]?.color == target {
                            plan.removed.insert(Pos(row: r, col: c))
                        }
                    }
                }
                plan.removed.insert(a)
                plan.removed.insert(b)
                if other.isSpecial && other.kind != .nova {
                    let otherPos = pa.kind == .nova ? b : a
                    plan.removed.formUnion(blast(from: otherPos, on: board))
                }
            } else if (pa.kind == .rocketH || pa.kind == .rocketV),
                      (pb.kind == .rocketH || pb.kind == .rocketV) {
                for c in 0..<board.cols { plan.removed.insert(Pos(row: b.row, col: c)) }
                for r in 0..<board.rows { plan.removed.insert(Pos(row: r, col: b.col)) }
                plan.removed.insert(a)
                plan.removed.insert(b)
            } else if pa.kind == .bomb && pb.kind == .bomb {
                for dr in -2...2 {
                    for dc in -2...2 {
                        let p = Pos(row: b.row + dr, col: b.col + dc)
                        if board.inBounds(p) { plan.removed.insert(p) }
                    }
                }
                plan.removed.insert(a)
                plan.removed.insert(b)
            } else if (pa.kind == .bomb || pb.kind == .bomb),
                      (pa.kind == .rocketH || pa.kind == .rocketV || pb.kind == .rocketH || pb.kind == .rocketV) {
                for dr in -1...1 {
                    for c in 0..<board.cols {
                        let p = Pos(row: b.row + dr, col: c)
                        if board.inBounds(p) { plan.removed.insert(p) }
                    }
                }
                for dc in -1...1 {
                    for r in 0..<board.rows {
                        let p = Pos(row: r, col: b.col + dc)
                        if board.inBounds(p) { plan.removed.insert(p) }
                    }
                }
                plan.removed.insert(a)
                plan.removed.insert(b)
            } else {
                let specialPos = pa.isSpecial ? a : b
                plan.removed.formUnion(blast(from: specialPos, on: board))
                plan.removed.insert(specialPos)
            }
        }

        for p in Array(plan.removed) {
            if board.piece(at: p)?.isCrate == true {
                plan.removed.remove(p)
                plan.crateHits.insert(p)
            }
        }
        chainBlasts(&plan, board: board)
        return plan
    }

    static func singleActivation(at p: Pos, board: Board) -> RemovalPlan {
        var plan = RemovalPlan()
        plan.removed.formUnion(blast(from: p, on: board))
        plan.removed.insert(p)
        for pos in Array(plan.removed) {
            if board.piece(at: pos)?.isCrate == true {
                plan.removed.remove(pos)
                plan.crateHits.insert(pos)
            }
        }
        chainBlasts(&plan, board: board)
        return plan
    }

    static func blast(from p: Pos, on board: Board) -> Set<Pos> {
        guard let piece = board.piece(at: p) else { return [] }
        var cells = Set<Pos>()
        switch piece.kind {
        case .rocketH:
            for c in 0..<board.cols { cells.insert(Pos(row: p.row, col: c)) }
        case .rocketV:
            for r in 0..<board.rows { cells.insert(Pos(row: r, col: p.col)) }
        case .bomb:
            for dr in -1...1 {
                for dc in -1...1 {
                    let q = Pos(row: p.row + dr, col: p.col + dc)
                    if board.inBounds(q) { cells.insert(q) }
                }
            }
        case .nova:
            let target = dominantColor(on: board)
            for r in 0..<board.rows {
                for c in 0..<board.cols {
                    if board.grid[r][c]?.color == target {
                        cells.insert(Pos(row: r, col: c))
                    }
                }
            }
        default:
            break
        }
        return cells
    }

    static func dominantColor(on board: Board) -> TileColor {
        var counts = [TileColor: Int]()
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                if let color = board.grid[r][c]?.color {
                    counts[color, default: 0] += 1
                }
            }
        }
        return counts.max { $0.value < $1.value }?.key ?? board.level.palette[0]
    }

    private static func chainBlasts(_ plan: inout RemovalPlan, board: Board) {
        var queue = [Pos](plan.removed.filter { board.piece(at: $0)?.isSpecial == true })
        var seen = Set<Pos>()
        while let p = queue.popLast() {
            if seen.contains(p) { continue }
            seen.insert(p)
            for q in blast(from: p, on: board) {
                guard let piece = board.piece(at: q) else { continue }
                if piece.isCrate {
                    plan.crateHits.insert(q)
                } else {
                    plan.removed.insert(q)
                    if piece.isSpecial && !seen.contains(q) {
                        queue.append(q)
                    }
                }
            }
        }
    }

    // MARK: - Gravity & refill

    static func applyGravity(board: Board) -> GravityResult {
        var result = GravityResult()
        for c in 0..<board.cols {
            var r = 0
            while r < board.rows {
                if board.grid[r][c]?.isCrate == true {
                    r += 1
                    continue
                }
                let segStart = r
                var src = [(pos: Pos, piece: Piece)]()
                while r < board.rows && board.grid[r][c]?.isCrate != true {
                    if let piece = board.grid[r][c] {
                        src.append((Pos(row: r, col: c), piece))
                    }
                    board.grid[r][c] = nil
                    r += 1
                }
                let segEnd = r
                var dst = segStart
                for (pos, piece) in src {
                    board.grid[dst][c] = piece
                    if dst != pos.row {
                        result.moves.append((from: pos, to: Pos(row: dst, col: c)))
                    }
                    dst += 1
                }
                while dst < segEnd {
                    let piece = Piece(kind: .candy, color: board.level.palette.randomElement()!)
                    let at = Pos(row: dst, col: c)
                    board.grid[dst][c] = piece
                    result.spawns.append(SpawnInfo(at: at,
                                                   from: Pos(row: segEnd, col: c),
                                                   piece: piece))
                    dst += 1
                }
            }
        }
        return result
    }

    // MARK: - Move availability / reshuffle

    static func hasPossibleMove(on board: Board) -> Bool {
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                let p = Pos(row: r, col: c)
                if board.piece(at: p)?.isSpecial == true { return true }
            }
        }
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                let p = Pos(row: r, col: c)
                for n in [Pos(row: r, col: c + 1), Pos(row: r + 1, col: c)] {
                    guard board.canSwap(p, n) else { continue }
                    board.swap(p, n)
                    let found = !findRuns(on: board).isEmpty
                    board.swap(p, n)
                    if found { return true }
                }
            }
        }
        return false
    }

    static func reshuffle(board: Board) {
        var cells = [Pos]()
        var pieces = [Piece]()
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                if let piece = board.grid[r][c], !piece.isCrate {
                    cells.append(Pos(row: r, col: c))
                    pieces.append(piece)
                }
            }
        }
        for _ in 0..<60 {
            pieces.shuffle()
            for (i, cell) in cells.enumerated() {
                board.grid[cell.row][cell.col] = pieces[i]
            }
            if findRuns(on: board).isEmpty && hasPossibleMove(on: board) {
                return
            }
        }
    }
}
