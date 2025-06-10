import CoreData
import SwiftUI
import Charts

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
                    allCards: allCards
                )
                .background(customBGColor).ignoresSafeArea()
            } else if selectedStatTab == NSLocalizedString("expense", comment: "지출") {
                VStack {
                    Picker("Expense View", selection: $selectedExpenseView) {
                        Text(NSLocalizedString("all", comment: "전체")).tag("all")
                        Text(NSLocalizedString("cash", comment: "현금")).tag("cash")
                        Text(NSLocalizedString("card", comment: "카드")).tag("card")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    let filteredTotals: [String: [String: Double]] = {
                        switch selectedExpenseView {
                        case "cash":
                            var cashTotals: [String: [String: Double]] = [:]
                            for (month, categories) in monthlyCategoryExpenseTotals {
                                let cashOnlyCategories = categories.filter { categoryName in
                                    // Check if the same category appears in card data; if not, it's considered cash
                                    !(monthlyCardExpenseTotals[month]?.keys.contains(categoryName.key) ?? false)
                                }
                                cashTotals[month] = cashOnlyCategories
                            }
                            return cashTotals
                        case "card":
                            return monthlyCardExpenseTotals
                        default: // "all"
                            var combined = monthlyCategoryExpenseTotals
                            for (month, cardData) in monthlyCardExpenseTotals {
                                for (card, amount) in cardData {
                                    combined[month, default: [:]][card, default: 0] += amount
                                }
                            }
                            return combined
                        }
                    }()

                    CategorySectionView(
                        monthlyCategoryTotals: filteredTotals,
                        color: Color("ExpenseColor"),
                        sectionTitleSuffix: NSLocalizedString(selectedExpenseView, comment: ""),
                        formattedAmount: formattedAmount,
                        isAscendingSort: isAscendingSort,
                        onToggleSort: { isAscendingSort.toggle() },
                        allCards: allCards
                    )
                    .background(customBGColor).ignoresSafeArea()
                }
            } else if selectedStatTab == NSLocalizedString("graph", comment: "그래프") {
                VStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("monthly_stats_title", comment: "월별 수입/지출 통계 그래프")).appSectionTitle()

                        Toggle(NSLocalizedString("show_bar_labels", comment: "막대 금액 표시"), isOn: $showBarAnnotations)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .toggleStyle(.switch)
                            .padding(.horizontal)

                        if monthlyIncomeTotals.isEmpty && monthlyExpenseTotals.isEmpty {
                            VStack {
                                Spacer()
                                Text(NSLocalizedString("no_data", comment: "표시할 데이터가 없습니다")).appBody()
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(maxHeight: .infinity)
                            .background(customBGColor)
                        } else {
                            ScrollView(.horizontal) {
                                Chart {
                                    ForEach(sortedMonths, id: \.self) { month in
                                        let income = monthlyIncomeTotals[month] ?? 0
                                        let expense = monthlyExpenseTotals[month] ?? 0

                                        BarMark(
                                            x: .value("Month", month),
                                            y: .value(NSLocalizedString("amount", comment: "금액"), income)
                                        )
                                        .position(by: .value(NSLocalizedString("type", comment: "종류"), NSLocalizedString("income", comment: "")))
                                        .foregroundStyle(Color("IncomeColor"))
                                        .annotation(position: .top) {
                                            if showBarAnnotations {
                                                Text(formattedCompactNumber(income)).appBody()
                                            }
                                        }

                                        BarMark(
                                            x: .value("Month", month),
                                            y: .value(NSLocalizedString("amount", comment: "금액"), expense)
                                        )
                                        .position(by: .value(NSLocalizedString("type", comment: "종류"), NSLocalizedString("expense", comment: "")))
                                        .foregroundStyle(Color("ExpenseColor"))
                                        .annotation(position: .top) {
                                            if showBarAnnotations {
                                                Text(formattedCompactNumber(expense)).appBody()
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
                                                Text(formattedCompactNumber(doubleValue)).appBody()
                                            }
                                        }
                                    }
                                }
                                .frame(width: CGFloat(sortedMonths.count) * 80, height: 280)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color("IncomeColor"))
                                        .frame(width: 10, height: 10)
                                    Text(NSLocalizedString("income", comment: ""))
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                }
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color("ExpenseColor"))
                                        .frame(width: 10, height: 10)
                                    Text(NSLocalizedString("expense", comment: ""))
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                    Spacer()
                }
            }
        }
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
        monthlyCategoryTotals: [String: [String: Double]],
        color: Color,
        sectionTitleSuffix: String,
        formattedAmount: @escaping (Double) -> String,
        isAscendingSort: Bool,
        onToggleSort: @escaping () -> Void,
        allCards: [Card]
    ) -> some View {
        let sortedMonths = getSortedMonths(from: monthlyCategoryTotals, ascending: isAscendingSort)
        let cardNameMap: [UUID: String] = Dictionary(uniqueKeysWithValues: allCards.compactMap { card in
            guard let id = card.id, let name = card.name else { return nil }
            return (id, name)
        })

        if monthlyCategoryTotals.isEmpty {
            VStack {
                Spacer()
                Text(NSLocalizedString("no_data", comment: "표시할 데이터가 없습니다")).appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .background(customBGColor)
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(sortedMonths, id: \.self) { month in
                        StatMonthSectionView(
                            month: month,
                            totals: monthlyCategoryTotals[month] ?? [:],
                            color: color,
                            cardNameMap: cardNameMap,
                            formattedAmount: formattedAmount,
                            sectionTitleSuffix: sectionTitleSuffix,
                            isAscendingSort: isAscendingSort,
                            onToggleSort: onToggleSort
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(customBGColor)
        }
    }

    struct StatMonthSectionView: View {
        let month: String
        let totals: [String: Double]
        let color: Color
        let cardNameMap: [UUID: String]
        let formattedAmount: (Double) -> String
        let sectionTitleSuffix: String
        let isAscendingSort: Bool
        let onToggleSort: () -> Void
        @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
        @Environment(\.colorScheme) var colorScheme
        var customLightCardColor: Color { Color(UIColor(hex: customLightCardColorHex)) }
        var body: some View {
            let keys = Array(totals.keys)
            let values = keys.map { totals[$0] ?? 0 }
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("\(month) \(NSLocalizedString("month_unit", comment: "월")) \(sectionTitleSuffix)").appSectionTitle()
                    Spacer()
                    Image(systemName: isAscendingSort ? "arrow.up" : "arrow.down")
                        .font(.system(size: 13))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onToggleSort()
                }
                Text(String(format: NSLocalizedString("total_sum", comment: "총 합계"), formattedAmount(values.reduce(0, +)))).appBody()
                VStack(spacing: 0) {
                    ForEach(keys.indices, id: \.self) { index in
                        if index != 0 {
                            Divider()
                                .padding(.vertical, 2)
                        }
                        let key = keys[index]
                        StatRowView(
                            key: key,
                            value: values[index],
                            color: color,
                            cardNameMap: cardNameMap,
                            formattedAmount: formattedAmount
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(colorScheme == .light ? customLightCardColor : Color("SectionBGColor"))
                )
                .padding(.horizontal, 4)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .padding(.vertical, 8)
        }
    }

    struct StatRowView: View {
        let key: String
        let value: Double
        let color: Color
        let cardNameMap: [UUID: String]
        let formattedAmount: (Double) -> String
        @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
        @Environment(\.colorScheme) var colorScheme
        var customLightCardColor: Color { Color(UIColor(hex: customLightCardColorHex)) }
        var body: some View {
            HStack {
                Text(cardNameMap.first(where: { $0.value == key })?.value ?? key).appBody()
                Spacer()
                Text(formattedAmount(value)).appBody()
                    .foregroundColor(color)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .light ? customLightCardColor : Color("SectionBGColor"))
            )
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
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
}
