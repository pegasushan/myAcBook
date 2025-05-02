import SwiftUI

@main
struct myAcBookApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @StateObject var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if isAppLockEnabled {
                    if authManager.isUnlocked {
                        ContentView()
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)
                            .preferredColorScheme(
                                colorScheme == "light" ? .light :
                                colorScheme == "dark" ? .dark : nil
                            )
                    } else {
                        VStack {
                            Text("앱 잠금 해제 필요")
                                .font(.title2)
                                .padding()
                        }
                    }
                } else {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .preferredColorScheme(
                            colorScheme == "light" ? .light :
                            colorScheme == "dark" ? .dark : nil
                        )
                }
            }
            .task {
                if isAppLockEnabled && !authManager.isUnlocked {
                    authManager.authenticate()
                }
            }
        }
    }
}
