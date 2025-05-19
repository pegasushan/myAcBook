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
@Environment(\.managedObjectContext) private var viewContext
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Record.date, ascending: false)],
    animation: .default)
private var records: FetchedResults<Record>

@AppStorage("colorScheme") private var colorScheme: String = "system"
@AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true

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
    private var currentCategory: String {
        switch selectedTypeFilter {
        case NSLocalizedString("income", comment: ""):
            return selectedIncomeCategory
        case NSLocalizedString("expense", comment: ""):
            return selectedExpenseCategory
        default:
            return selectedAllCategory
        }
    }
@AppStorage("selectedDateFilter") private var selectedDateFilter: String = NSLocalizedString("all", comment: "")
@AppStorage("selectedTypeFilter") private var selectedTypeFilter: String = NSLocalizedString("all", comment: "")
@State private var showFilterSheet = false
@AppStorage("customStartDate") private var customStartTimestamp: Double = Date().timeIntervalSince1970
@AppStorage("customEndDate") private var customEndTimestamp: Double = Date().timeIntervalSince1970

private var customStartDate: Date {
    get { Date(timeIntervalSince1970: customStartTimestamp) }
    set { customStartTimestamp = newValue.timeIntervalSince1970 }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

private var customEndDate: Date {
    get { Date(timeIntervalSince1970: customEndTimestamp) }
    set { customEndTimestamp = newValue.timeIntervalSince1970 }
}
@StateObject private var categoryManager = CategoryManager()
@State private var showSplash = true

    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
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

private var categoryTotals: [String: Double] {
    var totals = [String: Double]()
    for record in records {
        let category = record.category ?? NSLocalizedString("etc", comment: "")
        totals[category, default: 0] += record.amount
    }
    return totals
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
        let category = record.category ?? NSLocalizedString("etc", comment: "")
        totals[month, default: [:]][category, default: 0] += record.amount
    }
    return totals
}

private var monthlyCategoryIncomeTotals: [String: [String: Double]] {
    var totals = [String: [String: Double]]()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"

    for record in records where record.type == NSLocalizedString("income", comment: "") {
        let month = dateFormatter.string(from: record.date ?? Date())
        let category = record.category ?? NSLocalizedString("etc", comment: "")
        totals[month, default: [:]][category, default: 0] += record.amount
    }
    return totals
}

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
        } else {
            return false
        }
    case NSLocalizedString("month", comment: ""):
        if let monthAgo = calendar.date(byAdding: .month, value: -1, to: startOfToday) {
            return recordDate >= monthAgo && recordDate <= now
        } else {
            return false
        }
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
        let matchesCategory = currentCategory == NSLocalizedString("all", comment: "") || (record.category ?? NSLocalizedString("etc", comment: "")) == currentCategory
        let matchesType: Bool = {
            if selectedTypeFilter == NSLocalizedString("all", comment: "") {
                return true
            }
            guard let type = record.type else { return false }
            return type == selectedTypeFilter
        }()
        let matchesDate = isRecordInSelectedDateRange(record)
        return matchesCategory && matchesType && matchesDate
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

