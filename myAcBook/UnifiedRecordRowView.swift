import SwiftUI
import CoreData

struct UnifiedRecordRowView: View {
    let record: Record
    let isDeleteMode: Bool
    let selected: Bool
    let onSelect: () -> Void
    let onTap: () -> Void
    let colorForCategory: (String?) -> Color
    let isIncome: (Record) -> Bool
    let customSectionColor: Color
    let customBGColor: Color
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    var customCardColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightCardColorHex)) : Color(UIColor(hex: customDarkCardColorHex))
    }
    var body: some View {
        let isCard = (record.paymentType == "카드" || record.paymentType == "card" || record.paymentType == NSLocalizedString("card", comment: "카드"))
        let isCash = (record.paymentType == "현금" || record.paymentType == "cash" || record.paymentType == NSLocalizedString("cash", comment: "현금"))
        HStack(spacing: 0) {
            if isDeleteMode {
                Button(action: onSelect) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selected ? .pink : .gray)
                        .font(.system(size: 22))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 4)
            }
            Text(NSLocalizedString(record.paymentType ?? "-", comment: ""))
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(isCard ? Color.blue.opacity(0.7) : isCash ? Color.green.opacity(0.7) : Color.gray.opacity(0.7))
                )
                .frame(width: 56, alignment: .center)
            Text(record.categoryRelation?.name ?? "-")
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? colorForCategory(record.categoryRelation?.name).opacity(0.95) : colorForCategory(record.categoryRelation?.name))
                .frame(width: 70, alignment: .leading)
            Text(record.detail?.isEmpty == false ? record.detail! : "-")
                .font(.footnote)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(5)
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.92) : .primary)
            Text(record.amount > 0 ? "\(record.amount, specifier: "%.0f")" : "-")
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? (isIncome(record) ? Color.cyan : Color.pink) : (isIncome(record) ? Color.blue : Color.red))
                .frame(width: 70, alignment: .trailing)
                .padding(.trailing, 2)
        }
        .frame(height: 29)
        .padding(.vertical, 0)
        .padding(.horizontal, 0)
        .background(colorScheme == .light ? customBGColor : customSectionColor)
        .font(.system(size: 10))
        .contentShape(Rectangle())
        .onTapGesture {
            if isDeleteMode {
                onSelect()
            } else {
                onTap()
            }
        }
    }
} 