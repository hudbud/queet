import SwiftUI
import SwiftData

@main
struct QueetApp: App {
    let container = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(container)
    }
}
