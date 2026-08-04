import Foundation

enum QueetTimeUnit: String, CaseIterable, Codable {
    case seconds, minutes, hours, days, weeks, months, years

    var label: String { rawValue }

    var next: QueetTimeUnit {
        let order = QueetTimeUnit.allCases
        let idx = order.firstIndex(of: self)!
        return order[(idx + 1) % order.count]
    }

    private var secondsPerUnit: Double {
        switch self {
        case .seconds: return 1
        case .minutes: return 60
        case .hours: return 3600
        case .days: return 86400
        case .weeks: return 86400 * 7
        case .months: return 86400 * 30.4368
        case .years: return 86400 * 365.2425
        }
    }

    func value(for interval: TimeInterval) -> Double {
        max(0, interval / secondsPerUnit)
    }

    /// TimelineView refresh cadence in seconds for this unit's display to feel live without over-rendering.
    var refreshInterval: Double {
        switch self {
        case .seconds, .minutes: return 1
        case .hours: return 15
        default: return 30
        }
    }
}
