// SearchFilterView.swift

import SwiftUI

struct SearchFilterView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedType: String
    @Binding var selectedCategory: String
    @Binding var selectedDate: String
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date

    @Binding var selectedIncomeCategory: String
    @Binding var selectedExpenseCategory: String
    @Binding var selectedAllCategory: String

    @ObservedObject var categoryManager: CategoryManager

    var currentCategoryBinding: Binding<String> {
        switch selectedType {
        case NSLocalizedString("income", comment: "수입"):
            return $selectedIncomeCategory
        case NSLocalizedString("expense", comment: "지출"):
            return $selectedExpenseCategory
        default:
            return $selectedAllCategory
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    EmptyView()
                        .frame(height: 8)
                }

                Section(header: Text(NSLocalizedString("type", comment: "유형"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)) {
                    Picker(NSLocalizedString("type", comment: "유형"), selection: $selectedType) {
                        Text(NSLocalizedString("all", comment: "전체")).tag(NSLocalizedString("all", comment: "전체"))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                        Text(NSLocalizedString("income", comment: "수입")).tag(NSLocalizedString("income", comment: "수입"))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                        Text(NSLocalizedString("expense", comment: "지출")).tag(NSLocalizedString("expense", comment: "지출"))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.bottom, 8)

                Section {
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("select_category", comment: "카테고리 선택"))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                        Picker(selection: currentCategoryBinding) {
                            Text(NSLocalizedString("all", comment: "전체")).tag(NSLocalizedString("all", comment: "전체"))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                            let categories: [String] = {
                                switch selectedType {
                                case NSLocalizedString("income", comment: "수입"):
                                    return categoryManager.incomeCategories
                                case NSLocalizedString("expense", comment: "지출"):
                                    return categoryManager.expenseCategories
                                default:
                                    return categoryManager.incomeCategories + categoryManager.expenseCategories
                                }
                            }()
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                            }
                        } label: {
                            Text(NSLocalizedString("category", comment: "카테고리")).font(.system(size: 14, weight: .regular, design: .rounded))
                        }
                    }
                }
                .headerProminence(.increased)
                .padding(.bottom, 8)

                Section(header: Text(NSLocalizedString("period", comment: "기간"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)) {
                    Picker(selection: $selectedDate) {
                        Text(NSLocalizedString("all", comment: "전체"))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag(NSLocalizedString("all", comment: "전체"))
                        Text(NSLocalizedString("today", comment: "오늘"))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag(NSLocalizedString("today", comment: "오늘"))
                        Text(NSLocalizedString("yesterday", comment: "어제"))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag(NSLocalizedString("yesterday", comment: "어제"))
                        Text(NSLocalizedString("week", comment: "1주일"))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag(NSLocalizedString("week", comment: "1주일"))
                        Text(NSLocalizedString("month", comment: "한달"))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag(NSLocalizedString("month", comment: "한달"))
                        Text(NSLocalizedString("custom", comment: "직접 선택"))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag(NSLocalizedString("custom", comment: "직접 선택"))
                    } label: {
                        Text(NSLocalizedString("period", comment: "기간")).font(.system(size: 14, weight: .regular, design: .rounded))
                    }
                    if selectedDate == NSLocalizedString("custom", comment: "직접 선택") {
                        DatePicker(NSLocalizedString("start_date", comment: "시작 날짜"), selection: $customStartDate, displayedComponents: .date)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                        DatePicker(NSLocalizedString("end_date", comment: "종료 날짜"), selection: $customEndDate, displayedComponents: .date)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("filter_setting", comment: "필터 설정"))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "취소")) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("apply", comment: "적용")) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }
}
