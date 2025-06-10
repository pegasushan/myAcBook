import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"
    @Environment(\.colorScheme) var colorScheme
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
    @AppStorage("customLightBGColor") private var customLightBGColorHex: String = "#FEEAF2"
    var customLightBGColor: Color { Color(UIColor(hex: customLightBGColorHex)) }
    @AppStorage("customDarkBGColor") private var customDarkBGColorHex: String = "#181A20"
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    @AppStorage("customLightSectionColor") private var customLightSectionColorHex: String = "#F6F7FA"
    @AppStorage("customDarkSectionColor") private var customDarkSectionColorHex: String = "#23272F"
    @State private var showColorPicker = false

    struct ColorPalette {
        let name: String
        let lightBG: String
        let darkBG: String
        let lightCard: String
        let darkCard: String
        let lightSection: String
        let darkSection: String
    }

    let palettes = [
        ColorPalette(
            name: "라이트 핑크",
            lightBG: "#FEEAF2", darkBG: "#181A20",
            lightCard: "#FFFFFF", darkCard: "#23272F",
            lightSection: "#F6F7FA", darkSection: "#23272F"
        ),
        ColorPalette(
            name: "파스텔 민트",
            lightBG: "#D6F5E6", darkBG: "#181A20",
            lightCard: "#FFFFFF", darkCard: "#23272F",
            lightSection: "#E6F9F2", darkSection: "#23272F"
        ),
        ColorPalette(
            name: "라이트 옐로우",
            lightBG: "#FFF9D6", darkBG: "#181A20",
            lightCard: "#FFFFFF", darkCard: "#23272F",
            lightSection: "#FDF6E3", darkSection: "#23272F"
        )
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if colorScheme == .light {
                    Text("추천 테마")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .padding(.top, 24)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(palettes, id: \.name) { palette in
                            Button(action: {
                                customLightBGColorHex = palette.lightBG
                                customDarkBGColorHex = palette.darkBG
                                customLightCardColorHex = palette.lightCard
                                customDarkCardColorHex = palette.darkCard
                                customLightSectionColorHex = palette.lightSection
                                customDarkSectionColorHex = palette.darkSection
                            }) {
                                VStack {
                                    Circle()
                                        .fill(Color(UIColor(hex: palette.lightBG)))
                                        .frame(width: 36, height: 36)
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                    Text(palette.name)
                                        .font(.caption)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                } else {
                    Text("추천 테마는 라이트 모드에서만 선택할 수 있습니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                }
                // 기존 Form
                Form {
                    Section {
                        Picker(NSLocalizedString("theme", comment: "테마"), selection: $selectedColorScheme) {
                            Text(NSLocalizedString("system_default", comment: "시스템 기본값")).tag("system")
                            Text(NSLocalizedString("light_mode", comment: "라이트 모드")).tag("light")
                            Text(NSLocalizedString("dark_mode", comment: "다크 모드")).tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .font(.system(size: 15, weight: .regular, design: .rounded))

                        Toggle(isOn: $lockToggleValue) {
                            Text(NSLocalizedString("app_lock", comment: "앱 잠금 (Face ID/암호"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .onChange(of: lockToggleValue) { _, newValue in
                            showAppLockHint = newValue
                        }
                        if showAppLockHint {
                            Text(NSLocalizedString("lock_hint", comment: "다음 앱 실행 시부터 적용됩니다."))
                                .font(.footnote)
                                .foregroundColor(Color("HighlightColor"))
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
                                .foregroundColor(.primary)
                        }
                        Button(action: {
                            showCategoryManagerModal = true
                        }) {
                            Text(NSLocalizedString("category_management", comment: "카테고리 관리"))
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    Section(header: Text(NSLocalizedString("premium_section", comment: "프리미엄"))){
                        if purchaseManager.isAdRemoved {
                            Text(NSLocalizedString("ad_removed_done", comment: "광고 제거 완료 🎉"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("IncomeColor"))
                        } else {
                            Button {
                                Task {
                                    print("🟡 광고 제거 버튼 클릭됨")
                                    await purchaseManager.purchase()
                                }
                            } label: {
                                Text(String(format: NSLocalizedString("remove_ads_button", comment: "광고 제거 (%@)"), "₩1,100"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                            }

                            Button {
                                Task {
                                    await purchaseManager.restore()
                                }
                            } label: {
                                Text(NSLocalizedString("restore_purchase", comment: "구매 복원"))
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(colorScheme == .light ? customLightBGColor : Color("BackgroundSolidColor"))
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
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(NSLocalizedString("settings_tab", comment: "설정"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isAppLockEnabled = lockToggleValue
                    colorSchemeSetting = selectedColorScheme
                    isHapticsEnabled = hapticsValue
                    dismiss()
                }) {
                    Text(NSLocalizedString("save", comment: "저장"))
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
            selectedColorScheme = colorSchemeSetting
            hapticsValue = isHapticsEnabled
        }
        .onDisappear {
            isAppLockEnabled = lockToggleValue
            colorSchemeSetting = selectedColorScheme
            isHapticsEnabled = hapticsValue
        }
    }
}
