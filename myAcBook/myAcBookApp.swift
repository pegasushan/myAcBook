import SwiftUI

@main
struct myAcBookApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @StateObject var authManager = AuthManager()
    @StateObject var purchaseManager = PurchaseManager.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(purchaseManager)
                .preferredColorScheme(
                    colorScheme == "light" ? .light :
                    colorScheme == "dark" ? .dark : nil
                )
                .overlay(
                    Group {
                        if isAppLockEnabled && !authManager.isUnlocked {
                            Color.black.opacity(0.6).ignoresSafeArea()
                        }
                    }
                )
                .task(id: isAppLockEnabled) {
                    if isAppLockEnabled && !authManager.isUnlocked {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            authManager.authenticate()
                        }
                    }
                }
        }
    }
}
