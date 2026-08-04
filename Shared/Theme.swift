import SwiftUI

enum QueetFontDesign: String, CaseIterable, Codable {
    case system, rounded, serif, mono

    var design: Font.Design {
        switch self {
        case .system: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .mono: return .monospaced
        }
    }

    var heroTracking: CGFloat {
        switch self {
        case .system: return -3
        case .rounded: return -1.5
        case .serif: return -1
        case .mono: return 0
        }
    }

    var heroWeight: Font.Weight {
        switch self {
        case .system: return .heavy
        case .rounded: return .black
        case .serif: return .bold
        case .mono: return .bold
        }
    }

    var labelTracking: CGFloat { 3 }

    var displayName: String {
        switch self {
        case .system: return "SF Pro"
        case .rounded: return "SF Rounded"
        case .serif: return "New York"
        case .mono: return "SF Mono"
        }
    }

    var next: QueetFontDesign {
        let order = QueetFontDesign.allCases
        let idx = order.firstIndex(of: self)!
        return order[(idx + 1) % order.count]
    }
}

enum BackgroundTheme: String, CaseIterable, Codable {
    case trueBlack, warmBlack, coolBlack, ink, oxblood, forest, paper

    var background: Color {
        switch self {
        case .trueBlack: return Color(red: 0, green: 0, blue: 0)
        case .warmBlack: return Color(red: 0.07, green: 0.05, blue: 0.04)
        case .coolBlack: return Color(red: 0.03, green: 0.04, blue: 0.06)
        case .ink: return Color(red: 0.04, green: 0.07, blue: 0.16)
        case .oxblood: return Color(red: 0.16, green: 0.03, blue: 0.05)
        case .forest: return Color(red: 0.03, green: 0.09, blue: 0.06)
        case .paper: return Color(red: 0.97, green: 0.96, blue: 0.93)
        }
    }

    var foreground: Color {
        self == .paper ? .black : .white
    }

    var displayName: String {
        switch self {
        case .trueBlack: return "True Black"
        case .warmBlack: return "Warm Black"
        case .coolBlack: return "Cool Black"
        case .ink: return "Ink"
        case .oxblood: return "Oxblood"
        case .forest: return "Forest"
        case .paper: return "Paper"
        }
    }

    var next: BackgroundTheme {
        let order = BackgroundTheme.allCases
        let idx = order.firstIndex(of: self)!
        return order[(idx + 1) % order.count]
    }
}

struct QueetTheme {
    var fontDesign: QueetFontDesign
    var background: BackgroundTheme
}
