import AppIntents
import SwiftData

struct QuitEntity: AppEntity {
    let id: UUID
    let name: String
    let emoji: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Quit"
    static var defaultQuery = QuitEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }
}

struct QuitEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [QuitEntity] {
        allEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [QuitEntity] {
        allEntities()
    }

    private func allEntities() -> [QuitEntity] {
        let context = ModelContext(ModelContainerFactory.make())
        let quits = (try? context.fetch(FetchDescriptor<Quit>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        return quits.map { QuitEntity(id: $0.id, name: $0.name, emoji: $0.emoji) }
    }
}

enum WidgetMetric: String, AppEnum {
    case time, money

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Metric"
    static var caseDisplayRepresentations: [WidgetMetric: DisplayRepresentation] = [
        .time: "Time",
        .money: "Money saved",
    ]
}

enum QueetTimeUnitAppEnum: String, AppEnum {
    case hours, days, weeks, months, years

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Unit"
    static var caseDisplayRepresentations: [QueetTimeUnitAppEnum: DisplayRepresentation] = [
        .hours: "Hours", .days: "Days", .weeks: "Weeks", .months: "Months", .years: "Years",
    ]

    var timeUnit: QueetTimeUnit {
        switch self {
        case .hours: return .hours
        case .days: return .days
        case .weeks: return .weeks
        case .months: return .months
        case .years: return .years
        }
    }
}

struct SelectQuitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose Quit"
    static var description = IntentDescription("Pick which quit and metric to display.")

    @Parameter(title: "Quit")
    var quit: QuitEntity?

    @Parameter(title: "Show", default: .time)
    var metric: WidgetMetric

    @Parameter(title: "Unit", default: .days)
    var unit: QueetTimeUnitAppEnum
}
