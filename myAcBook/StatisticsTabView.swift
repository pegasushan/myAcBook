import CoreData
import SwiftUI
import Charts

struct ExpenseDetailView: View {
    let month: String
    var paymentType: String? = nil
    var cardName: String? = nil
    var customBGColor: Color = Color(UIColor(named: "customLightBGColor") ?? .yellow)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Record.date, ascending: false)],
        animation: .default
    ) private var records: FetchedResults<Record>

    var detailTitle: String {
        var title = "\(month) 지출"
        if let paymentType = paymentType, let cardName = cardName {
            title += "(\(paymentType)/\(cardName))"
        } else if let paymentType = paymentType {
            title += "(\(paymentType))"
        } else if let cardName = cardName {
            title += "(\(cardName))"
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
                Text("표시할 내역이 없습니다.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(records, id: \.objectID) { record in
                            RecordRowView(
                                record: record,
                                isDeleteMode: false,
                                selectedRecords: [],
                                toggleSelection: { _ in },
                                selectedRecord: .constant(nil),
                                formattedAmount: { amount in
                                    let numberFormatter = NumberFormatter()
                                    numberFormatter.numberStyle = .decimal
                                    numberFormatter.maximumFractionDigits = 0
                                    numberFormatter.groupingSeparator = ","
                                    return numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
                                },
                                formattedDate: { date in
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "yyyy/M/d"
                                    return formatter.string(from: date)
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
    @State private var selectedPeriod: String = "3개월"
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

    private var periodOptions: [String] { ["3개월", "6개월", "1년", "전체"] }

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

            Picker("기간", selection: $selectedPeriod) {
                ForEach(periodOptions, id: \.self) { period in
                    Text(period).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)

            if selectedStatTab == NSLocalizedString("graph", comment: "그래프") {
                Text(NSLocalizedString("monthly_stats_title", comment: "월별 수입/지출 통계 그래프"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
            }

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
                        monthlyCategoryTotals: filterMonths(dict: monthlyCategoryIncomeTotals),
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
                        monthRecordMap: monthRecordMap,
                        monthlyCategoryTotals: filterMonths(dict: monthlyCategoryExpenseTotals),
                        monthlyCardExpenseTotals: filterMonths(dict: monthlyCardExpenseTotals),
                        monthlyCashExpenseTotals: filterMonths(dict: monthlyCashExpenseTotals),
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
                let filteredMonths: [String] = {
                    let months = sortedMonths
                    switch selectedPeriod {
                    case "3개월":
                        return Array(months.suffix(3))
                    case "6개월":
                        return Array(months.suffix(6))
                    case "1년":
                        return Array(months.suffix(12))
                    default:
                        return months
                    }
                }()
                VStack(alignment: .leading, spacing: 4) {
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
                                ForEach(filteredMonths, id: \.self) { month in
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
                                width: max(CGFloat(filteredMonths.count) * (barWidth + barSpacing), chartWidth),
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
                        let incomeCount = categorySums.values.reduce(0) { $0 + ( $1 > 0 ? 1 : 0 ) }
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("\(monthNumber)월 수입 합계 (\(incomeCount)건)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color("HighlightColor"))
                                    .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                Spacer()
                                Text(formattedAmount(incomeSum))
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(Color("HighlightColor"))
                                    .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : Color("HighlightColor").opacity(0.18), radius: 2, x: 0, y: 2)
                            }
                            .padding(.bottom, 2)
                            VStack(spacing: 10) {
                                ForEach(categorySums.sorted(by: { $0.key < $1.key }), id: \.key) { category, value in
                                    HStack {
                                        Label(category, systemImage: "tag.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(formattedAmount(value))
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color("HighlightColor"))
                                            .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(colorScheme == .light ? Color("customLightSectionColor").opacity(0.5) : Color("customDarkSectionColor").opacity(0.7))
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(
                            colorScheme == .light ?
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("customLightSectionColor").opacity(0.18), Color.white]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            :
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("customDarkCardColor").opacity(0.85), Color("customDarkSectionColor").opacity(0.7)]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                        )
                        .cornerRadius(22)
                        .shadow(color: colorScheme == .light ? Color("HighlightColor").opacity(0.10) : Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(colorScheme == .light ? Color("HighlightColor").opacity(0.18) : Color("HighlightColor").opacity(0.35), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 16)
                        .animation(.spring(), value: incomeSum)
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
                                    .foregroundColor(Color("HighlightColor"))
                                    .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                Spacer()
                                Text(formattedAmount(totals.values.reduce(0, +)))
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(Color("HighlightColor"))
                                    .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : Color("HighlightColor").opacity(0.18), radius: 2, x: 0, y: 2)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 2)
                        // 현금/카드 합계 카드 박스
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                NavigationLink(destination: ExpenseDetailView(month: month, paymentType: "현금", customBGColor: customBGColor)) {
                                    Label("현금 합계 (\(cashCount)건)", systemImage: "banknote")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formattedAmount(cashSum))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color("HighlightColor"))
                                        .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(colorScheme == .light ? Color("customLightSectionColor").opacity(0.5) : Color("customDarkSectionColor").opacity(0.7))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Label("카드 합계 (\(cardCount)건)", systemImage: "creditcard")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: expandedCardMonth.wrappedValue == month ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.gray)
                                NavigationLink(destination: ExpenseDetailView(month: month, paymentType: "카드", customBGColor: customBGColor)) {
                                    Text(formattedAmount(cardSum))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color("HighlightColor"))
                                        .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(colorScheme == .light ? Color("customLightSectionColor").opacity(0.5) : Color("customDarkSectionColor").opacity(0.7))
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
                                                Label("\(cardName) (\(cardNameCount)건)", systemImage: "creditcard.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                                Text(formattedAmount(value))
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(Color("HighlightColor"))
                                                    .shadow(color: colorScheme == .dark ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                                            }
                                            .padding(8)
                                            .background(colorScheme == .light ? Color("customLightSectionColor").opacity(0.5) : Color("customDarkSectionColor").opacity(0.7))
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
                    .background(
                        colorScheme == .light ?
                            LinearGradient(
                                gradient: Gradient(colors: [Color("customLightSectionColor").opacity(0.18), Color.white]),
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        :
                            LinearGradient(
                                gradient: Gradient(colors: [Color("customDarkCardColor").opacity(0.85), Color("customDarkSectionColor").opacity(0.7)]),
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                    )
                    .cornerRadius(22)
                    .shadow(color: colorScheme == .light ? Color("HighlightColor").opacity(0.10) : Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(colorScheme == .light ? Color("HighlightColor").opacity(0.18) : Color("HighlightColor").opacity(0.35), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 16)
                    .animation(.spring(), value: totals.values.reduce(0, +))
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
}

