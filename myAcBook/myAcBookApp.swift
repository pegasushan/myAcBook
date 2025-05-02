import SwiftUI

@main
struct myAcBookApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("colorScheme") private var colorScheme: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(
                    colorScheme == "light" ? .light :
                    colorScheme == "dark" ? .dark : nil
                )
        }
    }
}
