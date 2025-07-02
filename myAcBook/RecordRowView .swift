//
//  RecordRowView .swift
//  myAcBook
//
//  Created by 한상욱 on 5/1/25.
//

import SwiftUI

struct RecordRowView: View {
    let record: Record
    let isDeleteMode: Bool
    let selectedRecords: Set<Record>
    let toggleSelection: (Record) -> Void
    @Binding var selectedRecord: Record?
    let formattedAmount: (Double) -> String
    let formattedDate: (Date) -> String
    let onDelete: () -> Void
    let dateLabel: String?
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    var customLightCardColor: Color { Color(UIColor(hex: customLightCardColorHex)) }
    @Environment(\.colorScheme) var colorScheme
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: (record.type ?? NSLocalizedString("expense", comment: "")) == NSLocalizedString("income", comment: "") ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor((record.type ?? NSLocalizedString("expense", comment: "")) == NSLocalizedString("income", comment: "") ? Color("IncomeColor") : Color("ExpenseColor"))
                .font(.system(size: 18, weight: .regular, design: .rounded))
            
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    if let dateLabel = dateLabel {
                        Text("")
                        + Text(dateLabel).foregroundColor(.secondary)
                        + Text(" ")
                        + Text(record.categoryRelation?.name ?? "unknown").foregroundColor(Color("HighlightColor"))
                    } else {
                        Text(record.categoryRelation?.name ?? "unknown").appBody()
                            .foregroundColor(Color("HighlightColor"))
                    }
                    if record.paymentType == "카드" {
                        Text("💳").appBody()
                            .foregroundColor(.secondary)
                    }
                }
                .font(.system(size: 15, weight: .regular, design: .rounded))
            }
            if let detail = record.detail, !detail.isEmpty {
                Text(detail).appBody()
                    .foregroundColor(.primary)
                    .padding(.top, 2)
            }
            Spacer()
            Text(((record.type ?? NSLocalizedString("expense", comment: "")) == NSLocalizedString("income", comment: "") ? "+ " : "- ") + formattedAmount(record.amount))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor((record.type ?? NSLocalizedString("expense", comment: "")) == NSLocalizedString("income", comment: "") ? Color("IncomeColor") : Color("ExpenseColor"))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(selectedRecords.contains(record) && isDeleteMode
                      ? Color(red: 1.0, green: 0.7, blue: 0.8).opacity(0.35)
                      : (colorScheme == .light ? customLightCardColor : Color("SectionBGColor")))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(selectedRecords.contains(record) && isDeleteMode
                                ? Color(red: 1.0, green: 0.5, blue: 0.7).opacity(0.85) : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: Color.black.opacity(0.13), radius: 7, x: 0, y: 3)
        .scaleEffect(selectedRecords.contains(record) && isDeleteMode ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedRecords)
        .onTapGesture {
            if isDeleteMode {
                toggleSelection(record)
            } else {
                selectedRecord = record
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
}
