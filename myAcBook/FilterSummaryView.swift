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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                onTap()
            }) {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("필터 설정")
                    Spacer()
                }
                .font(.body)
                .foregroundColor(.blue)
            }
            if selectedTypeFilter != "전체" || selectedDateFilter != "전체" || selectedCategory != "전체" {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("유형:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(selectedTypeFilter)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("카테고리:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(selectedCategory)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("기간:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(dateRangeText)
                            .font(.caption)
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
