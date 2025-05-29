import SwiftUI
import CoreData

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
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showCardManagerModal = false
    @State private var showCategoryManagerModal = false

    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("settings_section", comment: "환경 설정"))) {
                Picker(NSLocalizedString("theme", comment: "테마"), selection: $selectedColorScheme) {
                    Text(NSLocalizedString("system_default", comment: "시스템 기본값")).tag("system")
                    Text(NSLocalizedString("light_mode", comment: "라이트 모드")).tag("light")
                    Text(NSLocalizedString("dark_mode", comment: "다크 모드")).tag("dark")
                }
                .pickerStyle(.segmented)
                .font(.system(size: 15, weight: .regular, design: .rounded))

                Toggle(isOn: $lockToggleValue) {
                    Text(NSLocalizedString("app_lock", comment: "앱 잠금 (Face ID/암호)"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .onChange(of: lockToggleValue) { _, newValue in
                    showAppLockHint = newValue
                }
                if showAppLockHint {
                    Text(NSLocalizedString("lock_hint", comment: "다음 앱 실행 시부터 적용됩니다."))
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.leading, 2)
                }
                Toggle(isOn: $hapticsValue) {
                    Text(NSLocalizedString("haptics", comment: "햅틱 피드백"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
            Section(header: Text(NSLocalizedString("management_section", comment: "항목 관리"))) {
                Button(action: {
                    showCardManagerModal = true
                }) {
                    Text(NSLocalizedString("card_management", comment: "카드 관리"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
                Button(action: {
                    showCategoryManagerModal = true
                }) {
                    Text(NSLocalizedString("category_management", comment: "카테고리 관리"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }

            Section(header: Text(NSLocalizedString("premium_section", comment: "프리미엄"))){
                if purchaseManager.isAdRemoved {
                    Text(NSLocalizedString("ad_removed_done", comment: "광고 제거 완료 🎉"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                } else {
                    Button {
                        Task {
                            print("🟡 광고 제거 버튼 클릭됨")
                            await purchaseManager.purchase()
                        }
                    } label: {
                        Text(String(format: NSLocalizedString("remove_ads_button", comment: "광고 제거 (%@)"), "₩1,100"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }

                    Button {
                        Task {
                            await purchaseManager.restore()
                        }
                    } label: {
                        Text(NSLocalizedString("restore_purchase", comment: "구매 복원"))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                    }
                }

//                #if DEBUG
//                Button {
//                    UserDefaults.standard.set(false, forKey: "isPremiumUser")
//                    purchaseManager.isAdRemoved = false
//                    print("🔁 광고 제거 상태 초기화됨")
//                } label: {
//                    Text("초기화 (테스트용)")
//                        .font(.system(size: 15, weight: .regular, design: .rounded))
//                        .foregroundColor(.red)
//                }
//                #endif
            }
        }
        .sheet(isPresented: $showCardManagerModal) {
            NavigationStack {
                CardListView()
            }
        }
        .sheet(isPresented: $showCategoryManagerModal) {
            NavigationStack {
                CategoryManagerView(selectedType: NSLocalizedString("expense", comment: "지출"))
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
                Text(NSLocalizedString("settings_tab", comment: "설정"))
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
                    Text(NSLocalizedString("save", comment: "저장"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
        }
        .alert(NSLocalizedString("settings_saved", comment: "설정이 저장되었습니다."), isPresented: $showSaveConfirmation) {
            Button(NSLocalizedString("confirm", comment: "확인"), role: .cancel) {}
        }
    }
}
