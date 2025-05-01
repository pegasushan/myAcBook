import SwiftUI
import Charts

struct StatisticsTabView: View {
    @Binding var selectedStatTab: String
    let monthlyIncomeTotals: [String: Double]
    let monthlyExpenseTotals: [String: Double]
    let monthlyCategoryIncomeTotals: [String: [String: Double]]
    let monthlyCategoryExpenseTotals: [String: [String: Double]]
    let formattedAmount: (Double) -> String

    var body: some View {
        NavigationView {
            VStack {
                Picker("통계 종류", selection: $selectedStatTab) {
                    Text("지출").tag("지출")
                    Text("수입").tag("수입")
                    Text("그래프").tag("그래프")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedStatTab == "수입" {
                    List {
                        ForEach(Array(monthlyCategoryIncomeTotals.keys.sorted()), id: \.self) { month in
                            Section(header: VStack(alignment: .leading) {
                                Text("\(month) 월 수입")
                                Text("총 합계: \(formattedAmount(monthlyCategoryIncomeTotals[month]?.values.reduce(0, +) ?? 0))")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }) {
                                ForEach(Array(monthlyCategoryIncomeTotals[month]!.keys), id: \.self) { category in
                                    HStack {
                                        Text(category)
                                        Spacer()
                                        Text(formattedAmount(monthlyCategoryIncomeTotals[month]![category] ?? 0))
                                            .bold()
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                } else if selectedStatTab == "지출" {
                    List {
                        ForEach(Array(monthlyCategoryExpenseTotals.keys.sorted()), id: \.self) { month in
                            Section(header: VStack(alignment: .leading) {
                                Text("\(month) 월 지출")
                                Text("총 합계: \(formattedAmount(monthlyCategoryExpenseTotals[month]?.values.reduce(0, +) ?? 0))")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }) {
                                ForEach(Array(monthlyCategoryExpenseTotals[month]!.keys), id: \.self) { category in
                                    HStack {
                                        Text(category)
                                        Spacer()
                                        Text(formattedAmount(monthlyCategoryExpenseTotals[month]![category] ?? 0))
                                            .bold()
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                } else if selectedStatTab == "그래프" {
                    List {
                        Section(header: Text("월별 수입/지출 통계 그래프")) {
                            Chart {
                                ForEach(Array(monthlyIncomeTotals.keys.sorted()), id: \.self) { month in
                                    BarMark(
                                        x: .value("Month", month),
                                        y: .value("Income", monthlyIncomeTotals[month] ?? 0)
                                    )
                                    .foregroundStyle(.green)
                                }
                                ForEach(Array(monthlyExpenseTotals.keys.sorted()), id: \.self) { month in
                                    BarMark(
                                        x: .value("Month", month),
                                        y: .value("Expense", monthlyExpenseTotals[month] ?? 0)
                                    )
                                    .foregroundStyle(.red)
                                }
                            }
                            .frame(height: 250)
                        }
                    }
                }
            }
            .navigationTitle("통계 📊")
        }
    }
}
