import SwiftUI
import Charts
import GoogleMobileAds
import CoreData
import UIKit
// AdMob 배너 광고 뷰
struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = "ca-app-pub-7005642235163744/5831051767" // 여기에 AdMob 광고 단위 ID 입력
        //banner.adUnitID = "ca-app-pub-3940256099942544/2934735716" //test
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct ContentView: View {
    // MARK: - Environment & State
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var purchaseManager: IAPManager
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("isAdRemoved") private var isAdRemoved: Bool = false

    @State private var selectedRecords = Set<Record>()
    @State private var editMode: EditMode = .inactive
    @State private var isAddingNewRecord = false
    @State private var selectedRecord: Record? = nil
    @State private var recordToDelete: Record? = nil
    @State private var showingDeleteAlert = false
    @State private var selectedTabTitle: String = NSLocalizedString("ledger_tab", comment: "앱 타이틀")
    @State private var selectedStatTab: String = NSLocalizedString("expense", comment: "")
    @State private var isDeleteMode = false
    @AppStorage("selectedCategory") private var selectedCategory: String = NSLocalizedString("all", comment: "")
    @State private var selectedIncomeCategory: String = NSLocalizedString("all", comment: "")
    @State private var selectedExpenseCategory: String = NSLocalizedString("all", comment: "")
    @State private var selectedAllCategory: String = NSLocalizedString("all", comment: "")
    @State private var selectedPaymentType: String = NSLocalizedString("all", comment: "전체")
    @AppStorage("selectedDateFilter") private var selectedDateFilter: String = NSLocalizedString("month", comment: "한달")
    @AppStorage("selectedTypeFilter") private var selectedTypeFilter: String = NSLocalizedString("all", comment: "")
    @State private var showFilterSheet = false
    @AppStorage("customStartDate") private var customStartTimestamp: Double = Date().timeIntervalSince1970
    @AppStorage("customEndDate") private var customEndTimestamp: Double = Date().timeIntervalSince1970
    @State private var showSettingsSheet = false
    @State private var customStartDate: Date
    @State private var customEndDate: Date
    @State private var showStatistics = false
    @AppStorage("customLightBGColor") private var customLightBGColorHex: String = "#FEEAF2"
    @AppStorage("customDarkBGColor") private var customDarkBGColorHex: String = "#181A20"
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    @AppStorage("customLightSectionColor") private var customLightSectionColorHex: String = "#F6F7FA"
    @AppStorage("customDarkSectionColor") private var customDarkSectionColorHex: String = "#23272F"
    @Environment(\.colorScheme) var colorScheme

    // 페이징 관련 상태
    @State private var loadedMonthCount: Int = 1
    @State private var records: [Record] = []
    @State private var selectedMonth: String = "2025-07"

    // 1. 전체 월 리스트 생성
    private var allMonths: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let now = Date()
        return (0..<36).map { offset in
            let date = Calendar.current.date(byAdding: .month, value: -offset, to: now)!
            return formatter.string(from: date)
        }
    }

    @State private var selectedMonthIndex: Int = 0

    // MARK: - Init
    var onStatisticsDataChanged: (([String: Double], [String: Double], [String: [String: Double]], [String: [String: Double]], [String: [String: Double]], String, String, String, String, [String: Double]) -> Void)? = nil
    init(
        onStatisticsDataChanged: (([String: Double], [String: Double], [String: [String: Double]], [String: [String: Double]], [String: [String: Double]], String, String, String, String, [String: Double]) -> Void)? = nil
    ) {
        let start = UserDefaults.standard.double(forKey: "customStartDate")
        let end = UserDefaults.standard.double(forKey: "customEndDate")
        _customStartDate = State(initialValue: start > 0 ? Date(timeIntervalSince1970: start) : Date())
        _customEndDate = State(initialValue: end > 0 ? Date(timeIntervalSince1970: end) : Date())
        self.onStatisticsDataChanged = onStatisticsDataChanged
    }

    // MARK: - Computed Properties
    var customBGColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightBGColorHex)) : Color(UIColor(hex: customDarkBGColorHex))
    }
    var customCardColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightCardColorHex)) : Color(UIColor(hex: customDarkCardColorHex))
    }
    var customSectionColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightSectionColorHex)) : Color(UIColor(hex: customDarkSectionColorHex))
    }
    private var currentCategory: String { selectedCategory }

    // MARK: - Filtering & Grouping
    private func isRecordInSelectedDateRange(_ record: Record) -> Bool {
        guard selectedDateFilter != NSLocalizedString("all", comment: "") else { return true }
        guard let recordDate = record.date else { return false }
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        switch selectedDateFilter {
        case NSLocalizedString("today", comment: ""):
            return calendar.isDateInToday(recordDate)
        case NSLocalizedString("yesterday", comment: ""):
            return calendar.isDateInYesterday(recordDate)
        case NSLocalizedString("week", comment: ""):
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) {
                return recordDate >= weekAgo && recordDate <= now
            } else { return false }
        case NSLocalizedString("month", comment: ""):
            if let monthAgo = calendar.date(byAdding: .month, value: -1, to: startOfToday) {
                return recordDate >= monthAgo && recordDate <= now
            } else { return false }
        case NSLocalizedString("custom", comment: ""):
            let safeStartDate = min(customStartDate, customEndDate)
            let safeEndDate = max(customStartDate, customEndDate)
            let recordDay = calendar.startOfDay(for: recordDate)
            let startDay = calendar.startOfDay(for: safeStartDate)
            let endDay = calendar.startOfDay(for: safeEndDate)
            return recordDay >= startDay && recordDay <= endDay
        default:
            return true
        }
    }
    private var filteredRecords: [Record] {
        records.filter { record in
            let recordCategoryKey = record.categoryRelation?.name ?? "etc"
            let matchesCategory = currentCategory == NSLocalizedString("all", comment: "") || recordCategoryKey == currentCategory
            let matchesType: Bool = {
                if selectedTypeFilter == NSLocalizedString("all", comment: "") { return true }
                guard let type = record.type else { return false }
                return type == selectedTypeFilter
            }()
            let matchesPaymentType: Bool = {
                if selectedTypeFilter == NSLocalizedString("expense", comment: "") && selectedPaymentType != NSLocalizedString("all", comment: "전체") {
                    return record.paymentType == selectedPaymentType
                }
                return true
            }()
            // categoryRelation이 nil인 Record는 제외
            return matchesCategory && matchesType && matchesPaymentType && record.categoryRelation != nil
        }
    }
    // 날짜별 그룹핑 유틸 추가
    private var groupedRecordsByDate: [Date: [Record]] {
        let calendar = Calendar.current
        return Dictionary(grouping: records) { record in
            guard let date = record.date else { return Date.distantPast }
            return calendar.startOfDay(for: date)
        }
    }
    private var sortedRecordDates: [Date] {
        groupedRecordsByDate.keys.sorted(by: >)
    }

    // MARK: - 데이터 페치 함수
    private func fetchRecords() {
        let request = Record.fetchRequest()
        // 모든 데이터를 한 번에 보여주기 위해 predicate를 nil로 설정
        request.predicate = nil
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Record.date, ascending: false)]
        request.fetchBatchSize = 50
        do {
            let result = try viewContext.fetch(request)
            records = result
        } catch {
            records = []
        }
    }

    // MARK: - 전체 필터 적용 총 건수
    private var totalFilteredRecordsCount: Int {
        let request = Record.fetchRequest()
        var predicates: [NSPredicate] = []
        // 타입, 카테고리, 결제수단 등 기존 필터 조건 추가
        if selectedTypeFilter != NSLocalizedString("all", comment: "") {
            predicates.append(NSPredicate(format: "type == %@", selectedTypeFilter))
        }
        if currentCategory != NSLocalizedString("all", comment: "") {
            predicates.append(NSPredicate(format: "categoryRelation.name == %@", currentCategory))
        }
        if selectedPaymentType != NSLocalizedString("all", comment: "전체") && selectedTypeFilter == NSLocalizedString("expense", comment: "지출") {
            predicates.append(NSPredicate(format: "paymentType == %@", selectedPaymentType))
        }
        // 기간 필터는 '전체'일 때는 추가하지 않음
        if selectedDateFilter != NSLocalizedString("all", comment: "") {
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            if selectedDateFilter == NSLocalizedString("month", comment: "한달") {
                if let monthAgo = calendar.date(byAdding: .month, value: -1, to: startOfToday) {
                    predicates.append(NSPredicate(format: "date >= %@ AND date <= %@", monthAgo as NSDate, now as NSDate))
                }
            } else if selectedDateFilter == NSLocalizedString("week", comment: "1주일") {
                if let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) {
                    predicates.append(NSPredicate(format: "date >= %@ AND date <= %@", weekAgo as NSDate, now as NSDate))
                }
            } else if selectedDateFilter == NSLocalizedString("today", comment: "오늘") {
                predicates.append(NSPredicate(format: "date >= %@ AND date < %@", startOfToday as NSDate, calendar.date(byAdding: .day, value: 1, to: startOfToday)! as NSDate))
            } else if selectedDateFilter == NSLocalizedString("custom", comment: "직접 선택") {
                let safeStartDate = min(customStartDate, customEndDate)
                let safeEndDate = max(customStartDate, customEndDate)
                predicates.append(NSPredicate(format: "date >= %@ AND date <= %@", safeStartDate as NSDate, safeEndDate as NSDate))
            }
        }
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        do {
            return try viewContext.count(for: request)
        } catch {
            return 0
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            customBGColor.ignoresSafeArea()
            NavigationView {
                ZStack {
                    customBGColor.ignoresSafeArea()
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        VStack(spacing: 0) {
                            mainContent
                        }
                        // 카드 스타일(.background, .cornerRadius, .shadow 등) 모두 제거
                        // .background(
                        //     RoundedRectangle(cornerRadius: 22, style: .continuous)
                        //         .fill(customBGColor)
                        //         .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
                        // )
                        // .padding(.horizontal, 10)
                        // .padding(.top, 0)
                        // .padding(.bottom, 0)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .onAppear {
            fetchRecords()
            notifyStatisticsDataChanged()
            if let idx = allMonths.firstIndex(of: selectedMonth), !allMonths.isEmpty {
                selectedMonthIndex = idx
            } else {
                selectedMonthIndex = 0
                selectedMonth = allMonths.first ?? ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TestDataInserted"))) { _ in
            fetchRecords()
            notifyStatisticsDataChanged()
            // 테스트 데이터 저장 후 전체 Record 개수와 일부 데이터 콘솔 출력
            let request = Record.fetchRequest()
            do {
                let allRecords = try viewContext.fetch(request)
                print("✅ 전체 Record 개수: \(allRecords.count)")
                for record in allRecords.prefix(10) {
                    print("Record: \(record.id?.uuidString ?? "-"), 금액: \(record.amount), 날짜: \(record.date ?? Date()), 타입: \(record.type ?? "-")")
                }
                // 2025-02 데이터만 필터링해서 출력
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM"
                let filtered = allRecords.filter { record in
                    if let date = record.date {
                        return dateFormatter.string(from: date) == "2025-02"
                    }
                    return false
                }
                print("✅ 2025-02 Record 개수: \(filtered.count)")
                for record in filtered.prefix(10) {
                    print("[2025-02] Record: \(record.id?.uuidString ?? "-"), 금액: \(record.amount), 날짜: \(record.date ?? Date()), 타입: \(record.type ?? "-")")
                }
            } catch {
                print("❌ Record fetch 실패: \(error)")
            }
        }
        .onChange(of: selectedTypeFilter) {
            fetchRecords()
            notifyStatisticsDataChanged()
        }
        .onChange(of: selectedCategory) {
            fetchRecords()
            notifyStatisticsDataChanged()
        }
        .onChange(of: selectedDateFilter) {
            loadedMonthCount = 1
            fetchRecords()
            notifyStatisticsDataChanged()
        }
        .onChange(of: selectedPaymentType) {
            fetchRecords()
            notifyStatisticsDataChanged()
        }
        .sheet(isPresented: $isAddingNewRecord) {
            AddRecordView(onSave: {
                fetchRecords()
                notifyStatisticsDataChanged()
            })
        }
        .sheet(isPresented: $showFilterSheet) {
            let type = $selectedTypeFilter
            let category = $selectedCategory
            let date = $selectedDateFilter
            let start = $customStartDate
            let end = $customEndDate
            let incomeCategory = $selectedIncomeCategory
            let expenseCategory = $selectedExpenseCategory
            let allCategory = $selectedAllCategory
            let paymentType = $selectedPaymentType

            SearchFilterView(
                selectedType: type,
                selectedCategory: category,
                selectedDate: date,
                customStartDate: start,
                customEndDate: end,
                selectedIncomeCategory: incomeCategory,
                selectedExpenseCategory: expenseCategory,
                selectedAllCategory: allCategory,
                selectedPaymentType: paymentType,
                onReset: {
                    selectedTypeFilter = NSLocalizedString("all", comment: "")
                    selectedIncomeCategory = NSLocalizedString("all", comment: "")
                    selectedExpenseCategory = NSLocalizedString("all", comment: "")
                    selectedAllCategory = NSLocalizedString("all", comment: "")
                    selectedDateFilter = NSLocalizedString("month", comment: "한달")
                    customStartTimestamp = Date().timeIntervalSince1970
                    customEndTimestamp = Date().timeIntervalSince1970
                    selectedPaymentType = NSLocalizedString("all", comment: "전체")
                }
            )
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedRecord != nil },
            set: { if !$0 { selectedRecord = nil } }
        )) {
            if let record = selectedRecord {
                AddRecordView(recordToEdit: record)
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerBar
            filterSummarySection
            if !allMonths.isEmpty {
                HStack(spacing: 8) {
                    Button(action: { moveToPrevMonth() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18 * 0.7))
                            .foregroundColor(.white)
                            .padding(8 * 0.7)
                            .background(pastelAccentColor)
                            .clipShape(Circle())
                            .shadow(color: pastelAccentColor.opacity(0.12), radius: 3 * 0.7, x: 0, y: 1)
                    }
                    Menu {
                        ForEach(allMonths, id: \.self) { month in
                            Button(action: { selectedMonth = month }) {
                                Text(month)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedMonth)
                                .font(.system(size: 20 * 0.7, weight: .bold))
                                .foregroundColor(iconColor)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18 * 0.7))
                                .foregroundColor(iconColor)
                        }
                        .padding(.horizontal, 16 * 0.7)
                        .padding(.vertical, 8 * 0.7)
                        .background(colorScheme == .light ? Color.white.opacity(0.95) : Color(UIColor(hex: customDarkCardColorHex)).opacity(0.92))
                        .cornerRadius(12 * 0.7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12 * 0.7)
                                .stroke(colorScheme == .light ? borderColor : Color.white.opacity(0.18), lineWidth: 1.2 * 0.7)
                        )
                        .shadow(color: (colorScheme == .light ? borderColor.opacity(0.06) : Color.black.opacity(0.18)), radius: 2 * 0.7, x: 0, y: 1)
                        .foregroundColor(colorScheme == .light ? iconColor : Color.white)
                    }
                    Button(action: { moveToNextMonth() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18 * 0.7))
                            .foregroundColor(.white)
                            .padding(8 * 0.7)
                            .background(pastelAccentColor)
                            .clipShape(Circle())
                            .shadow(color: pastelAccentColor.opacity(0.12), radius: 3 * 0.7, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            Text("\(monthFilteredRecords.count)건")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
            Group {
                if monthFilteredRecords.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.secondary)
                        Text(NSLocalizedString("no_matching_records", comment: "해당 조건에 맞는 내역이 없습니다."))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                        Button(action: { isAddingNewRecord = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                Text(NSLocalizedString("add_new_entry", comment: "새 항목 추가"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color("HighlightColor"))
                            .clipShape(Capsule())
                            .shadow(radius: 4)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    RecordListSectionView(
                        records: monthFilteredRecords,
                        isNewDate: isNewDate,
                        displayDate: displayDate,
                        isTodayOrYesterday: isTodayOrYesterday,
                        recordRowView: { rec in
                            CompactRecordRowView(
                                record: rec,
                                onTap: { selectedRecord = rec },
                                colorForCategory: colorForCategory,
                                isIncome: isIncome,
                                customSectionColor: customSectionColor
                            )
                        },
                        selectedDateFilter: selectedDateFilter,
                        loadedMonthCount: $loadedMonthCount,
                        fetchRecords: fetchRecords,
                        customBGColor: customBGColor
                    )
                }
            }
            if isDeleteMode && !monthFilteredRecords.isEmpty {
                deleteButtons
            }
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            Button(action: {
                isDeleteMode.toggle()
                selectedRecords.removeAll()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colorScheme == .light ? Color(red: 0.95, green: 0.45, blue: 0.55) : Color(red: 1.0, green: 0.7, blue: 0.7))
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme == .light ? [Color(red: 1.0, green: 0.8, blue: 0.85), Color(red: 0.95, green: 0.7, blue: 0.8)] : [Color(red: 0.4, green: 0.2, blue: 0.3), Color(red: 0.6, green: 0.3, blue: 0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(red: 0.95, green: 0.45, blue: 0.55, opacity: 0.18), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isDeleteMode ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDeleteMode)

            Spacer()
            Text("myAcBook")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .light ? Color(red: 0.18, green: 0.32, blue: 0.55) : Color(red: 0.7, green: 0.8, blue: 1.0))
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

            Spacer()
            Button(action: {
                isAddingNewRecord = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colorScheme == .light ? Color(red: 0.45, green: 0.65, blue: 0.95) : Color(red: 0.7, green: 0.85, blue: 1.0))
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme == .light ? [Color(red: 0.8, green: 0.9, blue: 1.0), Color(red: 0.7, green: 0.85, blue: 1.0)] : [Color(red: 0.2, green: 0.3, blue: 0.4), Color(red: 0.3, green: 0.4, blue: 0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(red: 0.45, green: 0.65, blue: 0.95, opacity: 0.18), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isAddingNewRecord ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAddingNewRecord)
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 8)
    }

    private var filterSummarySection: some View {
        FilterSummaryView(
            selectedTypeFilter: selectedTypeFilter,
            selectedCategory: currentCategory,
            selectedDateFilter: selectedDateFilter,
            dateRangeText: "",
            onTap: { showFilterSheet = true },
            onReset: {
                selectedTypeFilter = NSLocalizedString("all", comment: "")
                selectedIncomeCategory = NSLocalizedString("all", comment: "")
                selectedExpenseCategory = NSLocalizedString("all", comment: "")
                selectedAllCategory = NSLocalizedString("all", comment: "")
                selectedDateFilter = NSLocalizedString("month", comment: "한달")
                customStartTimestamp = Date().timeIntervalSince1970
                customEndTimestamp = Date().timeIntervalSince1970
                selectedPaymentType = NSLocalizedString("all", comment: "전체")
            },
            selectedPaymentType: selectedPaymentType
        )
        .padding(.horizontal, 0)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    private var deleteButtons: some View {
        HStack(spacing: 16) {
            Spacer()
            Button(action: {
                showingDeleteAlert = true
            }) {
                Text("전체 삭제")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(colorScheme == .light ? Color(red: 0.95, green: 0.45, blue: 0.55) : Color(red: 1.0, green: 0.7, blue: 0.7))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme == .light ? [Color(red: 1.0, green: 0.8, blue: 0.85), Color(red: 0.95, green: 0.7, blue: 0.8)] : [Color(red: 0.4, green: 0.2, blue: 0.3), Color(red: 0.6, green: 0.3, blue: 0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0.95, green: 0.45, blue: 0.55, opacity: 0.18), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("정말 현재 화면의 모든 내역을 삭제하시겠습니까?"),
                    message: Text("현재 화면에 보이는 내역 \(monthFilteredRecords.count)건을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
                    primaryButton: .destructive(Text("전체 삭제")) {
                        withAnimation {
                            for record in monthFilteredRecords {
                                viewContext.delete(record)
                            }
                            do {
                                try viewContext.save()
                            } catch {
                                // 에러 처리 (필요시)
                            }
                            fetchRecords()
                            notifyStatisticsDataChanged()
                            selectedRecords.removeAll()
                            isDeleteMode = false
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            Button(action: {
                withAnimation {
                    for record in selectedRecords {
                        viewContext.delete(record)
                    }
                    selectedRecords.removeAll()
                    try? viewContext.save()
                    fetchRecords()
                    notifyStatisticsDataChanged()
                    isDeleteMode = false
                }
            }) {
                Text("선택 삭제 (\(selectedRecords.count))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(colorScheme == .light ? Color(red: 0.45, green: 0.65, blue: 0.95) : Color(red: 0.7, green: 0.85, blue: 1.0))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme == .light ? [Color(red: 0.8, green: 0.9, blue: 1.0), Color(red: 0.7, green: 0.85, blue: 1.0)] : [Color(red: 0.2, green: 0.3, blue: 0.4), Color(red: 0.3, green: 0.4, blue: 0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0.45, green: 0.65, blue: 0.95, opacity: 0.18), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
    }

    // MARK: - View Builders
    @ViewBuilder
    private func recordRowView(record: Record) -> some View {
        CompactRecordRowView(
            record: record,
            onTap: { selectedRecord = record },
            colorForCategory: colorForCategory,
            isIncome: isIncome,
            customSectionColor: customSectionColor
        )
    }

    // 카테고리별 아이콘 매핑 함수
    private func iconForCategory(_ name: String?) -> String {
        switch name {
        case "식대": return "fork.knife"
        case "음료": return "cup.and.saucer"
        case "교통": return "car"
        case "부수입": return "gift"
        case "급여": return "dollarsign.circle"
        case "쿠팡33": return "creditcard"
        case "food": return "takeoutbag.and.cup.and.straw"
        case "salary": return "banknote"
        case "side_income": return "giftcard"
        case "beverage": return "cup.and.saucer"
        default: return "tag"
        }
    }

    // 카테고리별 컬러 매핑 함수
    private func colorForCategory(_ name: String?) -> Color {
        // 1. AppCategory에서 colorHex 우선 적용
        if let name = name {
            let fetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
            fetch.predicate = NSPredicate(format: "name == %@", name)
            if let cat = try? viewContext.fetch(fetch).first, let hex = cat.colorHex, !hex.isEmpty {
                return Color(UIColor(hex: hex))
            }
        }
        // 2. fallback: 기존 하드코딩 색상
        switch name {
        case "식대": return .pink
        case "음료": return .blue
        case "교통": return .green
        case "부수입": return .purple
        case "급여": return .orange
        case "쿠팡33": return .yellow
        case "food": return .brown
        case "salary": return .mint
        case "side_income": return .purple
        case "beverage": return .blue
        default: return .gray
        }
    }

    // 수입/지출 판별 함수
    private func isIncome(_ record: Record) -> Bool {
        return record.type == NSLocalizedString("income", comment: "수입") || record.type == "수입"
    }

    // MARK: - Helpers
    private func formattedAmount(_ amount: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.groupingSeparator = ","
        return numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    private func toggleSelection(for record: Record) {
        if selectedRecords.contains(record) {
            selectedRecords.remove(record)
        } else {
            selectedRecords.insert(record)
        }
    }
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: date)
    }
    private func dateRangeText() -> String {
        let calendar = Calendar.current
        let now = Date()
        switch selectedDateFilter {
        case NSLocalizedString("today", comment: ""):
            return formatDateShort(now)
        case NSLocalizedString("yesterday", comment: ""):
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                return formatDateShort(yesterday)
            }
        case NSLocalizedString("week", comment: ""):
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                return "\(formatDateShort(weekAgo)) ~ \(formatDateShort(now))"
            }
        case NSLocalizedString("month", comment: ""):
            if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) {
                return "\(formatDateShort(monthAgo)) ~ \(formatDateShort(now))"
            }
        case NSLocalizedString("custom", comment: ""):
            let sortedDates = [customStartDate, customEndDate].sorted()
            return "\(formatDateShort(sortedDates[0])) ~ \(formatDateShort(sortedDates[1]))"
        default:
            return selectedDateFilter
        }
        return selectedDateFilter
    }
    private var formatDateShort: (Date) -> String {
        { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
    private func notifyStatisticsDataChanged() {
        onStatisticsDataChanged?(
            monthlyIncomeTotals,
            monthlyExpenseTotals,
            monthlyCategoryIncomeTotals,
            monthlyCategoryExpenseTotals,
            monthlyCardExpenseTotals,
            selectedTypeFilter,
            currentCategory,
            selectedDateFilter,
            dateRangeText(),
            monthlyCashExpenseTotals
        )
    }
    private var monthlyIncomeTotals: [String: Double] {
        var totals = [String: Double]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        for record in records where record.type == NSLocalizedString("income", comment: "") {
            let month = dateFormatter.string(from: record.date ?? Date())
            totals[month, default: 0] += record.amount
        }
        return totals
    }
    private var monthlyExpenseTotals: [String: Double] {
        var totals = [String: Double]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        for record in records where record.type != NSLocalizedString("income", comment: "") {
            let month = dateFormatter.string(from: record.date ?? Date())
            totals[month, default: 0] += record.amount
        }
        return totals
    }
    private var monthlyCategoryExpenseTotals: [String: [String: Double]] {
        var totals = [String: [String: Double]]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        for record in records where record.type != NSLocalizedString("income", comment: "") {
            let month = dateFormatter.string(from: record.date ?? Date())
            let categoryKey = record.categoryRelation?.name ?? "etc"
            totals[month, default: [:]][categoryKey, default: 0] += record.amount
        }
        return totals
    }
    private var monthlyCategoryIncomeTotals: [String: [String: Double]] {
        var totals = [String: [String: Double]]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        for record in records where record.type == NSLocalizedString("income", comment: "") {
            let month = dateFormatter.string(from: record.date ?? Date())
            let categoryKey = record.categoryRelation?.name ?? "etc"
            totals[month, default: [:]][categoryKey, default: 0] += record.amount
        }
        return totals
    }
    private var monthlyCardExpenseTotals: [String: [String: Double]] {
        var totals = [String: [String: Double]]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        for record in records where record.type == NSLocalizedString("expense", comment: "") && record.paymentType == NSLocalizedString("card", comment: "") {
            let month = dateFormatter.string(from: record.date ?? Date())
            let cardName = record.card?.name ?? "알 수 없음"
            totals[month, default: [:]][cardName, default: 0] += record.amount
        }
        return totals
    }
    private var monthlyCashExpenseTotals: [String: Double] {
        var totals = [String: Double]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        for record in records where record.type == NSLocalizedString("expense", comment: "") && record.paymentType == NSLocalizedString("cash", comment: "현금") {
            let month = dateFormatter.string(from: record.date ?? Date())
            totals[month, default: 0] += record.amount
        }
        return totals
    }

    // 날짜가 바뀔 때마다 true를 반환하는 유틸
    private func isNewDate(_ record: Record, _ previousRecord: Record?) -> Bool {
        guard let date1 = record.date else { return false }
        guard let date2 = previousRecord?.date else { return true }
        let calendar = Calendar.current
        return !calendar.isDate(date1, inSameDayAs: date2)
    }

    // 날짜 포맷 함수 (오늘/어제 한글, 나머지 yyyy/M/d)
    private func displayDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "오늘" }
        if calendar.isDateInYesterday(date) { return "어제" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: date)
    }

    private func isTodayOrYesterday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(date) || calendar.isDateInYesterday(date)
    }

    static func makeFetchRequest(selectedDateFilter: String?) -> NSFetchRequest<Record> {
        let request = Record.fetchRequest()
        let calendar = Calendar.current
        var predicate: NSPredicate? = nil
        if let filter = selectedDateFilter, filter != NSLocalizedString("all", comment: "") {
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            switch filter {
            case NSLocalizedString("today", comment: ""):
                predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfToday as NSDate, calendar.date(byAdding: .day, value: 1, to: startOfToday)! as NSDate)
            case NSLocalizedString("week", comment: ""):
                if let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) {
                    predicate = NSPredicate(format: "date >= %@ AND date <= %@", weekAgo as NSDate, now as NSDate)
                }
            case NSLocalizedString("month", comment: ""):
                if let monthAgo = calendar.date(byAdding: .month, value: -1, to: startOfToday) {
                    predicate = NSPredicate(format: "date >= %@ AND date <= %@", monthAgo as NSDate, now as NSDate)
                }
            case NSLocalizedString("custom", comment: ""):
                let customStart = UserDefaults.standard.double(forKey: "customStartDate")
                let customEnd = UserDefaults.standard.double(forKey: "customEndDate")
                let start = Date(timeIntervalSince1970: min(customStart, customEnd))
                let end = Date(timeIntervalSince1970: max(customStart, customEnd))
                predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, end as NSDate)
            default:
                break
            }
        }
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Record.date, ascending: false)]
        request.fetchBatchSize = 50
        return request
    }

    // 카테고리별 컬러 포인트 함수
    private func categoryColor(_ category: String?) -> Color {
        // 1. AppCategory에서 colorHex 우선 적용
        if let name = category {
            let fetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
            fetch.predicate = NSPredicate(format: "name == %@", name)
            if let cat = try? viewContext.fetch(fetch).first, let hex = cat.colorHex, !hex.isEmpty {
                return Color(UIColor(hex: hex)).opacity(0.7)
            }
        }
        // 2. fallback: 기존 하드코딩 색상
        switch category {
        case "식대": return Color.pink.opacity(0.7)
        case "음료": return Color.blue.opacity(0.5)
        case "교통": return Color.green.opacity(0.5)
        case "부수입": return Color.purple.opacity(0.5)
        default: return Color.gray.opacity(0.3)
        }
    }

    private var monthFilteredRecords: [Record] {
        if selectedMonth.isEmpty {
            return filteredRecords
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            return filteredRecords.filter { record in
                guard let date = record.date else { return false }
                return dateFormatter.string(from: date) == selectedMonth
            }
        }
    }

    private func moveToPrevMonth() {
        if let idx = allMonths.firstIndex(of: selectedMonth), idx < allMonths.count - 1 {
            selectedMonth = allMonths[idx + 1]
        }
    }

    private func moveToNextMonth() {
        if let idx = allMonths.firstIndex(of: selectedMonth), idx > 0 {
            selectedMonth = allMonths[idx - 1]
        }
    }
}

struct BannerAdContainerView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    var body: some View {
        Group {
            if !purchaseManager.isAdRemoved {
                BannerAdView()
            } else {
                EmptyView()
            }
        }
    }
}

let pastelAccentColor = Color(red: 1.0, green: 0.7, blue: 0.8) // 연한 파스텔 핑크
let borderColor = Color(red: 0.95, green: 0.75, blue: 0.8) // 더 연한 핑크
let iconColor = Color(red: 0.8, green: 0.5, blue: 0.6) // 톤다운 핑크

// MARK: - CompactRecordRowView: 가계부 스타일의 레코드 행 뷰
struct CompactRecordRowView: View {
    let record: Record
    let onTap: (() -> Void)?
    let colorForCategory: (String?) -> Color
    let isIncome: (Record) -> Bool
    let customSectionColor: Color // 추가
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    var customCardColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightCardColorHex)) : Color(UIColor(hex: customDarkCardColorHex))
    }
    var body: some View {
        HStack(spacing: 0) {
            Text(record.paymentType ?? "-")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill((record.paymentType == "카드") ? Color.blue.opacity(0.7) : Color.green.opacity(0.7))
                )
                .frame(width: 56, alignment: .center)
            Text(record.categoryRelation?.name ?? "-")
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? colorForCategory(record.categoryRelation?.name).opacity(0.95) : colorForCategory(record.categoryRelation?.name))
                .frame(width: 70, alignment: .leading)
            Text(record.detail?.isEmpty == false ? record.detail! : "-")
                .font(.footnote)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(5)
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.92) : .primary)
            Text(record.amount > 0 ? "\(record.amount, specifier: "%.0f")" : "-")
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? (isIncome(record) ? Color.cyan : Color.pink) : (isIncome(record) ? Color.blue : Color.red))
                .frame(width: 70, alignment: .trailing)
                .padding(.trailing, 2)
        }
        .frame(height: 29)
        .padding(.vertical, 0)
        .padding(.horizontal, 0)
        .background(customSectionColor)
        .font(.system(size: 10))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

