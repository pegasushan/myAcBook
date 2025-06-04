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
                    .foregroundColor(Color("HighlightColor"))
                }
                .contentShape(Rectangle())

                Spacer()
            }
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16, alignment: .leading),
                GridItem(.flexible(), spacing: 16, alignment: .leading)
            ], spacing: 8) {
                HStack(spacing: 4) {
                    Text(NSLocalizedString("type", comment: "유형") + ":")
                        .foregroundColor(.secondary)
                    Text(selectedTypeFilter.isEmpty ? NSLocalizedString("all", comment: "") : NSLocalizedString(selectedTypeFilter, comment: ""))
                        .foregroundColor(.primary)
                }
                HStack(spacing: 4) {
                    Text(NSLocalizedString("category", comment: "카테고리") + ":")
                        .foregroundColor(.secondary)
                    Text(selectedCategory.isEmpty ? NSLocalizedString("all", comment: "전체") : NSLocalizedString(selectedCategory, comment: ""))
                        .foregroundColor(.primary)
                }
                HStack(spacing: 4) {
                    Text(NSLocalizedString("period", comment: "기간") + ":")
                        .foregroundColor(.secondary)
                    Text(selectedDateFilter.isEmpty || selectedDateFilter == NSLocalizedString("all", comment: "") ? NSLocalizedString("all", comment: "") : dateRangeText)
                        .foregroundColor(.primary)
                }
            }
            .font(.system(size: 14, weight: .regular, design: .rounded))
        }
        .padding()
        .background(Color("SectionBGColor"))
        .cornerRadius(12)
    }
}
