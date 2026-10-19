import UIKit

struct Pos: Hashable {
    let row: Int
    let col: Int
}

enum TileColor: Int, CaseIterable, Hashable {
    case red = 0, orange, yellow, green, blue, purple
}

enum PieceKind {
    case candy
    case rocketH
    case rocketV
    case bomb
    case nova
    case crate
}

struct Piece {
    var kind: PieceKind
    var color: TileColor?

    var isSpecial: Bool {
        kind == .rocketH || kind == .rocketV || kind == .bomb || kind == .nova
    }
    var isCrate: Bool { kind == .crate }
    var isCandy: Bool { kind == .candy }
}

struct Goal {
    var color: TileColor?
    var remaining: Int
}

struct Level {
    let id: Int
    let rows: Int
    let cols: Int
    let palette: [TileColor]
    let moves: Int
    let goals: [Goal]
    let crates: Set<Pos>
    let starScores: (one: Int, two: Int, three: Int)
}

enum LevelCatalog {
    static let count = 30

    static func make(_ id: Int) -> Level {
        let idx = id - 1
        let cols = 8 + (idx % 2)
        let rows = 9 + (idx % 3)
        let colorCount = idx < 10 ? 5 : 6
        let palette = Array(TileColor.allCases.prefix(colorCount))

        var crates = Set<Pos>()
        if id >= 6 {
            switch id % 4 {
            case 0:
                let r0 = rows / 2 - 1, c0 = cols / 2 - 1
                for dr in 0...1 {
                    for dc in 0...1 {
                        crates.insert(Pos(row: r0 + dr, col: c0 + dc))
                    }
                }
            case 1:
                for c in stride(from: 0, to: cols, by: 2) {
                    crates.insert(Pos(row: 0, col: c))
                    crates.insert(Pos(row: 1, col: c))
                }
            case 2:
                let r = rows / 2
                for c in 1..<(cols - 1) {
                    crates.insert(Pos(row: r, col: c))
                }
            default:
                for r in stride(from: 2, to: rows - 2, by: 3) {
                    crates.insert(Pos(row: r, col: cols / 2))
                }
            }
        }

        var goals = [Goal]()
        let base = 14 + idx * 2
        goals.append(Goal(color: palette[idx % palette.count], remaining: min(base, 45)))
        if id >= 4 && id % 3 == 0 {
            goals.append(Goal(color: palette[(idx + 2) % palette.count], remaining: min(base - 4, 36)))
        }
        if !crates.isEmpty {
            goals.append(Goal(color: nil, remaining: crates.count))
        }

        let moves = max(16, 30 - idx / 3 + (goals.count - 1) * 3)
        let three = 3000 + idx * 700
        return Level(
            id: id,
            rows: rows,
            cols: cols,
            palette: palette,
            moves: moves,
            goals: goals,
            crates: crates,
            starScores: (three / 3, three * 2 / 3, three)
        )
    }
}
