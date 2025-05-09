import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var showAppLockHint: Bool = false
    @State private var lockToggleValue: Bool = false
    @State private var showSaveConfirmation = false
    @State private var hapticsValue: Bool = true
    @State private var selectedColorScheme: String = "system"

    var body: some View {
        Form {
            Section(header: Text("환경 설정")) {
                Picker("테마", selection: $selectedColorScheme) {
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
                    showAppLockHint = newValue
                }
                if showAppLockHint {
                    Text("다음 앱 실행 시부터 적용됩니다.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.leading, 2)
                }
                Toggle(isOn: $hapticsValue) {
                    Text("햅틱 피드백")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
        }
        .onAppear {
            if UserDefaults.standard.object(forKey: "isAppLockEnabled") == nil {
                isAppLockEnabled = false
                lockToggleValue = false
            } else {
                lockToggleValue = isAppLockEnabled
            }
            selectedColorScheme = colorScheme
            hapticsValue = isHapticsEnabled
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("설정 ⚙️")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isAppLockEnabled = lockToggleValue
                    colorScheme = selectedColorScheme
                    isHapticsEnabled = hapticsValue
                    showSaveConfirmation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }) {
                    Text("저장")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
        }
        .alert("설정이 저장되었습니다.", isPresented: $showSaveConfirmation) {
            Button("확인", role: .cancel) {}
        }
    }
}
