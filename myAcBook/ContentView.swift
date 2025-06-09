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
@EnvironmentObject var purchaseManager: IAPManager
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Record.date, ascending: false)],
    animation: .default)
private var records: FetchedResults<Record>

@AppStorage("colorScheme") private var colorScheme: String = "system"
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
@AppStorage("selectedDateFilter") private var selectedDateFilter: String = NSLocalizedString("all", comment: "")
@AppStorage("selectedTypeFilter") private var selectedTypeFilter: String = NSLocalizedString("all", comment: "")
@State private var showFilterSheet = false
@AppStorage("customStartDate") private var customStartTimestamp: Double = Date().timeIntervalSince1970
@AppStorage("customEndDate") private var customEndTimestamp: Double = Date().timeIntervalSince1970
@State private var showSettingsSheet = false
@State private var customStartDate: Date
@State private var customEndDate: Date

init() {
    let start = UserDefaults.standard.double(forKey: "customStartDate")
    let end = UserDefaults.standard.double(forKey: "customEndDate")
    _customStartDate = State(initialValue: start > 0 ? Date(timeIntervalSince1970: start) : Date())
    _customEndDate = State(initialValue: end > 0 ? Date(timeIntervalSince1970: end) : Date())
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

private var currentCategory: String {
    return selectedCategory
}

private var categoryTotals: [String: Double] {
    var totals = [String: Double]()
    for record in records {
        let categoryKey = record.categoryRelation?.name ?? "etc"
        totals[categoryKey, default: 0] += record.amount
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
        let recordCategoryKey = record.categoryRelation?.name ?? "etc"
        let matchesCategory = currentCategory == NSLocalizedString("all", comment: "") || recordCategoryKey == currentCategory
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
                    .background(Color("HighlightColor"))
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)
        } else {
            List {
                ForEach(sortedRecordDates, id: \.self) { date in
                    if let records = groupedRecordsByDate[date] {
                        recordSection(for: records, date: date)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color("BackgroundSolidColor"))
            .listRowBackground(Color("BackgroundSolidColor"))
            .listRowSeparator(.hidden)
        }
    }
}

var body: some View {
    NavigationView {
        ZStack {
            Color("BackgroundSolidColor").ignoresSafeArea()
            VStack(spacing: 0) {
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
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 12)
                groupedRecordSections
                Spacer(minLength: 0)
                BannerAdContainerView()
                    .frame(height: 50)
                    .padding(.bottom, 8)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .navigationBarTitle(Text(NSLocalizedString("ledger_tab", comment: "가계부")), displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    isDeleteMode.toggle()
                    selectedRecords.removeAll()
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.red))
                        .shadow(radius: 2)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isAddingNewRecord = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 2)
                }
            }
        }
        .sheet(isPresented: $isAddingNewRecord) {
            AddRecordView()
        }
        .sheet(isPresented: $showFilterSheet) {
            SearchFilterView(
                selectedType: $selectedTypeFilter,
                selectedCategory: $selectedCategory,
                selectedDate: $selectedDateFilter,
                customStartDate: $customStartDate,
                customEndDate: $customEndDate,
                selectedIncomeCategory: $selectedIncomeCategory,
                selectedExpenseCategory: $selectedExpenseCategory,
                selectedAllCategory: $selectedAllCategory,
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
        }
    }
}

private var recordListSection: some View {
    Section {
        groupedRecordSections
    }
    .listRowBackground(Color("BackgroundSolidColor"))
    .font(.system(size: 14, weight: .regular, design: .rounded))
}

private var filterSummaryView: some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            Button(action: {
                showFilterSheet = true
            }) {
                Text(NSLocalizedString("filter_setting", comment: "필터 설정"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: {
                selectedTypeFilter = NSLocalizedString("all", comment: "")
                selectedIncomeCategory = NSLocalizedString("all", comment: "")
                selectedExpenseCategory = NSLocalizedString("all", comment: "")
                selectedAllCategory = NSLocalizedString("all", comment: "")
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
        Group {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(NSLocalizedString("type", comment: "유형") + ":")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(selectedTypeFilter == NSLocalizedString("all", comment: "") ? NSLocalizedString("all", comment: "") : selectedTypeFilter)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(NSLocalizedString("category", comment: "카테고리") + ":")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(selectedCategory == NSLocalizedString("all", comment: "") ? NSLocalizedString("all", comment: "") : selectedCategory)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(NSLocalizedString("period", comment: "기간") + ":")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(selectedDateFilter == NSLocalizedString("all", comment: "") ? NSLocalizedString("all", comment: "") : dateRangeText())
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    .padding()
    .background(Color("SectionBGColor"))
    .cornerRadius(12)
    .font(.system(size: 14, weight: .regular, design: .rounded))
}


@ViewBuilder
private func recordSection(for records: [Record], date: Date) -> some View {
    Section {
        Text(formattedDate(
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: date)) ?? date
        ))
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundColor(Color("HighlightColor"))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        ForEach(records) { record in
            recordRowView(record: record)
                .listRowBackground(Color("BackgroundSolidColor"))
                .listRowSeparator(.hidden)
        }
    }
    .headerProminence(.increased)
    .font(.system(size: 14, weight: .regular, design: .rounded))
    .listRowBackground(Color("BackgroundSolidColor"))
    .listRowSeparator(.hidden)
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
            .fill(Color("SectionBGColor").opacity(0.95))
    )
    .onTapGesture {
        print("📝 Record tapped for edit:")
        print("- id: \(record.id?.uuidString ?? "nil")")
        print("- type: \(record.type ?? "nil")")
        print("- amount: \(record.amount)")
        print("- date: \(formattedDate(record.date ?? Date()))")
        print("- detail: \(record.detail ?? "nil")")
        print("- paymentType: \(record.paymentType ?? "nil")")
        print("- card: \(record.card?.name ?? "nil")")
        print("- category: \(record.categoryRelation?.name ?? "nil")")
        selectedRecord = record
    }
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
