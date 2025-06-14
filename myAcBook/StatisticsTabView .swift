import CoreData
import SwiftUI
import Charts
import Foundation

struct AccordionState {
    var expandedMonth: String? = nil
    var expandedCash: String? = nil
    var expandedCard: String? = nil
    var expandedCardType: [String: String?] = [:] // [month: 카드이름]
}

private func getSortedMonths(
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

struct StatRowViewModern: View {
    let key: String
    let value: Double
    let color: Color
    let cardNameMap: [UUID: String]
    let formattedAmount: (Double) -> String
    let allRecords: [Record]
    let formattedDate: (Date) -> String
    @State private var isExpanded: Bool = false
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 15))
                        .foregroundColor(.green.opacity(0.7))
                    Text(cardNameMap.first(where: { $0.value == key })?.value ?? key)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color("HighlightColor"))
                    Spacer()
                    Text(formattedAmount(value))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            if isExpanded {
                CardRecordListViewModern(
                    records: allRecords.filter { $0.categoryRelation?.name == key },
                    formattedAmount: formattedAmount,
                    formattedDate: formattedDate
                )
            }
        }
    }
}

struct CategorySectionView: View {
    let monthlyCategoryTotals: [String: [String: Double]]
    let color: Color
    let sectionTitleSuffix: String
    let formattedAmount: (Double) -> String
    let isAscendingSort: Bool
    let onToggleSort: () -> Void
    let allCards: [Card]
    let allRecords: [Record]
    let formattedDate: (Date) -> String
    let backgroundColor: Color
    @Binding var expandedMonth: String?
    var body: some View {
        let sortedMonths = getSortedMonths(from: monthlyCategoryTotals, ascending: isAscendingSort)
        let cardNameMap: [UUID: String] = Dictionary(uniqueKeysWithValues: allCards.compactMap { card in
            guard let id = card.id, let name = card.name else { return nil }
            return (id, name)
        })
        let monthTuples: [(month: String, totals: [String: Double], monthSum: Double)] = sortedMonths.map { month in
            let totals = monthlyCategoryTotals[month] ?? [:]
            let monthSum = totals.values.reduce(0, +)
            return (month, totals, monthSum)
        }
        if monthlyCategoryTotals.isEmpty {
            VStack {
                Spacer()
                Text(NSLocalizedString("no_data", comment: "표시할 데이터가 없습니다")).appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .background(backgroundColor)
        } else {
            ScrollView {
                VStack(spacing: 28) {
                    ForEach(monthTuples, id: \.month) { tuple in
                        let month = tuple.month
                        let totals = tuple.totals
                        let monthSum = tuple.monthSum
                        VStack(spacing: 0) {
                            Button(action: { withAnimation { expandedMonth = expandedMonth == month ? nil : month } }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color.blue.opacity(0.7))
                                    Text("\(month)월 합계")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.primary)
                                    Spacer()
                                    Text(formattedAmount(monthSum))
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red:0.3, green:0.45, blue:0.7))
                                    Image(systemName: expandedMonth == month ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(red:0.93, green:0.98, blue:1.0), Color(red:0.9, green:1.0, blue:0.95)]),
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 4)
                            }
                            if expandedMonth == month {
                                VStack(spacing: 10) {
                                    let monthKeys = Array(totals.keys)
                                    ForEach(monthKeys.indices, id: \.self) { index in
                                        let key = monthKeys[index]
                                        let value = totals[key] ?? 0
                                        StatRowViewModern(
                                            key: key,
                                            value: value,
                                            color: Color(red:0.3, green:0.45, blue:0.7),
                                            cardNameMap: cardNameMap,
                                            formattedAmount: formattedAmount,
                                            allRecords: allRecords,
                                            formattedDate: formattedDate
                                        )
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white.opacity(0.7))
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                )
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(backgroundColor)
        }
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
    let formattedAmount: (Double) -> String
    let formattedDate: (Date) -> String
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
    @State private var accordionState = AccordionState()
    @State private var selectedBarMonth: String? = nil
    let allRecords: [Record]

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

    var body: some View {
        NavigationStack {
            VStack {
                contentView
            }
            .background(customBGColor)
            .onChange(of: selectedStatTab) { _, _ in
                if let month = selectedBarMonth {
                    accordionState.expandedMonth = month
                    selectedBarMonth = nil
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        VStack {
            Picker(NSLocalizedString("statistics_type", comment: "통계 종류"), selection: $selectedStatTab) {
                Text(NSLocalizedString("graph", comment: "그래프")).tag(NSLocalizedString("graph", comment: "그래프"))
                Text(NSLocalizedString("expense", comment: "지출")).tag(NSLocalizedString("expense", comment: "지출"))
                Text(NSLocalizedString("income", comment: "수입")).tag(NSLocalizedString("income", comment: "수입"))
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            if selectedStatTab == NSLocalizedString("income", comment: "수입") {
                CategorySectionView(
                    monthlyCategoryTotals: monthlyCategoryIncomeTotals,
                    color: Color("IncomeColor"),
                    sectionTitleSuffix: NSLocalizedString("income", comment: ""),
                    formattedAmount: formattedAmount,
                    isAscendingSort: isAscendingSort,
                    onToggleSort: { isAscendingSort.toggle() },
                    allCards: allCards,
                    allRecords: allRecords,
                    formattedDate: formattedDate,
                    backgroundColor: customBGColor,
                    expandedMonth: $accordionState.expandedMonth
                )
                .background(customBGColor).ignoresSafeArea()
            } else if selectedStatTab == NSLocalizedString("expense", comment: "지출") {
                ExpenseAccordionSectionView(
                    monthlyCategoryTotals: monthlyCategoryExpenseTotals,
                    monthlyCardExpenseTotals: monthlyCardExpenseTotals,
                    formattedAmount: formattedAmount,
                    formattedDate: formattedDate,
                    accordionState: $accordionState,
                    allRecords: allRecords,
                    selectedBarMonth: $selectedBarMonth
                )
                .background(customBGColor).ignoresSafeArea()
            } else if selectedStatTab == NSLocalizedString("graph", comment: "그래프") {
                graphSection
            }
        }
    }

    private var graphSection: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("monthly_stats_title", comment: "월별 수입/지출 통계 그래프")).appSectionTitle()
                    .padding(.horizontal, 20)
                Toggle(NSLocalizedString("show_bar_labels", comment: "막대 금액 표시"), isOn: $showBarAnnotations)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .toggleStyle(.switch)
                    .padding(.horizontal, 20)
                Group {
                    if monthlyIncomeTotals.isEmpty && monthlyExpenseTotals.isEmpty {
                        VStack {
                            Spacer()
                            Text(NSLocalizedString("no_data", comment: "표시할 데이터가 없습니다")).appBody()
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .background(customBGColor)
                    } else {
                        GeometryReader { geometry in
                            let barCount = max(sortedMonths.count, 1)
                            let rawCardWidth = geometry.size.width - 40
                            let cardWidth = max(rawCardWidth, 0)
                            let chartWidth: CGFloat = {
                                switch barCount {
                                case 1:
                                    return max(cardWidth * 0.6, 0)
                                case 2:
                                    return max(cardWidth * 0.8, 0)
                                case 3:
                                    return max(cardWidth * 0.9, 0)
                                default:
                                    return max(min(CGFloat(barCount) * 90, cardWidth), 0)
                                }
                            }()
                            let chartData: [(month: String, displayMonth: String, income: Double, expense: Double)] = sortedMonths.map { month in
                                let income = monthlyIncomeTotals[month] ?? 0
                                let expense = monthlyExpenseTotals[month] ?? 0
                                let displayMonth = month.replacingOccurrences(of: "-", with: ".")
                                return (month, displayMonth, income, expense)
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: colorScheme == .light
                                                ? [Color(red:0.92, green:1.0, blue:0.97, opacity:0.85), Color(red:0.95, green:0.95, blue:1.0, opacity:0.82), Color(red:1.0, green:0.95, blue:0.98, opacity:0.80)]
                                                        : [Color(red:0.18, green:0.2, blue:0.28, opacity:0.96), Color(red:0.22, green:0.24, blue:0.32, opacity:0.94)]
                                            ),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 12)
                                    .frame(width: safeWidth(cardWidth), height: 350)
                                    .padding(.horizontal, 20)
                                HStack {
                                    Spacer(minLength: 0)
                                    ZStack {
                                        Chart {
                                            ForEach(chartData, id: \.month) { data in
                                                BarMark(
                                                    x: .value("Month", data.displayMonth),
                                                    y: .value(NSLocalizedString("amount", comment: "금액"), data.income)
                                                )
                                                .cornerRadius(12)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color(red:0.7, green:0.85, blue:1.0), Color(red:0.9, green:1.0, blue:0.95)]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .annotation(position: .overlay, alignment: .top) {
                                                    if showBarAnnotations {
                                                        Text(formattedCompactNumber(data.income))
                                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                                            .foregroundColor(Color(red:0.3, green:0.45, blue:0.7))
                                                            .padding(.top, -10)
                                                            .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
                                                    }
                                                }
                                                BarMark(
                                                    x: .value("Month", data.displayMonth),
                                                    y: .value(NSLocalizedString("amount", comment: "금액"), data.expense)
                                                )
                                                .cornerRadius(12)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color(red:1.0, green:0.8, blue:0.85), Color(red:0.95, green:0.7, blue:0.8)]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .annotation(position: .overlay, alignment: .top) {
                                                    if showBarAnnotations {
                                                        Text(formattedCompactNumber(data.expense))
                                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                                            .foregroundColor(Color(red:0.7, green:0.4, blue:0.5))
                                                            .padding(.top, -10)
                                                            .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks(position: .leading) { value in
                                            AxisGridLine()
                                            AxisTick()
                                            AxisValueLabel {
                                                if let doubleValue = value.as(Double.self) {
                                                    Text(formattedCompactNumber(doubleValue))
                                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.top, 36)
                                    .padding(.bottom, 12)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.85), value: monthlyIncomeTotals)
                                    .chartOverlay { proxy in
                                        GeometryReader { geo in
                                            if proxy.plotFrame != nil {
                                                Rectangle().fill(Color.clear).contentShape(Rectangle())
                                                    .gesture(
                                                        DragGesture(minimumDistance: 0)
                                                            .onEnded { value in
                                                                let location = value.location
                                                                if let (month, isIncome) = findBarAt(location: location, proxy: proxy, geo: geo, chartData: chartData) {
                                                                    selectedBarMonth = month
                                                                    selectedStatTab = isIncome ? NSLocalizedString("income", comment: "수입") : NSLocalizedString("expense", comment: "지출")
                                                                }
                                                            }
                                                    )
                                            }
                                        }
                                    }
                                }
                                .frame(width: safeWidth(chartWidth), height: 310)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                .frame(height: 370)
                HStack(spacing: 18) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: colorScheme == .light ? [Color(red:0.7, green:0.85, blue:1.0), Color(red:0.9, green:1.0, blue:0.95)] : [Color(red:0.3, green:0.45, blue:0.7), Color(red:0.5, green:0.6, blue:0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 12, height: 12)
                        Text(NSLocalizedString("income", comment: ""))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: colorScheme == .light ? [Color(red:1.0, green:0.8, blue:0.85), Color(red:0.95, green:0.7, blue:0.8)] : [Color(red:0.5, green:0.3, blue:0.4), Color(red:0.7, green:0.4, blue:0.5)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 12, height: 12)
                        Text(NSLocalizedString("expense", comment: ""))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            Spacer()
        }
    }

    func formattedCompactNumber(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        switch absValue {
        case 1_000_000_000...:
            return "\(sign)₩\(String(format: "%.1f", absValue / 1_000_000_000))" + NSLocalizedString("unit_billion", comment: "억")
        case 10_000_000...:
            return "\(sign)₩\(String(format: "%.0f", absValue / 10_000_000))" + NSLocalizedString("unit_ten_million", comment: "천만")
        case 1_000_000...:
            return "\(sign)₩\(String(format: "%.1f", absValue / 1_000_000))" + NSLocalizedString("unit_million", comment: "백만")
        case 10_000...:
            return "\(sign)₩\(String(format: "%.0f", absValue / 10_000))" + NSLocalizedString("unit_ten_thousand", comment: "만")
        case 1_000...:
            return "\(sign)₩\(String(format: "%.1f", absValue / 1_000))" + NSLocalizedString("unit_thousand", comment: "천")
        default:
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "KRW"
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "\(sign)₩\(Int(absValue))"
        }
    }

    @ViewBuilder
    private func ExpenseAccordionSectionView(
        monthlyCategoryTotals: [String: [String: Double]],
        monthlyCardExpenseTotals: [String: [String: Double]],
        formattedAmount: @escaping (Double) -> String,
        formattedDate: @escaping (Date) -> String,
        accordionState: Binding<AccordionState>,
        allRecords: [Record],
        selectedBarMonth: Binding<String?>
    ) -> some View {
        ScrollView {
            let sortedMonths = getSortedMonths(from: monthlyCategoryTotals, ascending: false)
            let monthTuples: [(month: String, allTotals: [String: Double], cardTotals: [String: Double], cashTotals: [String: Double], cashSum: Double, cardSum: Double, monthSum: Double)] = sortedMonths.map { month in
                let allTotals = monthlyCategoryTotals[month] ?? [:]
                let cardTotals = monthlyCardExpenseTotals[month] ?? [:]
                let cashTotals = allTotals.filter { key in !(cardTotals.keys.contains(key.key)) }
                let cashSum = cashTotals.values.reduce(0, +)
                let cardSum = cardTotals.values.reduce(0, +)
                let monthSum = allTotals.values.reduce(0, +)
                return (month, allTotals, cardTotals, cashTotals, cashSum, cardSum, monthSum)
            }
            VStack(spacing: 28) {
                ForEach(monthTuples, id: \.month) { tuple in
                    let month = tuple.month
                    let cardTotals = tuple.cardTotals
                    let cashTotals = tuple.cashTotals
                    let cashSum = tuple.cashSum
                    let cardSum = tuple.cardSum
                    let monthSum = tuple.monthSum
                    VStack(spacing: 0) {
                        Button(action: { withAnimation { accordionState.wrappedValue.expandedMonth = accordionState.wrappedValue.expandedMonth == month ? nil : month } }) {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color.blue.opacity(0.7))
                                Text("\(month)월 합계")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.primary)
                                Spacer()
                                Text(formattedAmount(monthSum))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("ExpenseColor"))
                                Image(systemName: accordionState.wrappedValue.expandedMonth == month ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(red:0.95, green:0.98, blue:1.0), Color(red:1.0, green:0.95, blue:0.98)]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                        if accordionState.wrappedValue.expandedMonth == month {
                            VStack(spacing: 18) {
                                Button(action: { withAnimation { accordionState.wrappedValue.expandedCash = accordionState.wrappedValue.expandedCash == month ? nil : month } }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "banknote")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.green.opacity(0.7))
                                        Text("현금 합계")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        Spacer()
                                        Text(formattedAmount(cashSum))
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(Color("ExpenseColor"))
                                        Image(systemName: accordionState.wrappedValue.expandedCash == month ? "chevron.up" : "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.green.opacity(0.08))
                                    )
                                }
                                if accordionState.wrappedValue.expandedCash == month {
                                    VStack(alignment: .leading, spacing: 10) {
                                        let cashKeys = Array(cashTotals.keys)
                                        ForEach(cashKeys, id: \.self) { key in
                                            HStack {
                                                Text(key)
                                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text(formattedAmount(cashTotals[key] ?? 0))
                                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                    .foregroundColor(Color("ExpenseColor"))
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 18)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.white.opacity(0.7))
                                            )
                                        }
                                    }
                                    .background(Color.green.opacity(0.05))
                                    .cornerRadius(12)
                                    .padding(.horizontal, 8)
                                    .padding(.bottom, 8)
                                }
                                Button(action: { withAnimation { accordionState.wrappedValue.expandedCard = accordionState.wrappedValue.expandedCard == month ? nil : month } }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "creditcard")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.purple.opacity(0.7))
                                        Text("카드 합계")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        Spacer()
                                        Text(formattedAmount(cardSum))
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(Color("ExpenseColor"))
                                        Image(systemName: accordionState.wrappedValue.expandedCard == month ? "chevron.up" : "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.purple.opacity(0.08))
                                    )
                                }
                                if accordionState.wrappedValue.expandedCard == month {
                                    VStack(spacing: 10) {
                                        let cardKeys = Array(cardTotals.keys)
                                        ForEach(cardKeys, id: \.self) { cardName in
                                            CardAccordionView(
                                                month: month,
                                                cardName: cardName,
                                                cardTotal: cardTotals[cardName] ?? 0,
                                                expanded: accordionState.wrappedValue.expandedCardType[month] == cardName,
                                                onToggle: { withAnimation { accordionState.wrappedValue.expandedCardType[month] = accordionState.wrappedValue.expandedCardType[month] == cardName ? nil : cardName } },
                                                cardRecords: cardRecordsFor(month: month, cardName: cardName, allRecords: allRecords),
                                                formattedAmount: formattedAmount,
                                                formattedDate: formattedDate,
                                                accordionState: accordionState
                                            )
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.7))
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private func cardRecordsFor(month: String, cardName: String, allRecords: [Record]) -> [Record] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let filteredByMonth = allRecords.filter { record in
            guard let recordDate = record.date else { return false }
            let recordMonth = dateFormatter.string(from: recordDate)
            return recordMonth == month
        }
        return filteredByMonth.filter { record in
            (record.card?.name ?? "") == cardName
        }
    }

    private func safeWidth(_ value: CGFloat) -> CGFloat {
        if value.isNaN || value.isInfinite || value < 0 {
            return 0
        }
        return value
    }

    private func findBarAt(location: CGPoint, proxy: ChartProxy, geo: GeometryProxy, chartData: [(month: String, displayMonth: String, income: Double, expense: Double)]) -> (String, Bool)? {
        guard let plotFrame = proxy.plotFrame else { return nil }
        let origin = geo[plotFrame].origin
        let size = geo[plotFrame].size
        let x = location.x - origin.x
        let barWidth = size.width / CGFloat(max(chartData.count, 1))
        let index = Int((x / max(barWidth, 1)).rounded(.down))
        guard index >= 0 && index < chartData.count else { return nil }
        let y = location.y - origin.y
        let isIncome = y < size.height / 2
        return (chartData[index].month, isIncome)
    }
}

struct CardRecordListViewModern: View {
    let records: [Record]
    let formattedAmount: (Double) -> String
    let formattedDate: (Date) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(records) { record in
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                .foregroundColor(.blue.opacity(0.7))
                            Text(formattedDate(record.date ?? Date()))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "tag")
                                .font(.system(size: 13))
                                .foregroundColor(.pink.opacity(0.7))
                            Text(record.categoryRelation?.name ?? "-")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(Color("HighlightColor"))
                        }
                        if let detail = record.detail, !detail.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray.opacity(0.7))
                                Text(detail)
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formattedAmount(record.amount))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color("ExpenseColor"))
                        if let payment = record.paymentType {
                            HStack(spacing: 4) {
                                Image(systemName: payment == "카드" ? "creditcard" : "banknote")
                                    .font(.system(size: 13))
                                    .foregroundColor(payment == "카드" ? .purple.opacity(0.7) : .green.opacity(0.7))
                                Text(payment)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(payment == "카드" ? .purple : .green)
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }
}

struct CardAccordionView: View {
    let month: String
    let cardName: String
    let cardTotal: Double
    let expanded: Bool
    let onToggle: () -> Void
    let cardRecords: [Record]
    let formattedAmount: (Double) -> String
    let formattedDate: (Date) -> String
    let accordionState: Binding<AccordionState>
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.purple.opacity(0.7))
                    Text(cardName)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                    Spacer()
                    Text(formattedAmount(cardTotal))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color("ExpenseColor"))
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 28)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.07))
                )
            }
            if expanded {
                CardRecordListViewModern(records: cardRecords, formattedAmount: formattedAmount, formattedDate: formattedDate)
            }
        }
    }
}
