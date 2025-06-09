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

    var body: some View {
        Button {
            if isDeleteMode {
                toggleSelection(record)
            } else {
                selectedRecord = record
            }
        } label: {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: (record.type ?? NSLocalizedString("expense", comment: "")) == NSLocalizedString("income", comment: "") ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor((record.type ?? NSLocalizedString("expense", comment: "")) == NSLocalizedString("income", comment: "") ? Color("IncomeColor") : Color("ExpenseColor"))
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if let date = record.date {
                            Text(formattedDate(date))
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 6) {
                            Text(record.categoryRelation?.name ?? "unknown")
                                .foregroundColor(Color("HighlightColor"))
                            if record.paymentType == "카드" {
                                Text("💳")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                    }
                    if let detail = record.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.top, 2)
                    }
                }
                Spacer()
                Text(((record.type ?? NSLocalizedString("expense", comment: "")) == NSLocalizedString("income", comment: "") ? "+ " : "- ") + formattedAmount(record.amount))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor((record.type ?? NSLocalizedString("expense", comment: "")) == NSLocalizedString("income", comment: "") ? Color("IncomeColor") : Color("ExpenseColor"))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selectedRecords.contains(record) && isDeleteMode ? Color.blue.opacity(0.12) : Color("SectionBGColor"))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
}
