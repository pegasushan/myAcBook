import SwiftUI
import Charts

struct ChartView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Record.category, ascending: true)],
        animation: .default)
    private var records: FetchedResults<Record>

    var body: some View {
        VStack {
            if groupedRecords.isEmpty {
                Text(NSLocalizedString("no_data", comment: "데이터가 없습니다."))
                    .foregroundColor(.secondary)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
            } else {
                Chart {
                    ForEach(groupedRecords, id: \.category) { group in
                        BarMark(
                            x: .value(NSLocalizedString("category", comment: "카테고리"), group.category),
                            y: .value(NSLocalizedString("amount", comment: "금액"), group.totalAmount)
                        )
                        .foregroundStyle(by: .value(NSLocalizedString("category", comment: "카테고리"), group.category))
                    }
                }
                .chartLegend(.visible)
                .frame(height: 300)
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(NSLocalizedString("spending_stats", comment: "소비 통계 📊"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
        }
    }

    // ✨ 지출만 그룹핑
    private var groupedRecords: [CategoryGroup] {
        let expenseRecords = records.filter { $0.type == "지출" }
        let grouped = Dictionary(grouping: expenseRecords) { $0.category ?? NSLocalizedString("etc", comment: "기타") }
        return grouped.map { (category, records) in
            CategoryGroup(category: category, totalAmount: records.reduce(0) { $0 + $1.amount })
        }
    }
}

struct CategoryGroup {
    var category: String
    var totalAmount: Double
}
