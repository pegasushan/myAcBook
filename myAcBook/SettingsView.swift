import SwiftUI
import CoreData
import UniformTypeIdentifiers
import Combine

// DocumentPickerCoordinator: NSObject + UIDocumentPickerDelegate
class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    let context: NSManagedObjectContext
    let resultSubject: PassthroughSubject<Bool, Never>
    init(context: NSManagedObjectContext, resultSubject: PassthroughSubject<Bool, Never>) {
        self.context = context
        self.resultSubject = resultSubject
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            print("복원 실패: 파일 URL 없음")
            resultSubject.send(false)
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            print("[복원] decoder.dateDecodingStrategy = .secondsSince1970 적용됨")
            let simpleRecords = try decoder.decode([SettingsView.SimpleRecord].self, from: data)
            // 기존 Record 모두 삭제
            let fetch = Record.fetchRequest()
            if let oldRecords = try context.fetch(fetch) as? [Record] {
                for r in oldRecords { context.delete(r) }
            }
            // 복원
            let calendar = Calendar.current
            for s in simpleRecords {
                let r = Record(context: context)
                r.amount = s.amount
                if let date = s.date {
                    r.date = calendar.startOfDay(for: date)
                } else {
                    r.date = nil
                }
                r.detail = s.detail
                r.type = s.type
                r.paymentType = s.paymentType
                // categoryRelation 연결
                if let categoryName = s.categoryName {
                    let catFetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
                    catFetch.predicate = NSPredicate(format: "name == %@", categoryName)
                    if let cat = try? context.fetch(catFetch).first {
                        r.categoryRelation = cat
                    }
                }
            }
            try context.save()
            print("복원 성공: \(simpleRecords.count)개 레코드")
            // 복원 후 실제 저장된 데이터 로그 출력
            let fetchAll = Record.fetchRequest()
            if let allRecords = try? context.fetch(fetchAll) as? [Record] {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                for r in allRecords.prefix(20) {
                    let dateStr = r.date != nil ? dateFormatter.string(from: r.date!) : "nil"
                    print("[복원 후] amount: \(r.amount), date: \(dateStr), detail: \(r.detail ?? "nil"), type: \(r.type ?? "nil")")
                }
            }
            resultSubject.send(true)
        } catch {
            print("복원 실패: \(error.localizedDescription)")
            resultSubject.send(false)
        }
    }
}

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
    @State private var showTestDataAlert = false
    @State private var testDataInsertedMonth: String? = nil
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showRestoreAlert = false
    @State private var restoreResultMessage = ""
    private let restoreResultSubject = PassthroughSubject<Bool, Never>()
    @State private var documentPickerCoordinator: DocumentPickerCoordinator?
    @State private var restoreResultCancellable: AnyCancellable?

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
            name: NSLocalizedString("theme_light_pink", comment: "라이트 핑크"),
            lightBG: "#FEEAF2", darkBG: "#181A20",
            lightCard: "#FFFFFF", darkCard: "#23272F",
            lightSection: "#F6F7FA", darkSection: "#23272F"
        ),
        ColorPalette(
            name: NSLocalizedString("theme_pastel_mint", comment: "파스텔 민트"),
            lightBG: "#D6F5E6", darkBG: "#181A20",
            lightCard: "#FFFFFF", darkCard: "#23272F",
            lightSection: "#E6F9F2", darkSection: "#23272F"
        ),
        ColorPalette(
            name: NSLocalizedString("theme_light_yellow", comment: "라이트 옐로우"),
            lightBG: "#FFF9D6", darkBG: "#181A20",
            lightCard: "#FFFFFF", darkCard: "#23272F",
            lightSection: "#FDF6E3", darkSection: "#23272F"
        ),
        ColorPalette(
            name: NSLocalizedString("theme_white", comment: "화이트"),
            lightBG: "#FFFFFF", darkBG: "#181A20",
            lightCard: "#FFFFFF", darkCard: "#23272F",
            lightSection: "#FFFFFF", darkSection: "#23272F"
        )
    ]

    // DTO 구조체 (Record만 예시)
    struct SimpleRecord: Codable {
        let amount: Double
        let date: Date?
        let detail: String?
        let type: String?
        let categoryName: String?
        let paymentType: String?
        // 필요한 필드만 추가
        init(from record: Record) {
            self.amount = record.amount
            self.date = record.date
            self.detail = record.detail
            self.type = record.type
            self.categoryName = record.categoryRelation?.name
            self.paymentType = record.paymentType
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if colorScheme == .light {
                    Text(NSLocalizedString("recommended_theme_title", comment: "추천 테마"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .padding(.top, 24)
                    HStack(spacing: 12) {
                        ForEach(palettes, id: \.name) { palette in
                            Button(action: {
                                customLightBGColorHex = palette.lightBG
                                customDarkBGColorHex = palette.darkBG
                                customLightCardColorHex = palette.lightCard
                                customDarkCardColorHex = palette.darkCard
                                customLightSectionColorHex = palette.lightSection
                                customDarkSectionColorHex = palette.darkSection
                            }) {
                                Circle()
                                    .fill(Color(UIColor(hex: palette.lightBG)))
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
                        Picker(NSLocalizedString("theme", comment: "테마"), selection: $colorSchemeSetting) {
                            Text(NSLocalizedString("system_default", comment: "시스템 기본값")).tag("system")
                            Text(NSLocalizedString("light_mode", comment: "라이트 모드")).tag("light")
                            Text(NSLocalizedString("dark_mode", comment: "다크 모드")).tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                    }
                    Section {
                        Toggle(isOn: $lockToggleValue) {
                            Text(NSLocalizedString("app_lock", comment: "앱 잠금 (Face ID/암호"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .onChange(of: lockToggleValue) { newValue, _ in
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
                        Button(action: { exportBackup() }) {
                            Text("백업 내보내기")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        Button(action: { importBackup() }) {
                            Text("백업 가져오기")
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
                    Section(header: Text(NSLocalizedString("test_section_title", comment: "테스트"))) {
                        // 기존 데이터 삭제 버튼 추가
                        Button(action: {
                            let context = PersistenceController.shared.container.viewContext
                            let fetch: NSFetchRequest<Record> = Record.fetchRequest()
                            let allRecords = (try? context.fetch(fetch)) ?? []
                            for record in allRecords {
                                context.delete(record)
                            }
                            do {
                                try context.save()
                                print("모든 Record 삭제 완료")
                                showTestDataAlert = true
                                testDataInsertedMonth = nil
                            } catch {
                                print("Record 삭제 실패:", error)
                                showTestDataAlert = true
                                testDataInsertedMonth = nil
                            }
                        }) {
                            Text("모든 데이터 삭제")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.red)
                        }
                        // 기존 테스트 데이터 입력 버튼
                        Button(action: {
                            let context = PersistenceController.shared.container.viewContext
                            let calendar = Calendar.current
                            let now = Date()
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM"
                            // 1. 카테고리 자동 생성 (수입/지출)
                            let incomeCategoryFetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
                            incomeCategoryFetch.predicate = NSPredicate(format: "type == %@", "income")
                            let expenseCategoryFetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
                            expenseCategoryFetch.predicate = NSPredicate(format: "type == %@", "expense")
                            let existingIncomeCategories = (try? context.fetch(incomeCategoryFetch)) ?? []
                            let existingExpenseCategories = (try? context.fetch(expenseCategoryFetch)) ?? []
                            print("수입 카테고리 개수: \(existingIncomeCategories.count)")
                            print("지출 카테고리 개수: \(existingExpenseCategories.count)")
                            if existingIncomeCategories.isEmpty {
                                let defaultIncomeNames = ["salary", "side_income"]
                                for name in defaultIncomeNames {
                                    let cat = AppCategory(context: context)
                                    cat.id = UUID()
                                    cat.name = name
                                    cat.type = "income"
                                }
                                try? context.save() // 카테고리 생성 후 저장
                            }
                            if existingExpenseCategories.isEmpty {
                                let defaultExpenseNames = ["food", "beverage", "transportation", "shopping", "leisure", "etc"]
                                for name in defaultExpenseNames {
                                    let cat = AppCategory(context: context)
                                    cat.id = UUID()
                                    cat.name = name
                                    cat.type = "expense"
                                }
                                try? context.save() // 카테고리 생성 후 저장
                            }
                            // 카테고리 최신 fetch
                            let updatedIncomeCategories = (try? context.fetch(incomeCategoryFetch)) ?? []
                            let updatedExpenseCategories = (try? context.fetch(expenseCategoryFetch)) ?? []

                            // 2. 카드 자동 생성
                            let cardFetch: NSFetchRequest<Card> = Card.fetchRequest()
                            let existingCards = (try? context.fetch(cardFetch)) ?? []
                            print("카드 개수: \(existingCards.count)")
                            if existingCards.isEmpty {
                                let defaultCardNames = ["신한카드", "삼성카드"]
                                for name in defaultCardNames {
                                    let card = Card(context: context)
                                    card.id = UUID()
                                    card.name = name
                                    card.createdAt = Date()
                                }
                                try? context.save() // 카드 생성 후 저장
                            }
                            // 카드 최신 fetch
                            let updatedCards = (try? context.fetch(cardFetch)) ?? []

                            // 기존 Record의 월 정보 추출 (existingMonths)
                            let fetch: NSFetchRequest<Record> = Record.fetchRequest()
                            let allRecords = (try? context.fetch(fetch)) ?? []
                            let existingMonths = Set<String>(allRecords.compactMap { record in
                                guard let date = record.date else { return nil }
                                return dateFormatter.string(from: date)
                            })
                            print("기존 데이터 월: \(existingMonths)")

                            // 최근 12개월 중 데이터가 없는 달 후보 만들기 (2020년~오늘 사이만)
                            var candidateMonths: [String] = []
                            var candidateMonthDates: [Date] = []
                            for offset in 0..<12 {
                                if let monthDate = calendar.date(byAdding: .month, value: -offset, to: now),
                                   calendar.component(.year, from: monthDate) >= 2020,
                                   monthDate <= now {
                                    let monthString = dateFormatter.string(from: monthDate)
                                    if !existingMonths.contains(monthString) {
                                        candidateMonths.append(monthString)
                                        candidateMonthDates.append(monthDate)
                                    }
                                }
                            }
                            print("후보 달: \(candidateMonths)")
                            if candidateMonthDates.isEmpty {
                                print("후보 달이 없습니다. 테스트 데이터 생성 스킵")
                                showTestDataAlert = true
                                return
                            }
                            let sortedCandidateMonthDates = candidateMonthDates.sorted(by: >)
                            guard let selectedMonthDate = sortedCandidateMonthDates.first else {
                                print("선택된 달이 없음")
                                showTestDataAlert = true
                                return
                            }
                            print("선택된 달: \(selectedMonthDate) (year: \(calendar.component(.year, from: selectedMonthDate)))")
                            if calendar.component(.year, from: selectedMonthDate) < 2020 || selectedMonthDate > now {
                                print("선택된 달이 유효하지 않음. 테스트 데이터 생성 중단")
                                showTestDataAlert = true
                                return
                            }
                            let selectedMonthString = dateFormatter.string(from: selectedMonthDate)
                            // 한 달치 데이터 입력
                            let range = calendar.range(of: .day, in: .month, for: selectedMonthDate) ?? (1..<29)
                            var createdCount = 0
                            for day in range {
                                var dateComponents = calendar.dateComponents([.year, .month], from: selectedMonthDate)
                                dateComponents.day = day
                                guard let date = calendar.date(from: dateComponents) else { continue }
                                // 오늘 이후, 2020년 이전 날짜는 건너뜀
                                if date > now { continue }
                                if calendar.component(.year, from: date) < 2020 { continue }
                                let count = Int.random(in: 1...5)
                                for i in 0..<count {
                                    let record = Record(context: context)
                                    record.id = UUID()
                                    record.amount = Double(Int.random(in: 1000...100000))
                                    let isIncome = Bool.random()
                                    record.type = isIncome ? NSLocalizedString("income", comment: "수입") : NSLocalizedString("expense", comment: "지출")
                                    record.date = date
                                    record.detail = "테스트 \(i+1)"
                                    if isIncome {
                                        record.paymentType = NSLocalizedString("cash", comment: "현금")
                                        record.card = nil
                                    } else {
                                        let isCard = Bool.random()
                                        record.paymentType = isCard ? NSLocalizedString("card", comment: "카드") : NSLocalizedString("cash", comment: "현금")
                                        if isCard {
                                            if let selectedCard = updatedCards.randomElement() {
                                                record.card = selectedCard
                                            }
                                        } else {
                                            record.card = nil
                                        }
                                    }
                                    let availableCategories = isIncome ? updatedIncomeCategories : updatedExpenseCategories
                                    if let selectedCategory = availableCategories.randomElement() {
                                        record.categoryRelation = selectedCategory
                                    }
                                    createdCount += 1
                                }
                            }
                            do {
                                try context.save()
                                print("테스트 데이터 저장 성공 (입력된 달: \(selectedMonthString)), 생성된 Record 수: \(createdCount)")
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: Notification.Name("TestDataInserted"), object: nil)
                                    showTestDataAlert = true
                                    testDataInsertedMonth = selectedMonthString
                                }
                            } catch {
                                print("테스트 데이터 저장 실패:", error)
                                DispatchQueue.main.async {
                                    showTestDataAlert = true
                                    testDataInsertedMonth = nil
                                }
                            }
                        }) {
                            Text(NSLocalizedString("insert_test_data_button", comment: "테스트 데이터 입력"))
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.red)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(colorScheme == .light ? customLightBGColor : Color(UIColor(hex: customDarkBGColorHex)))
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
            hapticsValue = isHapticsEnabled
            restoreResultCancellable = restoreResultSubject.sink { success in
                restoreResultMessage = success ? "백업 복원이 완료되었습니다." : "복원에 실패했습니다. 파일을 확인해주세요."
                showRestoreAlert = true
            }
        }
        .onDisappear {
            isAppLockEnabled = lockToggleValue
            isHapticsEnabled = hapticsValue
        }
        .alert(isPresented: $showTestDataAlert) {
            Alert(title: Text(NSLocalizedString("test_data_inserted_title", comment: "테스트 데이터 입력 완료")), message: Text(String(format: NSLocalizedString("test_data_inserted_message", comment: "테스트 데이터가 성공적으로 입력되었습니다.\n입력된 달: %@"), testDataInsertedMonth ?? "-")), dismissButton: .default(Text(NSLocalizedString("confirm", comment: "확인"))))
        }
        .alert(isPresented: $showRestoreAlert) {
            Alert(title: Text(restoreResultMessage), dismissButton: .default(Text("확인")))
        }
    }

    // 백업 내보내기
    func exportBackup() {
        let records = (try? viewContext.fetch(Record.fetchRequest())) as? [Record] ?? []
        let simpleRecords = records.map { SimpleRecord(from: $0) }
        // 로그 출력
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        for s in simpleRecords.prefix(20) { // 너무 많을 경우 20개만
            let dateStr = s.date != nil ? dateFormatter.string(from: s.date!) : "nil"
            print("[백업] amount: \(s.amount), date: \(dateStr), detail: \(s.detail ?? "nil"), type: \(s.type ?? "nil")")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(simpleRecords) else { return }
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("myAcBookBackup_\(todayString).json")
        try? data.write(to: url)
        let picker = UIDocumentPickerViewController(forExporting: [url])
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }

    // 백업 가져오기
    func importBackup() {
        let coordinator = DocumentPickerCoordinator(context: viewContext, resultSubject: restoreResultSubject)
        self.documentPickerCoordinator = coordinator // 메모리에 유지
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = coordinator
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }
} 
