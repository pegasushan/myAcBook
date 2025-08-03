import SwiftUI
import UIKit

// 앱 전체를 세로(Portrait)로만 고정하는 AppDelegate 추가
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

@main
struct myAcBookApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @StateObject var authManager = AuthManager()
    @StateObject var purchaseManager = PurchaseManager.shared
    @State private var showSplash = true // SplashView 표시 상태

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation {
                        showSplash = false
                    }
                }
            }
        }
    }
}
