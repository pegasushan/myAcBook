import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var showAppLockHint: Bool = false
    @State private var lockToggleValue: Bool = false

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

                Toggle(isOn: $lockToggleValue) {
                    Text("앱 잠금 (Face ID/암호)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .onChange(of: lockToggleValue) { _, newValue in
                    if newValue {
                        showAppLockHint = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showAppLockHint = false
                            dismiss()
                            // Delay updating storage flag until after dismiss
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isAppLockEnabled = true
                            }
                        }
                    } else {
                        isAppLockEnabled = false
                    }
                }
                if showAppLockHint {
                    Text("다음 앱 실행 시부터 적용됩니다.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.leading, 2)
                }
                Toggle(isOn: $isHapticsEnabled) {
                    Text("햅틱 피드백")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
        }
        .onAppear {
            lockToggleValue = isAppLockEnabled
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("설정 ⚙️")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
        }
    }
}
