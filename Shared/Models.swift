import Foundation
import SwiftData

@Model
final class Quit {
    var id: UUID
    var name: String
    var emoji: String
    var startDate: Date
    var costPerDay: Decimal
    var currencyCode: String
    var sortOrder: Int
    var attempts: [Attempt]

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        startDate: Date,
        costPerDay: Decimal = 0,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.startDate = startDate
        self.costPerDay = costPerDay
        self.currencyCode = currencyCode
        self.sortOrder = sortOrder
        self.attempts = []
    }
}

@Model
final class Attempt {
    var startDate: Date
    var endDate: Date

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

enum ModelContainerFactory {
    static let appGroupID = "group.com.hudsonpaine.queet"

    static func make() -> ModelContainer {
        let schema = Schema([Quit.self, Attempt.self])
        let configuration: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            configuration = ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("Queet.sqlite"))
        } else {
            configuration = ModelConfiguration(schema: schema)
        }
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
