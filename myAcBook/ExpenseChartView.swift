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

// formattedCompactNumber 함수가 필요하다면 아래처럼 임시로 추가
private func formattedCompactNumber(_ value: Double) -> String {
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