import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true

    var body: some View {
        Form {
            Section(header: Text("환경 설정")) {
                Picker("테마", selection: $colorScheme) {
                    Text("시스템 기본값").tag("system")
                    Text("라이트 모드").tag("light")
                    Text("다크 모드").tag("dark")
                }
                .pickerStyle(.segmented)
                .font(.system(size: 15, weight: .regular, design: .rounded))

                Toggle(isOn: $isAppLockEnabled) {
                    Text("앱 잠금 (Face ID/암호)")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
                Toggle(isOn: $isHapticsEnabled) {
                    Text("햅틱 피드백")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
        }
        .navigationTitle("설정")
    }
}
