import Foundation

struct Equivalence {
    let singular: String
    let plural: String
    let secondsPerUnit: Double
    let minCount: Double
    let maxCount: Double

    func text(for interval: TimeInterval) -> String? {
        let count = interval / secondsPerUnit
        guard count >= minCount, count <= maxCount else { return nil }
        let rounded = count < 10
            ? String(format: "%.1f", count)
            : count.formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
        let noun = count == 1 ? singular : plural
        return "That's \(rounded) \(noun)"
    }
}

enum Perspective {
    static let table: [Equivalence] = [
        Equivalence(singular: "ISS orbit", plural: "ISS orbits", secondsPerUnit: 92 * 60, minCount: 2, maxCount: 500),
        Equivalence(singular: "full moon", plural: "full moons", secondsPerUnit: 29.53 * 86400, minCount: 1, maxCount: 200),
        Equivalence(singular: "mayfly lifetime", plural: "mayfly lifetimes", secondsPerUnit: 86400, minCount: 2, maxCount: 10000),
        Equivalence(singular: "monarch butterfly lifetime", plural: "monarch butterfly lifetimes", secondsPerUnit: 14 * 86400, minCount: 2, maxCount: 2000),
        Equivalence(singular: "Mercury year", plural: "Mercury years", secondsPerUnit: 88 * 86400, minCount: 1, maxCount: 500),
        Equivalence(singular: "Everest expedition", plural: "Everest expeditions", secondsPerUnit: 40 * 86400, minCount: 1, maxCount: 500),
        Equivalence(singular: "human heartbeat", plural: "human heartbeats", secondsPerUnit: 86400.0 / 100_000.0, minCount: 100_000, maxCount: 5_000_000_000),
        Equivalence(singular: "breath", plural: "breaths", secondsPerUnit: 86400.0 / 20_000.0, minCount: 20_000, maxCount: 1_000_000_000),
        Equivalence(singular: "season", plural: "seasons", secondsPerUnit: 91.3 * 86400, minCount: 1, maxCount: 200),
        Equivalence(singular: "trip around the moon", plural: "trips around the moon", secondsPerUnit: 27.3 * 86400, minCount: 1, maxCount: 200),
    ]

    static func line(for interval: TimeInterval, excluding lastIndex: Int? = nil) -> (text: String, index: Int)? {
        let candidates = table.enumerated().compactMap { idx, eq -> (String, Int)? in
            guard idx != lastIndex, let text = eq.text(for: interval) else { return nil }
            return (text, idx)
        }
        if let pick = candidates.randomElement() { return pick }
        return table.enumerated().compactMap { idx, eq in
            eq.text(for: interval).map { (text: $0, index: idx) }
        }.first
    }
}
