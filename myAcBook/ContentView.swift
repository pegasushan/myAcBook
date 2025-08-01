import SwiftUI
import Charts
import GoogleMobileAds
import CoreData
import UIKit

// Date 확장: startOfDay 프로퍼티 추가
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

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
    @EnvironmentObject var purchaseManager: PurchaseManager
    @AppStorage("colorScheme") private var colorSchemeSetting: String = "system"
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("isAdRemoved") private var isAdRemoved: Bool = false

    @State private var selectedRecords = Set<NSManagedObjectID>()
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
    // 달력 팝업용 상태 변수 추가
    @State private var showDatePicker: Bool = false
    @State private var calendarSelectedDate: Date = Date()
    @State private var selectedDay: String = ""
    @State private var selectedMonth: String = "2025-07"
    @State private var newRecordDate: Date? = nil

    // 페이징 관련 상태
    @State private var loadedMonthCount: Int = 1
    @State private var records: [Record] = []
    // @State private var selectedMonth: String = "2025-07" // 중복 제거

    // MARK: - Date Filter Mode
    enum DateFilterMode: String, CaseIterable, Identifiable {
        case month = "월별"
        case day = "일별"
        var id: String { self.rawValue }
    }
    @State private var dateFilterMode: DateFilterMode = .month

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
    @State private var selectedDayIndex: Int = 0
    // 추가: 임시 달력 선택 날짜 및 인덱스 변수
    @State private var tempCalendarSelectedDate: Date = Date()
    @State private var tempSelectedDayIndex: Int = 0

    private var monthOptions: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let now = Date()
        return (0..<36).map { offset in
            let date = Calendar.current.date(byAdding: .month, value: -offset, to: now)!
            return formatter.string(from: date)
        }
    }
    private var dayOptions: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd (E)"
        let days: Set<Date> = Set(filteredRecords.compactMap { $0.date?.startOfDay })
        return days.sorted(by: >).map { formatter.string(from: $0) }
    }

    private var displayedRecords: [Record] {
        if dateFilterMode == .month {
            let monthString: String
            if selectedMonthIndex == -1 {
                monthString = selectedMonth
            } else {
                monthString = monthOptions.indices.contains(selectedMonthIndex) ? monthOptions[selectedMonthIndex] : monthOptions.first ?? ""
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return filteredRecords.filter { record in
                guard let date = record.date else { return false }
                return formatter.string(from: date) == monthString
            }
        } else {
            let dayString: String
            if selectedDayIndex == -1 {
                dayString = selectedDay
            } else {
                dayString = dayOptions.indices.contains(selectedDayIndex) ? dayOptions[selectedDayIndex] : dayOptions.first ?? ""
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd (E)"
            return filteredRecords.filter { record in
                guard let date = record.date else { return false }
                return formatter.string(from: date) == dayString
            }
        }
    }

    // 1. 날짜별 수입/지출 딕셔너리 computed property 추가 (State/Computed property 선언부 근처)
    private var incomeExpenseByDate: [Date: (income: Double, expense: Double)] {
        let calendar = Calendar.current
        var dict: [Date: (income: Double, expense: Double)] = [:]
        for record in filteredRecords {
            guard let date = record.date else { continue }
            let day = calendar.startOfDay(for: date)
            let isIncome = record.type == NSLocalizedString("income", comment: "수입") || record.type == "수입"
            if isIncome {
                dict[day, default: (0,0)].income += record.amount
            } else {
                dict[day, default: (0,0)].expense += record.amount
            }
        }
        return dict
    }

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
            AppColors.background.ignoresSafeArea()
            NavigationView {
                ZStack {
                    AppColors.background.ignoresSafeArea()
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
                    // 달력 오버레이
                    // 기존 오버레이 코드 제거
                    // if showDatePicker {
                    //     Color.black.opacity(0.3)
                    //         .ignoresSafeArea()
                    //         .onTapGesture { showDatePicker = false }
                    //     VStack {
                    //         Spacer()
                    //         CustomCalendarView(
                    //             selectedDate: $calendarSelectedDate,
                    //             incomeExpenseByDate: incomeExpenseByDate,
                    //             onConfirm: {
                    //                 if dateFilterMode == .month {
                    //                     let formatter = DateFormatter()
                    //                     formatter.dateFormat = "yyyy-MM"
                    //                     let selectedMonthStr = formatter.string(from: calendarSelectedDate)
                    //                     if let idx = monthOptions.firstIndex(of: selectedMonthStr) {
                    //                         selectedMonthIndex = idx
                    //                     } else {
                    //                         selectedMonth = selectedMonthStr
                    //                         selectedMonthIndex = -1
                    //                     }
                    //                 } else {
                    //                     let formatter = DateFormatter()
                    //                     formatter.dateFormat = "yyyy-MM-dd (E)"
                    //                     let selectedDayStr = formatter.string(from: calendarSelectedDate)
                    //                     if let idx = dayOptions.firstIndex(of: selectedDayStr) {
                    //                         selectedDayIndex = idx
                    //                     } else {
                    //                         selectedDay = selectedDayStr
                    //                         selectedDayIndex = -1
                    //                     }
                    //                 }
                    //                 showDatePicker = false
                    //             },
                    //             onToday: { calendarSelectedDate = Date() }
                    //         )
                    //         .background(Color.white)
                    //         .cornerRadius(18, corners: [.topLeft, .topRight])
                    //         .frame(maxWidth: .infinity)
                    //         .frame(height: 440)
                    //         .shadow(radius: 10)
                    //     }
                    // }
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
            if selectedDay.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd (E)"
                selectedDay = formatter.string(from: initialDate)
            }
            if selectedMonth.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                selectedMonth = formatter.string(from: initialDate)
            }
            calendarSelectedDate = initialDate
            tempCalendarSelectedDate = initialDate
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
        .onChange(of: dateFilterMode) {
            if !showDatePicker {
                if dateFilterMode == .month {
                    selectedMonthIndex = 0
                } else {
                    selectedDayIndex = 0
                }
            }
        }
        .onChange(of: monthOptions) {
            if selectedMonthIndex >= monthOptions.count {
                selectedMonthIndex = 0
            }
        }
        .onChange(of: dayOptions) {
            if !showDatePicker {
                if selectedDayIndex >= dayOptions.count {
                    selectedDayIndex = 0
                }
            }
        }
        // 새 항목 추가 버튼 클릭 시
        .onChange(of: isAddingNewRecord) {
            if isAddingNewRecord {
                newRecordDate = calendarSelectedDate
            }
        }
        .sheet(isPresented: $isAddingNewRecord) {
            AddRecordView(defaultDate: newRecordDate ?? calendarSelectedDate)
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
        // 달력 sheet 팝업 추가
        .sheet(isPresented: $showDatePicker) {
            if dateFilterMode == .month {
                MonthPickerView(
                    selectedMonth: $calendarSelectedDate,
                    onConfirm: {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM"
                        let selectedMonthStr = formatter.string(from: calendarSelectedDate)
                        if let idx = monthOptions.firstIndex(of: selectedMonthStr) {
                            selectedMonthIndex = idx
                        } else {
                            selectedMonthIndex = -1
                        }
                        selectedMonth = selectedMonthStr
                        showDatePicker = false
                    }
                )
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.hidden)
            } else if dateFilterMode == .day {
                VStack(spacing: 0) {
                    CustomCalendarView(
                        selectedDate: $tempCalendarSelectedDate,
                        incomeExpenseByDate: incomeExpenseByDate,
                        onConfirm: {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd (E)"
                            let selectedDayStr = formatter.string(from: tempCalendarSelectedDate)
                            selectedDay = selectedDayStr
                            selectedDayIndex = -1
                            calendarSelectedDate = tempCalendarSelectedDate
                            showDatePicker = false
                        },
                        onToday: { tempCalendarSelectedDate = Date() }
                    )
                    .background(Color.white)
                    .cornerRadius(18, corners: [.topLeft, .topRight])
                    .frame(maxWidth: .infinity)
                    .frame(height: 484)
                }
                .presentationDetents([.height(528)])
                .presentationDragIndicator(.hidden)
            }
        }
    }

    private var mainContent: some View {
        // ViewBuilder 바깥에서 미리 계산
        let dayString: String = {
            if selectedDayIndex == -1 {
                return selectedDay
            } else if dayOptions.indices.contains(selectedDayIndex) {
                return dayOptions[selectedDayIndex]
            } else {
                return dayOptions.first ?? ""
            }
        }()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd (E)"
        let recordsForDay = filteredRecords.filter { record in
            guard let date = record.date else { return false }
            return formatter.string(from: date) == dayString
        }
        return VStack(spacing: 0) {
            headerBarSection
            filterSummarySectionView
            dateSelectionBar
            Text("\(displayedRecords.count)건")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
            // 리스트만 분기
            if dateFilterMode == .month {
                Group {
                    if displayedRecords.isEmpty {
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
                            records: displayedRecords,
                            isNewDate: isNewDate,
                            displayDate: displayDate,
                            isTodayOrYesterday: isTodayOrYesterday,
                            recordRowView: { rec in
                                AnyView(
                                    UnifiedRecordRowView(
                                        record: rec,
                                        isDeleteMode: isDeleteMode,
                                        selected: selectedRecords.contains(rec.objectID),
                                        onSelect: {
                                            if selectedRecords.contains(rec.objectID) {
                                                selectedRecords.remove(rec.objectID)
                                            } else {
                                                selectedRecords.insert(rec.objectID)
                                            }
                                        },
                                        onTap: {
                                            selectedRecord = rec
                                        },
                                        colorForCategory: colorForCategory,
                                        isIncome: isIncome,
                                        customSectionColor: AppColors.section,
                                        customBGColor: AppColors.background
                                    )
                                )
                            },
                            selectedDateFilter: selectedDateFilter,
                            loadedMonthCount: $loadedMonthCount,
                            fetchRecords: fetchRecords,
                            customBGColor: AppColors.background
                        )
                    }
                }
            } else {
                Group {
                    if recordsForDay.isEmpty {
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
                            records: recordsForDay,
                            isNewDate: isNewDate,
                            displayDate: displayDate,
                            isTodayOrYesterday: isTodayOrYesterday,
                            recordRowView: { rec in
                                AnyView(
                                    UnifiedRecordRowView(
                                        record: rec,
                                        isDeleteMode: isDeleteMode,
                                        selected: selectedRecords.contains(rec.objectID),
                                        onSelect: {
                                            if selectedRecords.contains(rec.objectID) {
                                                selectedRecords.remove(rec.objectID)
                                            } else {
                                                selectedRecords.insert(rec.objectID)
                                            }
                                        },
                                        onTap: {
                                            selectedRecord = rec
                                        },
                                        colorForCategory: colorForCategory,
                                        isIncome: isIncome,
                                        customSectionColor: AppColors.section,
                                        customBGColor: AppColors.background
                                    )
                                )
                            },
                            selectedDateFilter: selectedDateFilter,
                            loadedMonthCount: $loadedMonthCount,
                            fetchRecords: fetchRecords,
                            customBGColor: AppColors.background
                        )
                    }
                }
            }
            if isDeleteMode && !displayedRecords.isEmpty {
                deleteButtons
            }
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var headerBarSection: some View {
        headerBar
    }

    private var filterSummarySectionView: some View {
        filterSummarySection
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
            Text(NSLocalizedString("main_title", comment: "메인 타이틀"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .light ? Color(red: 0.18, green: 0.32, blue: 0.55) : Color(red: 0.7, green: 0.8, blue: 1.0))
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

            Spacer()
            Button(action: {
                newRecordDate = calendarSelectedDate
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
                let deleteCount: Int = {
                    if dateFilterMode == .month {
                        return monthFilteredRecords.count
                    } else {
                        let dayString = dayOptions.indices.contains(selectedDayIndex) ? dayOptions[selectedDayIndex] : ""
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd (E)"
                        let recordsForDay = filteredRecords.filter { record in
                            guard let date = record.date else { return false }
                            return formatter.string(from: date) == dayString
                        }
                        return recordsForDay.count
                    }
                }()
                return Alert(
                    title: Text("정말 현재 화면의 모든 내역을 삭제하시겠습니까?"),
                    message: Text("현재 화면에 보이는 내역 \(deleteCount)건을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
                    primaryButton: .destructive(Text("전체 삭제")) {
                        withAnimation {
                            if dateFilterMode == .month {
                                for record in monthFilteredRecords {
                                    viewContext.delete(record)
                                }
                            } else {
                                let dayString = dayOptions.indices.contains(selectedDayIndex) ? dayOptions[selectedDayIndex] : ""
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd (E)"
                                let recordsForDay = filteredRecords.filter { record in
                                    guard let date = record.date else { return false }
                                    return formatter.string(from: date) == dayString
                                }
                                for record in recordsForDay {
                                    viewContext.delete(record)
                                }
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
                        if let record = try? viewContext.existingObject(with: record) as? Record {
                            viewContext.delete(record)
                        }
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
            customSectionColor: AppColors.section,
            customBGColor: AppColors.background
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
        if selectedRecords.contains(record.objectID) {
            selectedRecords.remove(record.objectID)
        } else {
            selectedRecords.insert(record.objectID)
        }
    }
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
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
        let incomeTypes = ["수입", "income", NSLocalizedString("income", comment: "수입")]
        for record in records where incomeTypes.contains(record.type ?? "") {
            let month = dateFormatter.string(from: record.date ?? Date())
            totals[month, default: 0] += record.amount
        }
        return totals
    }
    private var monthlyExpenseTotals: [String: Double] {
        var totals = [String: Double]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let incomeTypes = ["수입", "income", NSLocalizedString("income", comment: "수입")]
        for record in records where !(incomeTypes.contains(record.type ?? "")) {
            let month = dateFormatter.string(from: record.date ?? Date())
            totals[month, default: 0] += record.amount
        }
        return totals
    }
    private var monthlyCategoryExpenseTotals: [String: [String: Double]] {
        var totals = [String: [String: Double]]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let incomeTypes = ["수입", "income", NSLocalizedString("income", comment: "수입")]
        for record in records where !(incomeTypes.contains(record.type ?? "")) {
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
        let incomeTypes = ["수입", "income", NSLocalizedString("income", comment: "수입")]
        for record in records where incomeTypes.contains(record.type ?? "") {
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
        let expenseTypes = ["지출", "expense", NSLocalizedString("expense", comment: "지출")]
        let cardTypes = ["카드", "card", NSLocalizedString("card", comment: "카드")]
        for record in records where expenseTypes.contains(record.type ?? "") && cardTypes.contains(record.paymentType ?? "") {
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
        let formatter = DateFormatter()
        formatter.dateFormat = "(E)"
        let weekday = formatter.string(from: date)
        if calendar.isDateInToday(date) { return "오늘 " + weekday }
        if calendar.isDateInYesterday(date) { return "어제 " + weekday }
        formatter.dateFormat = "MM-dd (E)"
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

    private func deleteSelectedRecords() {
        for id in selectedRecords {
            if let record = try? viewContext.existingObject(with: id) as? Record {
                viewContext.delete(record)
            }
        }
        do {
            try viewContext.save()
            selectedRecords.removeAll()
            isDeleteMode = false
            fetchRecords()
        } catch {
            // 에러 처리
        }
    }

    private var dateSelectionBar: some View {
        HStack(spacing: 12) {
            dateFilterPicker
            monthOrDaySelector
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
        .padding(.bottom, 8)
    }

    private var dateFilterPicker: some View {
        Picker("그룹핑", selection: $dateFilterMode) {
            ForEach(DateFilterMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 120)
    }

    private var monthOrDaySelector: some View {
        Group {
            if dateFilterMode == .month {
                monthSelector
            } else if dateFilterMode == .day {
                daySelector
            } else {
                EmptyView()
            }
        }
    }

    private var monthSelector: some View {
        HStack(spacing: 8) {
            Button(action: {
                // 현재 선택된 월을 Date로 변환해서 calendarSelectedDate에 세팅
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                let monthString: String
                if selectedMonthIndex == -1 {
                    monthString = selectedMonth
                } else if monthOptions.indices.contains(selectedMonthIndex) {
                    monthString = monthOptions[selectedMonthIndex]
                } else {
                    monthString = formatter.string(from: Date())
                }
                if let date = formatter.date(from: monthString) {
                    calendarSelectedDate = date
                } else {
                    calendarSelectedDate = Date()
                }
                showDatePicker = true
            }) {
                Text(
                    selectedMonthIndex == -1
                        ? selectedMonth
                        : (monthOptions.indices.contains(selectedMonthIndex) ? monthOptions[selectedMonthIndex] : "")
                )
                .font(.system(size: 20 * 0.7, weight: .bold))
                .fixedSize()
                .frame(minWidth: 120, alignment: .center)
                .foregroundColor(iconColor)
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
            Button(action: {
                if selectedMonthIndex < monthOptions.count - 1 {
                    selectedMonthIndex += 1
                    selectedMonth = monthOptions[selectedMonthIndex] // 동기화
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18 * 0.7))
                    .foregroundColor(selectedMonthIndex < monthOptions.count - 1 ? .primary : .gray)
            }
            .padding(.leading, 4)
            Button(action: {
                if selectedMonthIndex > 0 {
                    selectedMonthIndex -= 1
                    selectedMonth = monthOptions[selectedMonthIndex] // 동기화
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18 * 0.7))
                    .foregroundColor(selectedMonthIndex > 0 ? .primary : .gray)
            }
            .padding(.leading, 4)
        }
    }

    private var daySelector: some View {
        HStack(spacing: 8) {
            Button(action: {
                // 선택된 날짜가 있으면 그 날짜로, 없으면 dayOptions에서 fallback
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dayString: String
                if selectedDayIndex == -1 {
                    if !selectedDay.isEmpty {
                        dayString = String(selectedDay.prefix(10))
                    } else if let first = dayOptions.first {
                        dayString = String(first.prefix(10))
                    } else {
                        dayString = formatter.string(from: Date())
                    }
                } else if dayOptions.indices.contains(selectedDayIndex) {
                    dayString = String(dayOptions[selectedDayIndex].prefix(10))
                } else {
                    dayString = formatter.string(from: Date())
                }
                if let date = formatter.date(from: dayString) {
                    tempCalendarSelectedDate = date
                } else {
                    tempCalendarSelectedDate = Date()
                }
                showDatePicker = true
            }) {
                Text(
                    selectedDayIndex == -1
                        ? selectedDay
                        : (dayOptions.indices.contains(selectedDayIndex) ? dayOptions[selectedDayIndex] : "")
                )
                .font(.system(size: 20 * 0.7, weight: .bold))
                .fixedSize()
                .frame(minWidth: 120, alignment: .center)
                .foregroundColor(iconColor)
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
            Button(action: {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd (E)"
                let currentDate: Date
                if selectedDayIndex == -1, !selectedDay.isEmpty {
                    currentDate = formatter.date(from: selectedDay) ?? Date()
                } else if dayOptions.indices.contains(selectedDayIndex) {
                    currentDate = formatter.date(from: dayOptions[selectedDayIndex]) ?? Date()
                } else {
                    currentDate = Date()
                }
                // 하루 전 날짜
                if let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                    let prevString = formatter.string(from: prevDate)
                    if let idx = dayOptions.firstIndex(of: prevString) {
                        selectedDayIndex = idx
                        selectedDay = dayOptions[idx]
                    } else {
                        selectedDay = prevString
                        selectedDayIndex = -1
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18 * 0.7))
                    .foregroundColor(selectedDayIndex > 0 ? .primary : .gray)
            }
            .padding(.leading, 4)
            Button(action: {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd (E)"
                let currentDate: Date
                if selectedDayIndex == -1, !selectedDay.isEmpty {
                    currentDate = formatter.date(from: selectedDay) ?? Date()
                } else if dayOptions.indices.contains(selectedDayIndex) {
                    currentDate = formatter.date(from: dayOptions[selectedDayIndex]) ?? Date()
                } else {
                    currentDate = Date()
                }
                // 하루 후 날짜
                if let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
                    let nextString = formatter.string(from: nextDate)
                    if let idx = dayOptions.firstIndex(of: nextString) {
                        selectedDayIndex = idx
                        selectedDay = dayOptions[idx]
                    } else {
                        selectedDay = nextString
                        selectedDayIndex = -1
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18 * 0.7))
                    .foregroundColor(selectedDayIndex < dayOptions.count - 1 ? .primary : .gray)
            }
            .padding(.leading, 4)
        }
    }

    // 원하는 최초 날짜를 ContentView 스코프 내에 명확히 선언
    private let initialDate: Date = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: "2025-07-15") ?? Date()
    }()
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
    let customBGColor: Color // 추가
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    var customCardColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightCardColorHex)) : Color(UIColor(hex: customDarkCardColorHex))
    }
    var body: some View {
        let paymentType = (record.paymentType ?? "").lowercased()
        let isCard = (paymentType == "카드" || paymentType == "card" || paymentType == NSLocalizedString("card", comment: "카드").lowercased())
        let isCash = (paymentType == "현금" || paymentType == "cash" || paymentType == NSLocalizedString("cash", comment: "현금").lowercased())
        HStack(spacing: 0) {
            Text(NSLocalizedString(record.paymentType ?? "-", comment: ""))
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(
                    Capsule().fill(isCard ? Color.blue.opacity(0.7) : isCash ? Color.green.opacity(0.7) : Color.gray.opacity(0.7))
                )
                .frame(width: 48, alignment: .center)
            Text(NSLocalizedString(record.categoryRelation?.name ?? "-", comment: ""))
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? colorForCategory(record.categoryRelation?.name).opacity(0.95) : colorForCategory(record.categoryRelation?.name))
                .frame(width: 60, alignment: .leading)
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
        .background(colorScheme == .light ? Color.white : Color(UIColor(hex: "#23272F")))
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
                    .font(.system(size: 9.6, weight: .semibold))
                    .foregroundColor(isTodayOrYesterday(record.date) ? .accentColor : .secondary)
                    .frame(width: 120, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    .padding(.leading, 0)
                recordRowView(record)
                    .padding(.bottom, 2)
                    .padding(.leading, 0)
                    .padding(.trailing, 4)
            } else {
                Color.clear
                    .frame(height: 20) // 날짜 라벨 높이와 맞춤
                recordRowView(record)
                    .padding(.bottom, 2)
                    .padding(.leading, 0)
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
    let recordRowView: (Record) -> AnyView
    let selectedDateFilter: String
    @Binding var loadedMonthCount: Int
    let fetchRecords: () -> Void
    let customBGColor: Color
    @Environment(\.colorScheme) var colorScheme

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

    // RecordListSectionView 내부에 formattedAmount 함수 추가
    private func formattedAmount(_ amount: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.groupingSeparator = ","
        return numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    // In makeSectionHeader, set background to customBGColor in light mode
    private func makeSectionHeader(
        date: Date,
        incomeText: String?,
        expenseText: String?,
        isToday: Bool,
        isYesterday: Bool,
        displayDate: (Date) -> String,
        customSectionColor: Color,
        customBGColor: Color,
        colorScheme: ColorScheme
    ) -> some View {
        HStack(spacing: 0) {
            // 결제수단 자리: 아이콘 제거, 항상 빈칸
            Text("")
                .frame(width: 20, alignment: .center)
            // 카테고리 자리: 날짜 텍스트 (행과 동일 폰트/정렬)
            Text(displayDate(date))
                .font(.footnote)
                .frame(width: 84, alignment: .leading)
                .foregroundColor(.primary)
            // 상세/금액 영역은 기존과 동일
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                if let incomeText = incomeText {
                    Text(incomeText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .frame(width: 70, alignment: .trailing)
                }
                if let expenseText = expenseText {
                    Text(expenseText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(width: 70, alignment: .trailing)
                }
            }
            .padding(.trailing, 2)
        }
        .frame(height: 29)
        .padding(.vertical, 0)
        .padding(.horizontal, 0)
        .background(colorScheme == .light ? Color.white.opacity(0.85) : customSectionColor)
    }

    @ViewBuilder
    private func dateGroupView(idx: Int, date: Date) -> some View {
        let dayRecords = groupedRecordsByDate[date] ?? []
        let income = dayRecords.filter { $0.type == NSLocalizedString("income", comment: "수입") || $0.type == "수입" }.reduce(0.0) { $0 + $1.amount }
        let expense = dayRecords.filter { $0.type != NSLocalizedString("income", comment: "수입") && $0.type != "수입" }.reduce(0.0) { $0 + $1.amount }
        let incomeText = income > 0 ? formattedAmount(income) : nil
        let expenseText = expense > 0 ? formattedAmount(expense) : nil
        let isToday = isTodayOrYesterday(date) && Calendar.current.isDateInToday(date)
        let isYesterday = isTodayOrYesterday(date) && Calendar.current.isDateInYesterday(date)
        if idx != 0 {
            Spacer().frame(height: 12)
        }
        VStack(spacing: 0) {
            makeSectionHeader(
                date: date,
                incomeText: incomeText,
                expenseText: expenseText,
                isToday: isToday,
                isYesterday: isYesterday,
                displayDate: displayDate,
                customSectionColor: {
                    #if canImport(UIKit)
                    if UITraitCollection.current.userInterfaceStyle == .dark {
                        return Color(UIColor(hex: "#23272F"))
                    } else {
                        return Color(UIColor(hex: "#F6F7FA"))
                    }
                    #else
                    return Color.white
                    #endif
                }(),
                customBGColor: customBGColor,
                colorScheme: colorScheme
            )
            .padding(.horizontal, 0)
            ForEach(Array(dayRecords.enumerated()), id: \ .element.objectID) { rowIdx, record in
                recordRowView(record)
                    .padding(.horizontal, 0)
                    .onAppear {
                        if selectedDateFilter == NSLocalizedString("all", comment: "") && record == records.last {
                            loadedMonthCount += 1
                            fetchRecords()
                        }
                    }
                // Add subtle separator except after last row
                if rowIdx < dayRecords.count - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.10))
                        .frame(height: 1)
                        .padding(.leading, 0)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .light ? Color.white.opacity(0.95) : Color(UIColor(hex: "#23272F")))
                .shadow(color: colorScheme == .light ? Color.black.opacity(0.07) : Color.black.opacity(0.18), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(Array(sortedRecordDates.enumerated()), id: \ .element) { idx, date in
                    dateGroupView(idx: idx, date: date)
                }
            }
            .background(Color.clear)
        }
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

#endif

