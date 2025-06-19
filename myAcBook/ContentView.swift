import SwiftUI
import Charts
import GoogleMobileAds
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

struct ContentView: View {
    // MARK: - Environment & State
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var purchaseManager: IAPManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Record.date, ascending: false)],
        animation: .default)
    private var records: FetchedResults<Record>

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
    @AppStorage("selectedDateFilter") private var selectedDateFilter: String = NSLocalizedString("all", comment: "")
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
            let matchesDate = isRecordInSelectedDateRange(record)
            let matchesPaymentType: Bool = {
                if selectedTypeFilter == NSLocalizedString("expense", comment: "") && selectedPaymentType != NSLocalizedString("all", comment: "전체") {
                    return record.paymentType == selectedPaymentType
                }
                return true
            }()
            return matchesCategory && matchesType && matchesDate && matchesPaymentType
        }
    }
    private var groupedRecordsByDate: [Date: [Record]] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let filtered = filteredRecords
        return Dictionary(grouping: filtered) { record in
            guard let date = record.date else { return Date.distantPast }
            return calendar.startOfDay(for: date)
        }
    }
    private var sortedRecordDates: [Date] {
        groupedRecordsByDate.keys.sorted(by: >)
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                customBGColor.ignoresSafeArea()
                mainContent
            }
        }
        .onAppear {
            notifyStatisticsDataChanged()
        }
        .onChange(of: selectedTypeFilter) {
            notifyStatisticsDataChanged()
        }
        .onChange(of: selectedCategory) {
            notifyStatisticsDataChanged()
        }
        .onChange(of: selectedDateFilter) {
            notifyStatisticsDataChanged()
        }
        .onChange(of: selectedPaymentType) {
            notifyStatisticsDataChanged()
        }
        .sheet(isPresented: $isAddingNewRecord) {
            AddRecordView()
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
                    selectedDateFilter = NSLocalizedString("all", comment: "")
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
            // 총 건수 표시
            Text("\(filteredRecords.count)건")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.bottom, 0)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
            groupedRecordSections
            if isDeleteMode { deleteButtons }
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
            dateRangeText: dateRangeText(),
            onTap: { showFilterSheet = true },
            onReset: {
                selectedTypeFilter = NSLocalizedString("all", comment: "")
                selectedIncomeCategory = NSLocalizedString("all", comment: "")
                selectedExpenseCategory = NSLocalizedString("all", comment: "")
                selectedAllCategory = NSLocalizedString("all", comment: "")
                selectedDateFilter = NSLocalizedString("all", comment: "")
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
                    title: Text("정말 모든 내역을 삭제하시겠습니까?"),
                    message: Text("이 작업은 되돌릴 수 없습니다."),
                    primaryButton: .destructive(Text("전체 삭제")) {
                        withAnimation {
                            for record in records {
                                viewContext.delete(record)
                            }
                            selectedRecords.removeAll()
                            try? viewContext.save()
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

    // MARK: - Grouped Record Sections (중복 제거)
    private var groupedRecordSections: some View {
        Group {
            if filteredRecords.isEmpty {
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
                .padding(.horizontal, 0)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(sortedRecordDates, id: \.self) { date in
                            if let records = groupedRecordsByDate[date] {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(formattedDate(
                                        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: date)) ?? date
                                    ))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color("HighlightColor"))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    VStack(spacing: 0) {
                                        ForEach(records.indices, id: \.self) { index in
                                            if index != 0 {
                                                Divider().padding(.vertical, 2)
                                            }
                                            recordRowView(record: records[index])
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(customCardColor)
                                )
                                .padding(.horizontal, 0)
                                .padding(.top, 4)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 0)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(customBGColor)
            }
        }
    }

    // MARK: - View Builders
    @ViewBuilder
    private func recordRowView(record: Record) -> some View {
        RecordRowView(
            record: record,
            isDeleteMode: isDeleteMode,
            selectedRecords: selectedRecords,
            toggleSelection: toggleSelection,
            selectedRecord: $selectedRecord,
            formattedAmount: formattedAmount,
            formattedDate: formattedDate
        )
        .onTapGesture { selectedRecord = record }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isDeleteMode {
                Button(role: .destructive) {
                    withAnimation {
                        viewContext.delete(record)
                        try? viewContext.save()
                    }
                } label: {
                    Label(NSLocalizedString("delete", comment: "삭제"), systemImage: "trash")
                }
            }
        }
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

