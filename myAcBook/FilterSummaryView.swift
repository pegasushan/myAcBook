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
    var selectedPaymentType: String

    @Environment(\.colorScheme) var colorScheme
    
    var activeBorder: Color {
        colorScheme == .light ? Color(red: 1.0, green: 0.5, blue: 0.7) : Color(red: 0.9, green: 0.4, blue: 0.6)
    }
    var highlightColor: Color {
        colorScheme == .light ? Color(red: 1.0, green: 0.1, blue: 0.5) : Color(red: 0.95, green: 0.0, blue: 0.4)
    }
    var body: some View {
        // 1. 필터가 전체인지 여부 판단
        let all = NSLocalizedString("all", comment: "")
        let allPayment = NSLocalizedString("all", comment: "전체")
        let isDefaultFilter = (selectedTypeFilter == all || selectedTypeFilter.isEmpty)
            && (selectedCategory == all || selectedCategory.isEmpty)
            && (selectedPaymentType == allPayment || selectedPaymentType.isEmpty)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(NSLocalizedString("filter_setting", comment: "필터 설정")).appBody()
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color("HighlightColor"))
                Spacer()
            }
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16, alignment: .leading),
                GridItem(.flexible(), spacing: 16, alignment: .leading)
            ], spacing: 8) {
                HStack(spacing: 4) {
                    Text(NSLocalizedString("type", comment: "유형") + ":" ).appCaption()
                    Text(selectedTypeFilter.isEmpty || selectedTypeFilter == NSLocalizedString("all", comment: "") ? NSLocalizedString("all", comment: "") : NSLocalizedString(selectedTypeFilter, comment: ""))
                        .foregroundColor((!selectedTypeFilter.isEmpty && selectedTypeFilter != NSLocalizedString("all", comment: "")) ? highlightColor : .primary)
                }
                // 지출구분(결제수단) 필터 요약 표시
                if selectedTypeFilter == NSLocalizedString("expense", comment: "지출") {
                    HStack(spacing: 4) {
                        Text(NSLocalizedString("payment_type_label", comment: "지출 구분") + ":").appCaption()
                        Text((selectedPaymentType.isEmpty || selectedPaymentType == NSLocalizedString("all", comment: "전체")) ? NSLocalizedString("all", comment: "전체") : NSLocalizedString(selectedPaymentType, comment: ""))
                            .foregroundColor((!selectedPaymentType.isEmpty && selectedPaymentType != NSLocalizedString("all", comment: "전체")) ? highlightColor : .primary)
                    }
                }
                HStack(spacing: 4) {
                    Text(NSLocalizedString("category", comment: "카테고리") + ":" ).appCaption()
                    Text(selectedCategory.isEmpty || selectedCategory == NSLocalizedString("all", comment: "전체") ? NSLocalizedString("all", comment: "전체") : NSLocalizedString(selectedCategory, comment: ""))
                        .foregroundColor((!selectedCategory.isEmpty && selectedCategory != NSLocalizedString("all", comment: "전체")) ? highlightColor : .primary)
                }
            }
            .font(.system(size: 14, weight: .regular, design: .rounded))
        }
        .padding()
        .background(AppColors.section)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isDefaultFilter ? Color.gray.opacity(0.15) : activeBorder, lineWidth: isDefaultFilter ? 1 : 2)
        )
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            print("FilterSummaryView tapped!")
            onTap()
        }
    }
}