struct RecordRowSectionView: View {
    let record: Record
    let showDateLabel: Bool
    let displayDate: (Date?) -> String
    let isTodayOrYesterday: (Date?) -> Bool
    let recordRowView: (Record) -> CompactRecordRowView

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showDateLabel {
                Text(displayDate(record.date))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isTodayOrYesterday(record.date) ? .accentColor : .secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    .padding(.leading, 4)
                recordRowView(record)
                    .padding(.bottom, 2)
                    .padding(.leading, 4)
                    .padding(.trailing, 4)
            } else {
                Color.clear
                    .frame(height: 20) // 날짜 라벨 높이와 맞춤
                recordRowView(record)
                    .padding(.bottom, 2)
                    .padding(.leading, 4)
                    .padding(.trailing, 4)
            }
        }
    }
}

struct RecordListSectionView: View {
    let records: [Record]
    let isNewDate: (Record, Record?) -> Bool
    let displayDate: (Date?) -> String
    let isTodayOrYesterday: (Date?) -> Bool
    let recordRowView: (Record) -> CompactRecordRowView
    let selectedDateFilter: String
    @Binding var loadedMonthCount: Int
    let fetchRecords: () -> Void
    let customBGColor: Color

    // 날짜별 그룹핑
    private var groupedRecordsByDate: [Date: [Record]] {
        let calendar = Calendar.current
        return Dictionary(grouping: records) { record in
            guard let date = record.date else { return Date.distantPast }
            return calendar.startOfDay(for: date)
        }
    }
    private var sortedRecordDates: [Date] {
        groupedRecordsByDate.keys.sorted(by: >)
    }

    var body: some View {
        List {
            ForEach(sortedRecordDates, id: \.self) { date in
                Section(header:
                    Text(displayDate(date))
                        .font(.headline)
                        .padding(.vertical, 4)
                ) {
                    ForEach(groupedRecordsByDate[date] ?? [], id: \ .objectID) { record in
                        recordRowView(record)
                            .onAppear {
                                if selectedDateFilter == NSLocalizedString("all", comment: "") && record == records.last {
                                    loadedMonthCount += 1
                                    fetchRecords()
                                }
                            }
                            .listRowSeparator(.visible)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(0)
        .background(Color.clear)
        .scrollContentBackground(.hidden)
    }
}

#if DEBUG
import CoreData

class DummyIAPManager: ObservableObject {}

struct ContentView_LivePreview: View {
    @State private var listPadding: CGFloat = 0

    var body: some View {
        VStack {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(IAPManager())
                .padding(.horizontal, listPadding)
            VStack {
                Text("List Padding: \(Int(listPadding))")
                Slider(value: $listPadding, in: 0...40)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct ContentView_LivePreview_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_LivePreview()
            .previewDevice("iPhone 16 Pro")
    }
}
#endif