private var groupedRecordSections: some View {
    AnyView(
        Group {
            if filteredRecords.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tray")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.secondary)

                    Text(NSLocalizedString("no_matching_records", comment: "해당 조건에 맞는 내역이 없습니다."))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)

                    Button(action: {
                        isAddingNewRecord = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Text(NSLocalizedString("add_new_entry", comment: "새 항목 추가"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .multilineTextAlignment(.center)
            } else {
                ForEach(sortedRecordDates, id: \.self) { date in
                    if let records = groupedRecordsByDate[date] {
                        recordSection(for: records, date: date)
                    }
                }
            }
        }
    )
}

var body: some View {
    ZStack {
        GeometryReader { geometry in
            Image("BackgroundGlass")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()
                .opacity(0.6)
        }

        VStack(spacing: 0) {
            TabView {
                AccountingTabView(
                    selectedRecord: $selectedRecord,
                    isAddingNewRecord: $isAddingNewRecord,
                    isDeleteMode: $isDeleteMode,
                    selectedRecords: $selectedRecords,
                    filterSummaryView: AnyView(
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
                            }
                        )
                    ),
                    recordListSection: AnyView(recordListSection)
                )
                .sheet(isPresented: $showFilterSheet) {
                    SearchFilterView(
                        selectedType: $selectedTypeFilter,
                        selectedCategory: $selectedCategory,
                        selectedDate: $selectedDateFilter,
                        customStartDate: Binding(
                            get: { Date(timeIntervalSince1970: customStartTimestamp) },
                            set: { customStartTimestamp = $0.timeIntervalSince1970 }
                        ),
                        customEndDate: Binding(
                            get: { Date(timeIntervalSince1970: customEndTimestamp) },
                            set: { customEndTimestamp = $0.timeIntervalSince1970 }
                        ),
                        selectedIncomeCategory: $selectedIncomeCategory,
                        selectedExpenseCategory: $selectedExpenseCategory,
                        selectedAllCategory: $selectedAllCategory,
                        categoryManager: categoryManager
                    )
                }
                .tabItem {
                    Label(NSLocalizedString("ledger_tab", comment: ""), systemImage: "list.bullet.rectangle")
                }

                StatisticsTabView(
                    selectedStatTab: $selectedStatTab,
                    monthlyIncomeTotals: monthlyIncomeTotals,
                    monthlyExpenseTotals: monthlyExpenseTotals,
                    monthlyCategoryIncomeTotals: monthlyCategoryIncomeTotals,
                    monthlyCategoryExpenseTotals: monthlyCategoryExpenseTotals,
                    formattedAmount: formattedAmount
                )
                .tabItem {
                    Label(NSLocalizedString("statistics_tab", comment: ""), systemImage: "chart.pie.fill")
                }

                NavigationView {
                    SettingsView()
                }
                .tabItem {
                    Label(NSLocalizedString("settings_tab", comment: ""), systemImage: "gear")
                }
            }
            .sheet(isPresented: $isAddingNewRecord, onDismiss: {
                if isHapticsEnabled {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }) {
                AddRecordView(categoryManager: categoryManager, recordToEdit: nil)
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.large])
            }
            .sheet(item: $selectedRecord, onDismiss: {
                if isHapticsEnabled {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }) { record in
                AddRecordView(categoryManager: categoryManager, recordToEdit: record)
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.large])
            }

            Divider()

            BannerAdView()
                .frame(height: 50)
        }

        if showSplash {
            SplashView()
                .transition(.opacity)
                .zIndex(1)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation {
                            showSplash = false
                        }
                    }
                }
        }
    }
}

private var recordListSection: some View {
    Section {
        groupedRecordSections
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color(.systemBackground))
    .font(.system(size: 14, weight: .regular, design: .rounded))
}

private var filterSummaryView: some View {
    VStack(alignment: .leading, spacing: 6) {
        // 필터 설정 버튼과 초기화 버튼을 HStack으로 분리 배치
        HStack {
            Button(action: {
                showFilterSheet = true
            }) {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(NSLocalizedString("filter_setting", comment: "필터 설정"))
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                selectedTypeFilter = NSLocalizedString("all", comment: "")
                selectedCategory = NSLocalizedString("all", comment: "")
                selectedDateFilter = NSLocalizedString("all", comment: "")
                customStartTimestamp = Date().timeIntervalSince1970
                customEndTimestamp = Date().timeIntervalSince1970
            }) {
                Label(NSLocalizedString("reset", comment: "초기화"), systemImage: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.red)
            }
        }
        if selectedTypeFilter != NSLocalizedString("all", comment: "") || selectedDateFilter != NSLocalizedString("all", comment: "") || selectedCategory != NSLocalizedString("all", comment: "") {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(NSLocalizedString("type", comment: "유형") + ":")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(selectedTypeFilter)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(NSLocalizedString("category", comment: "카테고리") + ":")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(selectedCategory)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(NSLocalizedString("period", comment: "기간") + ":")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(dateRangeText())
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .font(.system(size: 14, weight: .regular, design: .rounded))
}


@ViewBuilder
private func recordSection(for records: [Record], date: Date) -> some View {
    Section {
        SectionHeader(
            title: formattedDate(
                Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: date)) ?? date
            )
        )
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundColor(Color.blue)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        ForEach(records) { record in
            recordRowView(record: record)
        }
    }
    .headerProminence(.increased)
    .font(.system(size: 14, weight: .regular, design: .rounded))
}

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
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground).opacity(0.95))
    )
}

private func deleteSelectedRecords() {
    withAnimation {
        for record in selectedRecords {
            viewContext.delete(record)
        }
        selectedRecords.removeAll()
        do {
            try viewContext.save()
        } catch {
            print("Delete error: \(error.localizedDescription)")
        }
    }
}

private func formattedAmount(_ amount: Double) -> String {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.maximumFractionDigits = 0
    numberFormatter.groupingSeparator = ","
    let formatted = numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
    return String(format: NSLocalizedString("formatted_amount", comment: "금액 포맷"), formatted)
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
}
