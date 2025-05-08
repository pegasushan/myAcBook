import SwiftUI
import Charts

struct StatisticsTabView: View {
    @Binding var selectedStatTab: String
    let monthlyIncomeTotals: [String: Double]
    let monthlyExpenseTotals: [String: Double]
    let monthlyCategoryIncomeTotals: [String: [String: Double]]
    let monthlyCategoryExpenseTotals: [String: [String: Double]]
    let formattedAmount: (Double) -> String
    @State private var isAscendingSort = false
    @State private var graphOffset: Int = 0
    @State private var showBarAnnotations: Bool = true

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
        return NavigationStack {
            VStack {
                Picker("통계 종류", selection: $selectedStatTab) {
                    Text("지출").tag("지출")
                    Text("수입").tag("수입")
                    Text("그래프").tag("그래프")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedStatTab == "수입" {
                    CategorySectionView(
                        monthlyCategoryTotals: monthlyCategoryIncomeTotals,
                        color: .green,
                        sectionTitleSuffix: "수입",
                        formattedAmount: formattedAmount,
                        isAscendingSort: isAscendingSort,
                        onToggleSort: { isAscendingSort.toggle() }
                    )
                } else if selectedStatTab == "지출" {
                    CategorySectionView(
                        monthlyCategoryTotals: monthlyCategoryExpenseTotals,
                        color: .red,
                        sectionTitleSuffix: "지출",
                        formattedAmount: formattedAmount,
                        isAscendingSort: isAscendingSort,
                        onToggleSort: { isAscendingSort.toggle() }
                    )
                } else if selectedStatTab == "그래프" {
                    VStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("월별 수입/지출 통계 그래프")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .padding(.horizontal)

                            Toggle("막대 금액 표시", isOn: $showBarAnnotations)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .toggleStyle(.switch)
                                .padding(.horizontal)

                            if monthlyIncomeTotals.isEmpty && monthlyExpenseTotals.isEmpty {
                                VStack(alignment: .center, spacing: 8) {
                                    Text("표시할 데이터가 없습니다")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(height: 250, alignment: .top)
                            } else {
                                ScrollView(.horizontal) {
                                    Chart {
                                        ForEach(sortedMonths, id: \.self) { month in
                                            let income = monthlyIncomeTotals[month] ?? 0
                                            let expense = monthlyExpenseTotals[month] ?? 0

                                            BarMark(
                                                x: .value("Month", month),
                                                y: .value("금액", income)
                                            )
                                            .position(by: .value("종류", "수입"))
                                            .foregroundStyle(.green)
                                            .annotation(position: .top) {
                                                if showBarAnnotations {
                                                    Text(formattedCompactNumber(income))
                                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                                }
                                            }

                                            BarMark(
                                                x: .value("Month", month),
                                                y: .value("금액", expense)
                                            )
                                            .position(by: .value("종류", "지출"))
                                            .foregroundStyle(.red)
                                            .annotation(position: .top) {
                                                if showBarAnnotations {
                                                    Text(formattedCompactNumber(expense))
                                                        .font(.system(size: 13, weight: .regular, design: .rounded))
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
                                            .fill(Color.green)
                                            .frame(width: 10, height: 10)
                                        Text("수입")
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                    }
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 10, height: 10)
                                        Text("지출")
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
        } // <-- This is the missing closing brace
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("통계 📊")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
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
        onToggleSort: @escaping () -> Void
    ) -> some View {
        let sortedMonths = getSortedMonths(from: monthlyCategoryTotals, ascending: isAscendingSort)

        if monthlyCategoryTotals.isEmpty {
            VStack {
                Spacer()
                Text("표시할 데이터가 없습니다")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(sortedMonths, id: \.self) { month in
                    Section(header: VStack(alignment: .leading) {
                        HStack {
                            Text("\(month) 월 \(sectionTitleSuffix)")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Spacer()
                            Image(systemName: isAscendingSort ? "arrow.up" : "arrow.down")
                                .font(.system(size: 13))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onToggleSort()
                        }

                        Text("총 합계: \(formattedAmount(monthlyCategoryTotals[month]?.values.reduce(0, +) ?? 0))")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(color)
                    }) {
                        ForEach(Array(monthlyCategoryTotals[month]!.keys), id: \.self) { category in
                            HStack {
                                Text(category)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                Spacer()
                                Text(formattedAmount(monthlyCategoryTotals[month]![category] ?? 0))
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(color)
                            }
                        }
                    }
                }
            }
        }
    }
}

func formattedCompactNumber(_ value: Double) -> String {
    let absValue = abs(value)
    let sign = value < 0 ? "-" : ""

    switch absValue {
    case 1_000_000_000...:
        return "\(sign)₩\(String(format: "%.1f", absValue / 1_000_000_000))억"
    case 10_000_000...:
        return "\(sign)₩\(String(format: "%.0f", absValue / 10_000_000))천만"
    case 1_000_000...:
        return "\(sign)₩\(String(format: "%.1f", absValue / 1_000_000))백만"
    case 10_000...:
        return "\(sign)₩\(String(format: "%.0f", absValue / 10_000))만"
    case 1_000...:
        return "\(sign)₩\(String(format: "%.1f", absValue / 1_000))천"
    default:
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "KRW"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(sign)₩\(Int(absValue))"
    }
}

}
