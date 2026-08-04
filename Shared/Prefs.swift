import Foundation

extension UserDefaults {
    static let queetGroup = UserDefaults(suiteName: ModelContainerFactory.appGroupID) ?? .standard
}

enum PerQuitUnitStore {
    static func unit(for quitID: UUID) -> QueetTimeUnit {
        QueetTimeUnit(rawValue: UserDefaults.queetGroup.string(forKey: "unit.\(quitID.uuidString)") ?? "") ?? .days
    }

    static func setUnit(_ unit: QueetTimeUnit, for quitID: UUID) {
        UserDefaults.queetGroup.set(unit.rawValue, forKey: "unit.\(quitID.uuidString)")
    }
}
