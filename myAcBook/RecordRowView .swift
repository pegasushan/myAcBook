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
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: (record.type ?? "지출") == "수입" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor((record.type ?? "지출") == "수입" ? .green : .red)
                    .font(.system(size: 15, weight: .regular, design: .rounded))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let date = record.date {
                            Text(formattedDate(date))
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        Text(record.category ?? "Unknown")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                        if let detail = record.detail, !detail.isEmpty {
                            Text(detail)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text(formattedAmount(record.amount))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal)
            .background(
                selectedRecords.contains(record)
                ? Color.blue.opacity(0.15)
                : Color(.systemBackground)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
}
