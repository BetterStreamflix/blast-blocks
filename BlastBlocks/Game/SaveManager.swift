import Foundation

enum SaveManager {
    private static let defaults = UserDefaults.standard
    private static let unlockedKey = "bb_unlocked"

    static func stars(for level: Int) -> Int {
        defaults.integer(forKey: "bb_stars_\(level)")
    }

    static func unlockedMax() -> Int {
        max(1, defaults.integer(forKey: unlockedKey))
    }

    static func record(level: Int, stars: Int) {
        if stars > self.stars(for: level) {
            defaults.set(stars, forKey: "bb_stars_\(level)")
        }
        if level + 1 > unlockedMax() {
            defaults.set(level + 1, forKey: unlockedKey)
        }
    }

    static func isUnlocked(_ level: Int) -> Bool {
        level <= unlockedMax()
    }
}
