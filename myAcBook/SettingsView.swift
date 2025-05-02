import SwiftUI

struct SettingsView: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("colorScheme") private var colorScheme: String = "system" // 시스템 테마 기본값

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("환경 설정").font(.system(size: 15, weight: .semibold, design: .rounded))) {
                    Toggle(isOn: $isHapticsEnabled) {
                        Text("햅틱 피드백 사용").font(.system(size: 15, weight: .regular, design: .rounded))
                    }

                    Picker(selection: $colorScheme) {
                        Text("시스템 기본값").font(.system(size: 15, weight: .regular, design: .rounded)).tag("system")
                        Text("라이트 모드").font(.system(size: 15, weight: .regular, design: .rounded)).tag("light")
                        Text("다크 모드").font(.system(size: 15, weight: .regular, design: .rounded)).tag("dark")
                    } label: {
                        Text("테마")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}
