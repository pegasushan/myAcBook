import LocalAuthentication
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isUnlocked = false

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "앱에 접근하려면 인증이 필요합니다."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    self.isUnlocked = success
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isUnlocked = false
            }
            print("인증 불가: \(error?.localizedDescription ?? "알 수 없음")")
        }
    }
}
