import SwiftUI
import Charts

struct ContentView: View {
@Environment(\.managedObjectContext) private var viewContext
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \Record.date, ascending: false)],
    animation: .default)
private var records: FetchedResults<Record>

@AppStorage("colorScheme") private var colorScheme: String = "system"

@State private var selectedRecords = Set<Record>()
@State private var editMode: EditMode = .inactive
@State private var isAddingNewRecord = false
@State private var selectedRecord: Record? = nil
@State private var recordToDelete: Record? = nil
@State private var showingDeleteAlert = false
@State private var selectedTabTitle: String = "가계부 📒"
@State private var selectedStatTab: String = "지출"
@State private var isDeleteMode = false
@AppStorage("selectedCategory") private var selectedCategory: String = "전체"
@AppStorage("selectedDateFilter") private var selectedDateFilter: String = "전체"
@AppStorage("selectedTypeFilter") private var selectedTypeFilter: String = "전체"
@State private var showFilterSheet = false
@State private var customStartDate = Date()
@State private var customEndDate = Date()
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
        case "오늘":
            return formatDateShort(now)
        case "어제":
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                return formatDateShort(yesterday)
            }
        case "1주일":
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                return "\(formatDateShort(weekAgo)) ~ \(formatDateShort(now))"
            }
        case "한달":
            if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) {
                return "\(formatDateShort(monthAgo)) ~ \(formatDateShort(now))"
            }
        case "직접 선택":
            let start = formatDateShort(customStartDate)
            let end = formatDateShort(customEndDate)
            return "\(min(start, end)) ~ \(max(start, end))"
        default:
            return selectedDateFilter
        }
        return selectedDateFilter
    }

private var categoryTotals: [String: Double] {
    var totals = [String: Double]()
    for record in records {
        let category = record.category ?? "기타"
        totals[category, default: 0] += record.amount
    }
    return totals
}

private var monthlyIncomeTotals: [String: Double] {
    var totals = [String: Double]()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"
    for record in records where record.type == "수입" {
        let month = dateFormatter.string(from: record.date ?? Date())
        totals[month, default: 0] += record.amount
    }
    return totals
}

private var monthlyExpenseTotals: [String: Double] {
    var totals = [String: Double]()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"
    for record in records where record.type != "수입" {
        let month = dateFormatter.string(from: record.date ?? Date())
        totals[month, default: 0] += record.amount
    }
    return totals
}

private var monthlyCategoryExpenseTotals: [String: [String: Double]] {
    var totals = [String: [String: Double]]()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"

    for record in records where record.type != "수입" {
        let month = dateFormatter.string(from: record.date ?? Date())
        let category = record.category ?? "기타"
        totals[month, default: [:]][category, default: 0] += record.amount
    }
    return totals
}

private var monthlyCategoryIncomeTotals: [String: [String: Double]] {
    var totals = [String: [String: Double]]()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"

    for record in records where record.type == "수입" {
        let month = dateFormatter.string(from: record.date ?? Date())
        let category = record.category ?? "기타"
        totals[month, default: [:]][category, default: 0] += record.amount
    }
    return totals
}

private func isRecordInSelectedDateRange(_ record: Record) -> Bool {
    guard selectedDateFilter != "전체" else { return true }
    guard let recordDate = record.date else { return false }
    let calendar = Calendar.current
    let now = Date()

    let startOfToday = calendar.startOfDay(for: now)

    switch selectedDateFilter {
    case "오늘":
        return calendar.isDateInToday(recordDate)
    case "어제":
        return calendar.isDateInYesterday(recordDate)
    case "1주일":
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) {
            return recordDate >= weekAgo && recordDate <= now
        } else {
            return false
        }
    case "한달":
        if let monthAgo = calendar.date(byAdding: .month, value: -1, to: startOfToday) {
            return recordDate >= monthAgo && recordDate <= now
        } else {
            return false
        }
    case "직접 선택":
        let safeStartDate = min(customStartDate, customEndDate)
        let safeEndDate = max(customStartDate, customEndDate)
        let recordDay = Calendar.current.startOfDay(for: recordDate)
        let startDay = Calendar.current.startOfDay(for: safeStartDate)
        let endDay = Calendar.current.startOfDay(for: safeEndDate)
        return recordDay >= startDay && recordDay <= endDay
    default:
        return true
    }
}

