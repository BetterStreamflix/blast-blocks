import Foundation

final class Board {
    let level: Level
    var grid: [[Piece?]]

    var rows: Int { level.rows }
    var cols: Int { level.cols }

    init(level: Level) {
        self.level = level
        grid = Array(repeating: Array(repeating: nil, count: level.cols), count: level.rows)
        for p in level.crates {
            grid[p.row][p.col] = Piece(kind: .crate, color: nil)
        }
        fillInitial()
    }

    func piece(at p: Pos) -> Piece? { grid[p.row][p.col] }
    func set(_ p: Pos, _ piece: Piece?) { grid[p.row][p.col] = piece }

    func inBounds(_ p: Pos) -> Bool {
        p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols
    }

    func canSwap(_ a: Pos, _ b: Pos) -> Bool {
        guard inBounds(a), inBounds(b) else { return false }
        guard abs(a.row - b.row) + abs(a.col - b.col) == 1 else { return false }
        guard let pa = piece(at: a), let pb = piece(at: b) else { return false }
        return !pa.isCrate && !pb.isCrate
    }

    func swap(_ a: Pos, _ b: Pos) {
        let tmp = grid[a.row][a.col]
        grid[a.row][a.col] = grid[b.row][b.col]
        grid[b.row][b.col] = tmp
    }

    func neighbors(of p: Pos) -> [Pos] {
        [Pos(row: p.row + 1, col: p.col), Pos(row: p.row - 1, col: p.col),
         Pos(row: p.row, col: p.col + 1), Pos(row: p.row, col: p.col - 1)].filter { inBounds($0) }
    }

    private func fillInitial() {
        for r in 0..<rows {
            for c in 0..<cols where grid[r][c] == nil {
                grid[r][c] = Piece(kind: .candy, color: pickColor(row: r, col: c))
            }
        }
    }

    private func pickColor(row r: Int, col c: Int) -> TileColor {
        var banned = Set<TileColor>()
        if c >= 2,
           let a = grid[r][c - 1], a.isCandy, let ac = a.color,
           let b = grid[r][c - 2], b.isCandy, b.color == ac {
            banned.insert(ac)
        }
        if r >= 2,
           let a = grid[r - 1][c], a.isCandy, let ac = a.color,
           let b = grid[r - 2][c], b.isCandy, b.color == ac {
            banned.insert(ac)
        }
        let options = level.palette.filter { !banned.contains($0) }
        return options.randomElement() ?? level.palette[0]
    }
}
