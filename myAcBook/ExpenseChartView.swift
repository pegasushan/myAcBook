import SwiftUI
import Charts
import Foundation

struct ExpenseChartView: View {
    let data: [ChartBarData]
    let showBarAnnotations: Bool
    let onBarTap: (String) -> Void
    var body: some View {
        Chart {
            ForEach(data) { d in
                BarMark(
                    x: .value("Month", d.month),
                    y: .value(NSLocalizedString("amount", comment: "금액"), d.expense)
                )
                .cornerRadius(6)
                .foregroundStyle(Color("ExpenseColor"))
                .annotation(position: .top) {
                    if showBarAnnotations {
                        Text(formattedCompactNumber(d.expense))
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .frame(height: 140)
    }
} 