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
                let hasIncomeData = monthlyCategoryIncomeTotals.values.flatMap { $0.values }.reduce(0, +) > 0
                if !hasIncomeData {
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
                }
            } else if selectedStatTab == NSLocalizedString("expense", comment: "지출") {
                let hasExpenseData = monthlyCategoryExpenseTotals.values.flatMap { $0.values }.reduce(0, +) > 0
                if !hasExpenseData {
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
                    ExpenseAccordionSectionView(
                        monthlyCategoryTotals: monthlyCategoryExpenseTotals,
                        monthlyCardExpenseTotals: monthlyCardExpenseTotals,
                        monthlyCashExpenseTotals: monthlyCashExpenseTotals,
                        formattedAmount: formattedAmount,
                        expandedCardMonth: $expandedCardMonth
                    )
                    .background(customBGColor).ignoresSafeArea()
                }
            } else if selectedStatTab == NSLocalizedString("graph", comment: "그래프") {
                let pastelBlue = Color(red: 0.55, green: 0.75, blue: 1.0)
                let pastelRed = Color(red: 1.0, green: 0.55, blue: 0.65)
                let screenWidth = UIScreen.main.bounds.width
                let horizontalPadding: CGFloat = 32 // 좌우 패딩 합계
                let visibleMonths = 3
                let chartWidth = screenWidth - horizontalPadding
                let barWidth: CGFloat = (chartWidth / CGFloat(visibleMonths)) * 0.6
                let barSpacing: CGFloat = (chartWidth / CGFloat(visibleMonths)) * 0.4
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("monthly_stats_title", comment: "월별 수입/지출 통계 그래프"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color("HighlightColor"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("customLightSectionColor").opacity(0.95),
                                            Color.white.opacity(0.85)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: colorScheme == .light ? Color.black.opacity(0.12) : Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.pink.opacity(0.18), lineWidth: 1.5)
                                )
                                .frame(height: 380)
                            Chart {
                                ForEach(sortedMonths, id: \.self) { month in
                                    BarMark(
                                        x: .value("Month", month),
                                        y: .value("수입", monthlyIncomeTotals[month] ?? 0)
                                    )
                                    .foregroundStyle(pastelBlue)
                                    .position(by: .value("Type", "수입"))
                                    .cornerRadius(4)
                                    .annotation(position: .top) {
                                        if let value = monthlyIncomeTotals[month], value > 0 {
                                            Text(formattedCompactNumber(value))
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(pastelBlue)
                                        }
                                    }
                                    BarMark(
                                        x: .value("Month", month),
                                        y: .value("지출", monthlyExpenseTotals[month] ?? 0)
                                    )
                                    .foregroundStyle(pastelRed)
                                    .position(by: .value("Type", "지출"))
                                    .cornerRadius(4)
                                    .annotation(position: .top) {
                                        if let value = monthlyExpenseTotals[month], value > 0 {
                                            Text(formattedCompactNumber(value))
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(pastelRed)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel() {
                                        if let doubleValue = value.as(Double.self) {
                                            Text(formattedCompactNumber(doubleValue))
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
                                            Text(str)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .frame(
                                width: max(CGFloat(sortedMonths.count) * (barWidth + barSpacing), chartWidth),
                                height: 340
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.horizontal, 8)
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Circle().fill(pastelBlue).frame(width: 12, height: 12)
                            Text(NSLocalizedString("income", comment: "")).font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(pastelBlue)
                        }
                        HStack(spacing: 6) {
                            Circle().fill(pastelRed).frame(width: 12, height: 12)
                            Text(NSLocalizedString("expense", comment: "")).font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(pastelRed)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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
        monthlyCategoryTotals: [String: [String: Double]],
        color: Color,
        sectionTitleSuffix: String,
        formattedAmount: @escaping (Double) -> String,
        isAscendingSort: Bool,
        onToggleSort: @escaping () -> Void,
        allCards: [Card]
    ) -> some View {
        let sortedMonths = getSortedMonths(from: monthlyCategoryTotals, ascending: isAscendingSort)
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
                    ForEach(sortedMonths, id: \.self) { month in
                        let categorySums = monthlyCategoryTotals[month] ?? [:]
                        let incomeSum = categorySums.values.reduce(0, +)
                        let monthNumber = month.split(separator: "-").count == 2 ? String(Int(month.split(separator: "-")[1]) ?? 0) : month
                        VStack(alignment: .leading, spacing: 16) {
                            // 월별 수입 합계
                            HStack {
                                Text("\(monthNumber)월 수입 합계")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color("IncomeColor"))
                                Spacer()
                                Text(formattedAmount(incomeSum))
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color("IncomeColor"))
                            }
                            .padding(.bottom, 2)
                            // 카테고리별 합계 카드 박스
                            VStack(spacing: 10) {
                                ForEach(categorySums.sorted(by: { $0.key < $1.key }), id: \.key) { category, value in
                                    HStack {
                                        Label(category, systemImage: "tag.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(formattedAmount(value))
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color("IncomeColor"))
                                    }
                                    .padding(10)
                                    .background(Color(red: 0.95, green: 1.0, blue: 0.95).opacity(0.7))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    func ExpenseAccordionSectionView(
        monthlyCategoryTotals: [String: [String: Double]],
        monthlyCardExpenseTotals: [String: [String: Double]],
        monthlyCashExpenseTotals: [String: Double],
        formattedAmount: @escaping (Double) -> String,
        expandedCardMonth: Binding<String?>
    ) -> some View {
        let sortedMonths = getSortedMonths(from: monthlyCategoryTotals, ascending: false)
        ScrollView {
            VStack(spacing: 28) {
                ForEach(sortedMonths, id: \.self) { month in
                    let totals = monthlyCategoryTotals[month] ?? [:]
                    let sum = totals.values.reduce(0, +)
                    let cashSum = monthlyCashExpenseTotals[month] ?? 0
                    let cardSums = monthlyCardExpenseTotals[month] ?? [:]
                    let cardSum = cardSums.values.reduce(0, +)
                    let monthNumber = month.split(separator: "-").count == 2 ? String(Int(month.split(separator: "-")[1]) ?? 0) : month
                    VStack(alignment: .leading, spacing: 16) {
                        // 월별 합계
                        HStack {
                            Text("\(monthNumber)월 합계")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color("HighlightColor"))
                            Spacer()
                            Text(formattedAmount(sum))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color("ExpenseColor"))
                        }
                        .padding(.bottom, 2)
                        // 현금/카드 합계 카드 박스
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("현금 합계", systemImage: "banknote")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                                Text(formattedAmount(cashSum))
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color("ExpenseColor"))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(red: 0.85, green: 1.0, blue: 0.95).opacity(0.7))
                            .cornerRadius(12)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Label("카드 합계", systemImage: "creditcard")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.8))
                                    Spacer()
                                    Image(systemName: expandedCardMonth.wrappedValue == month ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                Text(formattedAmount(cardSum))
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color("ExpenseColor"))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(red: 0.9, green: 0.95, blue: 1.0).opacity(0.7))
                            .cornerRadius(12)
                            .onTapGesture {
                                withAnimation {
                                    expandedCardMonth.wrappedValue = expandedCardMonth.wrappedValue == month ? nil : month
                                }
                            }
                        }
                        // 카드별 합계 펼침
                        if expandedCardMonth.wrappedValue == month, !cardSums.isEmpty {
                            VStack(spacing: 6) {
                                ForEach(cardSums.sorted(by: { $0.key < $1.key }), id: \.key) { cardName, value in
                                    HStack {
                                        Label(cardName, systemImage: "creditcard.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(formattedAmount(value))
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color("ExpenseColor"))
                                    }
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.top, 2)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
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

