//
//  FilterSummaryView .swift
//  myAcBook
//
//  Created by 한상욱 on 5/1/25.
//

import SwiftUI

struct FilterSummaryView: View {
    var selectedTypeFilter: String
    var selectedCategory: String
    var selectedDateFilter: String
    var dateRangeText: String
    var onTap: () -> Void
    var onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 16) {
                Button(action: {
                    onTap()
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(NSLocalizedString("filter_setting", comment: "필터 설정"))
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
                }
                .contentShape(Rectangle())

                Spacer()
            }
            if selectedTypeFilter != NSLocalizedString("all", comment: "") || selectedDateFilter != NSLocalizedString("all", comment: "") || selectedCategory != NSLocalizedString("all", comment: "") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(NSLocalizedString("type", comment: "유형") + ":")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                        Text(selectedTypeFilter)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(NSLocalizedString("category", comment: "카테고리") + ":")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                        Text(selectedCategory.isEmpty ? NSLocalizedString("all", comment: "") : selectedCategory)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(NSLocalizedString("period", comment: "기간") + ":")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                        Text(dateRangeText)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
