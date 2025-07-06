import CoreData
import SwiftUI
import Charts

let pastelIncomeColor = Color(red: 0.45, green: 0.65, blue: 1.0) // 파스텔 블루(수입)
let pastelExpenseColor = Color(red: 1.0, green: 0.45, blue: 0.55) // 파스텔 레드(지출)

// y축/라벨용 compact number formatter (다국어)
func formattedCompactNumber(_ value: Double) -> String {
    let absValue = abs(value)
    let locale = Locale.current.language.languageCode?.identifier ?? "en"
    if locale == "ko" {
        if absValue >= 100_000_000 {
            return String(format: "%.1f억", value / 100_000_000)
        } else if absValue >= 10_000 {
            return String(format: "%.1f만", value / 10_000)
        } else if absValue >= 1_000 {
            return String(format: "%.1f천", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    } else {
        if absValue >= 1_000_000_000 {
            return String(format: "%.1fB", value / 1_000_000_000)
        } else if absValue >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if absValue >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// 월별 수입/지출 그룹드 바차트용 데이터 구조
struct MonthValue: Identifiable {
    let id = UUID()
    let month: String
    let type: String // "수입" or "지출"
    let value: Double
    let count: Int // 추가: 해당 월/타입의 건수
}

struct ExpenseDetailView: View {
    let month: String
    var paymentType: String? = nil
    var cardName: String? = nil
    var customBGColor: Color = Color(UIColor(named: "customLightBGColor") ?? .yellow)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Record.date, ascending: false)],
        animation: .default
    ) private var records: FetchedResults<Record>
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    var customCardColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightCardColorHex)) : Color(UIColor(hex: customDarkCardColorHex))
    }

    var detailTitle: String {
        var title = "\(month) 지출"
        if let paymentType = paymentType, let cardName = cardName {
            title += "(\(NSLocalizedString(paymentType, comment: ""))/\(NSLocalizedString(cardName, comment: "")))"
        } else if let paymentType = paymentType {
            title += "(\(NSLocalizedString(paymentType, comment: "")))"
        } else if let cardName = cardName {
            title += "(\(NSLocalizedString(cardName, comment: "")))"
        }
        title += " 상세내역"
        return title
    }

    init(month: String, paymentType: String? = nil, cardName: String? = nil, customBGColor: Color = Color(UIColor(named: "customLightBGColor") ?? .yellow)) {
        self.month = month
        self.paymentType = paymentType
        self.cardName = cardName
        self.customBGColor = customBGColor
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let startDate = dateFormatter.date(from: month) ?? Date()
        var comps = DateComponents()
        comps.month = 1
        let endDate = Calendar.current.date(byAdding: comps, to: startDate) ?? Date()
        var predicateFormat = "date >= %@ AND date < %@ AND type == %@"
        var predicateArgs: [Any] = [startDate as NSDate, endDate as NSDate, "지출"]
        if let paymentType = paymentType {
            predicateFormat += " AND paymentType == %@"
            predicateArgs.append(paymentType)
        }
        if let cardName = cardName {
            predicateFormat += " AND card.name == %@"
            predicateArgs.append(cardName)
        }
        let predicate = NSPredicate(format: predicateFormat, argumentArray: predicateArgs)
        _records = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Record.date, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(detailTitle)
                .font(.headline).bold()
                .padding(.top, 16)
            Text("\(records.count)건")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
                .padding(.top, 10)
                .padding(.bottom, 2)
            if records.isEmpty {
                Spacer()
                Text(NSLocalizedString("no_data_stats", comment: "표시할 데이터가 없습니다."))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(records, id: \.objectID) { record in
                            CompactRecordRowView(
                                record: record,
                                onTap: nil,
                                colorForCategory: { name in
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
                                },
                                isIncome: { record in
                                    record.type == NSLocalizedString("income", comment: "수입") || record.type == "수입"
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .background(customBGColor.ignoresSafeArea())
    }
}

struct IncomeDetailView: View {
    let month: String
    let categoryName: String?
    var customBGColor: Color = Color(UIColor(named: "customLightBGColor") ?? .yellow)
    @FetchRequest private var records: FetchedResults<Record>

    init(month: String, categoryName: String? = nil, customBGColor: Color = Color(UIColor(named: "customLightBGColor") ?? .yellow)) {
        self.month = month
        self.categoryName = categoryName
        self.customBGColor = customBGColor
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let startDate = dateFormatter.date(from: month) ?? Date()
        var comps = DateComponents()
        comps.month = 1
        let endDate = Calendar.current.date(byAdding: comps, to: startDate) ?? Date()
        var predicateFormat = "date >= %@ AND date < %@ AND type == %@"
        var predicateArgs: [Any] = [startDate as NSDate, endDate as NSDate, "수입"]
        if let categoryName = categoryName {
            predicateFormat += " AND categoryRelation.name == %@"
            predicateArgs.append(categoryName)
        }
        let predicate = NSPredicate(format: predicateFormat, argumentArray: predicateArgs)
        _records = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Record.date, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(categoryName != nil ? "\(month) 수입(\(NSLocalizedString(categoryName!, comment: ""))) 상세내역" : "\(month) 수입 상세내역")
                .font(.headline).bold()
                .padding(.top, 16)
            Text("\(records.count)건")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
                .padding(.top, 10)
                .padding(.bottom, 2)
            if records.isEmpty {
                Spacer()
                Text(NSLocalizedString("no_data_stats", comment: "표시할 데이터가 없습니다."))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(records, id: \.objectID) { record in
                            CompactRecordRowView(
                                record: record,
                                onTap: nil,
                                colorForCategory: { name in
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
                                },
                                isIncome: { record in
                                    record.type == NSLocalizedString("income", comment: "수입") || record.type == "수입"
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .background(customBGColor.ignoresSafeArea())
    }
}

struct StatisticsTabView: View {
    @AppStorage("customLightBGColor") private var customLightBGColorHex: String = "#FEEAF2"
    @AppStorage("customDarkBGColor") private var customDarkBGColorHex: String = "#181A20"
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    @AppStorage("customLightSectionColor") private var customLightSectionColorHex: String = "#F6F7FA"
    @AppStorage("customDarkSectionColor") private var customDarkSectionColorHex: String = "#23272F"
    @Environment(\.colorScheme) var colorScheme
    let monthlyIncomeTotals: [String: Double]
    let monthlyExpenseTotals: [String: Double]
    let monthlyCategoryIncomeTotals: [String: [String: Double]]
    let monthlyCategoryExpenseTotals: [String: [String: Double]]
    let monthlyCardExpenseTotals: [String: [String: Double]]
    let monthlyCashExpenseTotals: [String: Double]
    let formattedAmount: (Double) -> String
    let allCards: [Card]
    let selectedTypeFilter: String
    let selectedCategory: String
    let selectedDateFilter: String
    let dateRangeText: String
    let onTap: () -> Void
    let onReset: () -> Void
    @State private var isAscendingSort = false
    @State private var graphOffset: Int = 0
    @State private var showBarAnnotations: Bool = true
    @State private var selectedExpenseView: String = "all"
    @State private var selectedStatTab: String = NSLocalizedString("graph", comment: "그래프")
    @State private var expandedCardMonth: String? = nil
    @State private var selectedPeriod: String = NSLocalizedString("period_3months", comment: "3개월")
    let records: [Record]

    var customBGColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightBGColorHex)) : Color(UIColor(hex: customDarkBGColorHex))
    }
    var customCardColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightCardColorHex)) : Color(UIColor(hex: customDarkCardColorHex))
    }
    var customSectionColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightSectionColorHex)) : Color(UIColor(hex: customDarkSectionColorHex))
    }

    var sortedMonths: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let allMonths = Set(monthlyIncomeTotals.keys).union(monthlyExpenseTotals.keys)
        return allMonths.sorted {
            guard let d1 = dateFormatter.date(from: $0),
                  let d2 = dateFormatter.date(from: $1) else { return false }
            return d1 < d2
        }
    }
    
    var sortedCategoryMonths: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        return monthlyCategoryIncomeTotals.keys.sorted {
            guard let d1 = dateFormatter.date(from: $0),
                  let d2 = dateFormatter.date(from: $1) else { return false }
            return d1 > d2
        }
    }

    private var periodOptions: [String] {
        [
            NSLocalizedString("period_3months", comment: "3개월"),
            NSLocalizedString("period_6months", comment: "6개월"),
            NSLocalizedString("period_1year", comment: "1년"),
            NSLocalizedString("period_all", comment: "전체")
        ]
    }

    // 선택된 기간에 따라 필터링된 월 목록
    var filteredMonths: [String] {
        let months = sortedMonths
        switch selectedPeriod {
        case NSLocalizedString("period_3months", comment: "3개월"):
            return Array(months.suffix(3)).reversed()
        case NSLocalizedString("period_6months", comment: "6개월"):
            return Array(months.suffix(6)).reversed()
        case NSLocalizedString("period_1year", comment: "1년"):
            return Array(months.suffix(12)).reversed()
        default:
            return months.reversed()
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                contentView
            }
            .background(customBGColor.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var contentView: some View {
        let isIncomeTab = selectedStatTab == NSLocalizedString("income", comment: "수입")
        let isExpenseTab = selectedStatTab == NSLocalizedString("expense", comment: "지출")
        let isGraphTab = selectedStatTab == NSLocalizedString("graph", comment: "그래프")
        let hasIncomeData = monthlyCategoryIncomeTotals.values.flatMap { $0.values }.reduce(0, +) > 0
        let hasExpenseData = monthlyCategoryExpenseTotals.values.flatMap { $0.values }.reduce(0, +) > 0
        VStack {
            Picker(NSLocalizedString("statistics_type", comment: "통계 종류"), selection: $selectedStatTab) {
                Text(NSLocalizedString("graph", comment: "그래프")).tag(NSLocalizedString("graph", comment: "그래프"))
                Text(NSLocalizedString("expense", comment: "지출")).tag(NSLocalizedString("expense", comment: "지출"))
                Text(NSLocalizedString("income", comment: "수입")).tag(NSLocalizedString("income", comment: "수입"))
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if isGraphTab {
                Text(NSLocalizedString("monthly_stats_title", comment: "월별 수입/지출 통계 그래프"))
                    .font(.system(size: (Locale.current.language.languageCode?.identifier == "en" ? 15 : 20), weight: .semibold, design: .rounded))
                    .foregroundColor(Color.primary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                HStack(spacing: 8) {
                    Button(action: { moveToPrevPeriod() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18 * 0.7))
                            .foregroundColor(.white)
                            .padding(8 * 0.7)
                            .background(pastelAccentColor)
                            .clipShape(Circle())
                            .shadow(color: pastelAccentColor.opacity(0.12), radius: 3 * 0.7, x: 0, y: 1)
                    }
                    Menu {
                        ForEach(periodOptions, id: \.self) { period in
                            Button(action: { selectedPeriod = period }) {
                                Text(period)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedPeriod)
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
                    Button(action: { moveToNextPeriod() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18 * 0.7))
                            .foregroundColor(.white)
                            .padding(8 * 0.7)
                            .background(pastelAccentColor)
                            .clipShape(Circle())
                            .shadow(color: pastelAccentColor.opacity(0.12), radius: 3 * 0.7, x: 0, y: 1)
                    }
                }
                .padding(.bottom, 10)
            }

            if isIncomeTab {
                if !hasIncomeData {
                    VStack {
                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.gray.opacity(0.3))
                            .padding(.bottom, 8)
                        Text(NSLocalizedString("no_data_stats", comment: "표시할 데이터가 없습니다."))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 월별 카테고리별 수입 합계 표시
                    CategorySectionView(
                        records: Array(records),
                        monthlyCategoryTotals: filterMonths(dict: monthlyCategoryIncomeTotals),
                        color: pastelIncomeColor,
                        sectionTitleSuffix: NSLocalizedString("income", comment: ""),
                        formattedAmount: formattedAmount,
                        isAscendingSort: isAscendingSort,
                        onToggleSort: { isAscendingSort.toggle() },
                        allCards: allCards
                    )
                    .background(customBGColor).ignoresSafeArea()
                }
            } else if isExpenseTab {
                if !hasExpenseData {
                    VStack {
                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.gray.opacity(0.3))
                            .padding(.bottom, 8)
                        Text(NSLocalizedString("no_data_stats", comment: "표시할 데이터가 없습니다."))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ExpenseAccordionSectionView(
                        monthRecordMap: monthRecordMap,
                        monthlyCategoryTotals: filterMonths(dict: monthlyCategoryExpenseTotals),
                        monthlyCardExpenseTotals: filterMonths(dict: monthlyCardExpenseTotals),
                        monthlyCashExpenseTotals: filterMonths(dict: monthlyCashExpenseTotals),
                        formattedAmount: formattedAmount,
                        expandedCardMonth: $expandedCardMonth
                    )
                    .background(customBGColor).ignoresSafeArea()
                }
            } else if isGraphTab {
                if filteredMonths.isEmpty || (filteredMonths.allSatisfy { (monthlyIncomeTotals[$0] ?? 0) == 0 && (monthlyExpenseTotals[$0] ?? 0) == 0 }) {
                    VStack {
                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.gray.opacity(0.3))
                            .padding(.bottom, 8)
                        Text(NSLocalizedString("no_data_stats", comment: "표시할 데이터가 없습니다."))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let chartData: [MonthValue] = filteredMonths.flatMap { month in
                        let incomeCount = records.filter { record in
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM"
                            return record.type == NSLocalizedString("income", comment: "") && dateFormatter.string(from: record.date ?? Date()) == month
                        }.count
                        let expenseCount = records.filter { record in
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM"
                            return record.type == NSLocalizedString("expense", comment: "") && dateFormatter.string(from: record.date ?? Date()) == month
                        }.count
                        return [
                            MonthValue(month: month, type: NSLocalizedString("income", comment: ""), value: monthlyIncomeTotals[month] ?? 0, count: incomeCount),
                            MonthValue(month: month, type: NSLocalizedString("expense", comment: ""), value: monthlyExpenseTotals[month] ?? 0, count: expenseCount)
                        ]
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        GroupedBarChartView(data: chartData)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    func getSortedMonths(
        from monthlyCategoryTotals: [String: [String: Double]],
        ascending: Bool
    ) -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        return monthlyCategoryTotals.keys.sorted {
            guard let d1 = dateFormatter.date(from: $0),
                  let d2 = dateFormatter.date(from: $1) else { return false }
            return ascending ? d1 < d2 : d1 > d2
        }
    }

    @ViewBuilder
    func CategorySectionView(
        records: [Record],
        monthlyCategoryTotals: [String: [String: Double]],
        color: Color,
        sectionTitleSuffix: String,
        formattedAmount: @escaping (Double) -> String,
        isAscendingSort: Bool,
        onToggleSort: @escaping () -> Void,
        allCards: [Card]
    ) -> some View {
        let sortedMonths = getSortedMonths(from: monthlyCategoryTotals, ascending: isAscendingSort)
        let monthData: [(month: String, categorySums: [String: Double], incomeSum: Double, incomeCount: Int, monthNumber: String)] = sortedMonths.map { month in
            let categorySums = monthlyCategoryTotals[month] ?? [:]
            let incomeSum = categorySums.values.reduce(0, +)
            let allRecords: [Record] = Array(records)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            let monthString = month
            let incomeRecords = allRecords.filter { $0.type == "수입" && $0.date != nil && dateFormatter.string(from: $0.date!) == monthString }
            let incomeCount = incomeRecords.count
            let monthNumber = month.split(separator: "-").count == 2 ? String(Int(month.split(separator: "-")[1]) ?? 0) : month
            return (month, categorySums, incomeSum, incomeCount, monthNumber)
        }
        if monthlyCategoryTotals.isEmpty {
            VStack {
                Spacer()
                Text(NSLocalizedString("no_data", comment: "표시할 데이터가 없습니다")).appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(customBGColor)
        } else {
            ScrollView {
                VStack(spacing: 28) {
                    ForEach(monthData, id: \.month) { data in
                        VStack(alignment: .leading, spacing: 18) {
                            // 월별 합계 (상단)
                            NavigationLink(destination: IncomeDetailView(month: data.month, customBGColor: customBGColor)) {
                                HStack {
                                    Text("\(data.monthNumber)월 합계 (\(data.incomeCount)건)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(pastelIncomeColor)
                                        .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                    Spacer()
                                    Text(formattedAmount(data.incomeSum))
                                        .font(.system(size: 24, weight: .heavy))
                                        .foregroundColor(pastelIncomeColor)
                                        .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : pastelIncomeColor.opacity(0.18), radius: 2, x: 0, y: 2)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.bottom, 2)
                            // 하단 카테고리별 합계 리스트
                            let sortedCategorySums = data.categorySums.sorted { $0.key < $1.key }
                            let filteredCategorySums = sortedCategorySums.filter { $0.value > 0 }
                            ForEach(filteredCategorySums, id: \ .key) { category, sum in
                                let categoryCount = records.filter { record in
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy-MM"
                                    let monthString = dateFormatter.string(from: record.date ?? Date())
                                    return record.type == "수입" && record.categoryRelation?.name == category && monthString == data.month
                                }.count
                                NavigationLink(destination: IncomeDetailView(month: data.month, categoryName: category, customBGColor: customBGColor)) {
                                    HStack {
                                        Text("")
                                        Text("")
                                        Label("\(NSLocalizedString(category, comment: "")) (\(categoryCount)건)", systemImage: "tag")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(formattedAmount(sum))
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(pastelIncomeColor)
                                            .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(customCardColor)
                                    .cornerRadius(10)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .background(customCardColor)
                        .cornerRadius(22)
                        .shadow(color: colorScheme == .light ? Color("HighlightColor").opacity(0.10) : Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(colorScheme == .light ? Color("HighlightColor").opacity(0.18) : Color("HighlightColor").opacity(0.35), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 16)
                        .animation(.spring(), value: data.incomeSum)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    func ExpenseAccordionSectionView(
        monthRecordMap: [String: [Record]],
        monthlyCategoryTotals: [String: [String: Double]],
        monthlyCardExpenseTotals: [String: [String: Double]],
        monthlyCashExpenseTotals: [String: Double],
        formattedAmount: @escaping (Double) -> String,
        expandedCardMonth: Binding<String?>
    ) -> some View {
        let sortedMonths = getSortedMonths(from: monthlyCategoryTotals, ascending: false)
        ScrollView {
            VStack(spacing: 36) {
                ForEach(sortedMonths, id: \.self) { month in
                    let filteredMonthRecords = monthRecordMap[month] ?? []
                    let monthCount = filteredMonthRecords.count
                    let filteredCashRecords = filteredMonthRecords.filter { $0.paymentType == "현금" }
                    let cashCount = filteredCashRecords.count
                    let filteredCardRecords = filteredMonthRecords.filter { $0.paymentType == "카드" }
                    let cardCount = filteredCardRecords.count
                    let totals = monthlyCategoryTotals[month] ?? [:]
                    let cashSum = monthlyCashExpenseTotals[month] ?? 0
                    let cardSums = monthlyCardExpenseTotals[month] ?? [:]
                    let cardSum = cardSums.values.reduce(0, +)
                    let monthNumber = month.split(separator: "-").count == 2 ? String(Int(month.split(separator: "-")[1]) ?? 0) : month
                    VStack(alignment: .leading, spacing: 18) {
                        // 월별 합계
                        NavigationLink(destination: ExpenseDetailView(month: month, customBGColor: customBGColor)) {
                            HStack {
                                Text("\(monthNumber)월 합계 (\(monthCount)건)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(pastelExpenseColor)
                                    .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                Spacer()
                                Text(formattedAmount(totals.values.reduce(0, +)))
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(pastelExpenseColor)
                                    .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : pastelExpenseColor.opacity(0.18), radius: 2, x: 0, y: 2)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 2)
                        // 현금/카드 합계 카드 박스
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                NavigationLink(destination: ExpenseDetailView(month: month, paymentType: "현금", customBGColor: customBGColor)) {
                                    Label(String(format: NSLocalizedString("cash_total", comment: "현금 합계"), cashCount), systemImage: "banknote")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formattedAmount(cashSum))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(pastelExpenseColor)
                                        .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(customCardColor)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Label(String(format: NSLocalizedString("card_total", comment: "카드 합계"), cardCount), systemImage: "creditcard")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: expandedCardMonth.wrappedValue == month ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.gray)
                                NavigationLink(destination: ExpenseDetailView(month: month, paymentType: "카드", customBGColor: customBGColor)) {
                                    Text(formattedAmount(cardSum))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(pastelExpenseColor)
                                        .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(customCardColor)
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    expandedCardMonth.wrappedValue = expandedCardMonth.wrappedValue == month ? nil : month
                                }
                            }
                            // 카드별 합계 펼침
                            if expandedCardMonth.wrappedValue == month, !cardSums.isEmpty {
                                VStack(spacing: 6) {
                                    let filteredCardNameRecords: (String) -> [Record] = { cardName in
                                        filteredMonthRecords.filter { record in
                                            let localFormatter = DateFormatter()
                                            localFormatter.dateFormat = "yyyy-MM"
                                            let recordMonth = localFormatter.string(from: record.date ?? Date())
                                            return recordMonth == month && record.type == "지출" && record.paymentType == "카드" && record.card?.name == cardName
                                        }
                                    }
                                    ForEach(cardSums.sorted(by: { $0.key < $1.key }), id: \.key) { cardName, value in
                                        let cardNameCount = filteredCardNameRecords(cardName).count
                                        NavigationLink(destination: ExpenseDetailView(month: month, paymentType: "카드", cardName: cardName, customBGColor: customBGColor)) {
                                            HStack {
                                                Label("\(NSLocalizedString(cardName, comment: "")) (\(cardNameCount)건)", systemImage: "creditcard.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                                Text(formattedAmount(value))
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(pastelExpenseColor)
                                                    .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                            }
                                            .padding(8)
                                            .background(customCardColor)
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.top, 2)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                    .padding()
                    .background(customCardColor)
                    .cornerRadius(22)
                    .shadow(color: colorScheme == .light ? pastelExpenseColor.opacity(0.10) : Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(colorScheme == .light ? pastelExpenseColor.opacity(0.18) : pastelExpenseColor.opacity(0.35), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 16)
                    .animation(.spring(), value: totals.values.reduce(0, +))
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    func filterMonths<T>(dict: [String: T]) -> [String: T] {
        let months = dict.keys.sorted()
        let filteredKeys: [String]
        switch selectedPeriod {
        case "3개월":
            filteredKeys = Array(months.suffix(3))
        case "6개월":
            filteredKeys = Array(months.suffix(6))
        case "1년":
            filteredKeys = Array(months.suffix(12))
        default:
            filteredKeys = months
        }
        return dict.filter { filteredKeys.contains($0.key) }
    }

    // 월별 지출 레코드 미리 그룹핑
    var monthRecordMap: [String: [Record]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let expenseRecords = records.filter { $0.type == "지출" }
        return Dictionary(grouping: expenseRecords) { record in
            dateFormatter.string(from: record.date ?? Date())
        }
    }

    private func moveToPrevPeriod() {
        if let idx = periodOptions.firstIndex(of: selectedPeriod), idx > 0 {
            selectedPeriod = periodOptions[idx - 1]
        }
    }

    private func moveToNextPeriod() {
        if let idx = periodOptions.firstIndex(of: selectedPeriod), idx < periodOptions.count - 1 {
            selectedPeriod = periodOptions[idx + 1]
        }
    }
}

// 월별로 수입/지출 막대가 나란히 그룹핑되어 표시되는 차트
struct GroupedBarChartView: View {
    let data: [MonthValue]
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        let monthCount = Set(data.map { $0.month }).count
        let chartWidth: CGFloat = monthCount > 3
            ? UIScreen.main.bounds.width * CGFloat(monthCount) / 3
            : UIScreen.main.bounds.width - 40
        let colorMap: [String: Color] = [
            NSLocalizedString("income", comment: ""): pastelIncomeColor,
            NSLocalizedString("expense", comment: ""): pastelExpenseColor
        ]
        let maxValue = data.map { $0.value }.max() ?? 0
        let yMax = ceil(maxValue / 500_000) * 500_000 + 500_000
        return VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.pink.opacity(0.13), lineWidth: 1.5)
                    )
                    .frame(height: 340)
                Chart {
                    ForEach(data, id: \ .id) { d in
                        let barColor = colorMap[d.type] ?? .gray
                        let label = d.value > 0 ? formattedCompactNumber(d.value) : ""
                        BarMark(
                            x: .value(NSLocalizedString("month", comment: "월"), d.month),
                            y: .value(NSLocalizedString("amount", comment: "금액"), d.value)
                        )
                        .position(by: .value("Type", d.type))
                        .foregroundStyle(barColor)
                        .annotation(position: .top, alignment: .center) {
                            VStack(spacing: 2) {
                                if d.value > 0 {
                                    Text(label)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(barColor)
                                }
                                if d.count > 0 {
                                    Text("\(d.count)건")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .chartForegroundStyleScale(
                    KeyValuePairs(dictionaryLiteral:
                        (NSLocalizedString("income", comment: ""), pastelIncomeColor),
                        (NSLocalizedString("expense", comment: ""), pastelExpenseColor)
                    )
                )
                .chartYScale(domain: 0...yMax)
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel() {
                            if let doubleValue = value.as(Double.self) {
                                let yLabel = formattedCompactNumber(doubleValue)
                                Text(yLabel)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel() {
                            if let str = value.as(String.self) {
                                let xLabel = str
                                Text(xLabel)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(colorScheme == .light ? .black : .white)
                            }
                        }
                    }
                }
            }
            .frame(width: chartWidth, height: 340)
            .padding(.vertical, 16)
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(pastelIncomeColor).frame(width: 12, height: 12)
                    Text(NSLocalizedString("income", comment: ""))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(pastelIncomeColor)
                }
                HStack(spacing: 6) {
                    Circle().fill(pastelExpenseColor).frame(width: 12, height: 12)
                    Text(NSLocalizedString("expense", comment: ""))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(pastelExpenseColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

