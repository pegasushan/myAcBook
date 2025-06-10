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
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    var customLightCardColor: Color { Color(UIColor(hex: customLightCardColorHex)) }
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
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
                .fill((isDeleteMode && selectedRecords.contains(record)) ? Color.blue.opacity(0.18) : (colorScheme == .light ? customLightCardColor : Color("SectionBGColor")))
                .overlay(
                    (isDeleteMode && selectedRecords.contains(record)) ? RoundedRectangle(cornerRadius: 14).stroke(Color.blue, lineWidth: 2) : nil
                )
        )
        .onTapGesture {
            if isDeleteMode {
                toggleSelection(record)
            } else {
                selectedRecord = record
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isDeleteMode {
                Button(role: .destructive) {
                    if let context = record.managedObjectContext {
                        context.delete(record)
                        try? context.save()
                    }
                } label: {
                    Label(NSLocalizedString("delete", comment: "삭제"), systemImage: "trash")
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
}