private var filteredRecords: [Record] {
    records.filter {
        (selectedCategory == "전체" || ($0.category ?? "기타") == selectedCategory)
        && (selectedTypeFilter == "전체" || ($0.type ?? "지출") == selectedTypeFilter)
        && isRecordInSelectedDateRange($0)
    }
}

private var groupedRecordsByDate: [Date: [Record]] {
    Dictionary(grouping: filteredRecords) {
        Calendar.current.startOfDay(for: $0.date ?? Date())
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

                    Text("해당 조건에 맞는 내역이 없습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        isAddingNewRecord = true
                    }) {
                        Label("새 항목 추가", systemImage: "plus")
                            .font(.body)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                ForEach(sortedRecordDates, id: \.self) { date in
                    if let records = groupedRecordsByDate[date] {
                        if records.count > 1 {
                            recordSection(for: records, date: date)
                        } else if let record = records.first {
                            recordRowView(record: record)
                        }
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

        TabView {
            AccountingTabView(
                selectedRecord: $selectedRecord,
                isAddingNewRecord: $isAddingNewRecord,
                isDeleteMode: $isDeleteMode,
                selectedRecords: $selectedRecords,
                filterSummaryView: AnyView(
                    FilterSummaryView(
                        selectedTypeFilter: selectedTypeFilter,
                        selectedCategory: selectedCategory,
                        selectedDateFilter: selectedDateFilter,
                        dateRangeText: dateRangeText(),
                        onTap: { showFilterSheet = true }
                    )
                ),
                recordListSection: AnyView(recordListSection)
            )
            .sheet(isPresented: $showFilterSheet) {
                SearchFilterView(
                    selectedType: $selectedTypeFilter,
                    selectedCategory: $selectedCategory,
                    selectedDate: $selectedDateFilter,
                    customStartDate: $customStartDate,
                    customEndDate: $customEndDate,
                    categoryManager: categoryManager
                )
            }
            .tabItem {
                Label("가계부", systemImage: "list.bullet.rectangle")
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
                Label("통계", systemImage: "chart.pie.fill")
            }
        }
        .preferredColorScheme(
            colorScheme == "light" ? .light :
            colorScheme == "dark" ? .dark : nil
        )
        .sheet(isPresented: $isAddingNewRecord, onDismiss: {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }) {
            AddRecordView(categoryManager: categoryManager, recordToEdit: nil)
                .environment(\.managedObjectContext, viewContext)
                .presentationDetents([.large])
        }
        .sheet(item: $selectedRecord, onDismiss: {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }) { record in
            AddRecordView(categoryManager: categoryManager, recordToEdit: record)
                .environment(\.managedObjectContext, viewContext)
                .presentationDetents([.large])
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
}

private var filterSummaryView: some View {
    VStack(alignment: .leading, spacing: 6) {
        Button(action: {
            showFilterSheet = true
        }) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text("필터 설정")
                Spacer()
            }
            .font(.body)
            .foregroundColor(.blue)
        }
        if selectedTypeFilter != "전체" || selectedDateFilter != "전체" || selectedCategory != "전체" {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("유형:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selectedTypeFilter)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("카테고리:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selectedCategory)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("기간:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dateRangeText())
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
}


@ViewBuilder
private func recordSection(for records: [Record], date: Date) -> some View {
    Section {
        SectionHeader(title: formattedDate(date))
        ForEach(records) { record in
            recordRowView(record: record)
        }
    }
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
            print("삭제 에러: \(error.localizedDescription)")
        }
    }
}

private func formattedAmount(_ amount: Double) -> String {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.maximumFractionDigits = 0
    numberFormatter.groupingSeparator = ","
    let formatted = numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
    return "\(formatted) 원"
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
