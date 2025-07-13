import CoreData
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

    @Binding var selectedPaymentType: String

    var onReset: () -> Void

    @State private var fetchedCategories: [AppCategory] = []

    // customBGColor, customCardColor, customSectionColor 등 변수 선언부 모두 삭제
    // 배경색, 카드색, 섹션색 사용하는 모든 곳을 AppColors.background, AppColors.card, AppColors.section으로 교체
    // 예시: .background(customBGColor.ignoresSafeArea()) -> .background(AppColors.background.ignoresSafeArea())
    // ZStack, VStack, Section 등에서 배경색 지정 시 AppColors 사용
    @Environment(\.colorScheme) var colorScheme
    var customBGColor: Color {
        colorScheme == .light ? Color(UIColor(hex: "#FEEAF2")) : Color(UIColor(hex: "#181A20"))
    }

    var currentCategoryBinding: Binding<String> {
        switch selectedType {
        case "수입":
            return $selectedIncomeCategory
        case "지출":
            return $selectedExpenseCategory
        default:
            return $selectedAllCategory
        }
    }

    // 강조 색상 정의
    var highlightColor: Color {
        colorScheme == .light ? Color(red: 1.0, green: 0.5, blue: 0.7) : Color(red: 0.9, green: 0.4, blue: 0.6)
    }

    @State private var selectedCategoryIndex: Int? = nil
    @State private var selectedDateIndex: Int? = nil

    init(
        selectedType: Binding<String>,
        selectedCategory: Binding<String>,
        selectedDate: Binding<String>,
        customStartDate: Binding<Date>,
        customEndDate: Binding<Date>,
        selectedIncomeCategory: Binding<String>,
        selectedExpenseCategory: Binding<String>,
        selectedAllCategory: Binding<String>,
        selectedPaymentType: Binding<String>,
        onReset: @escaping () -> Void
    ) {
        self._selectedType = selectedType
        self._selectedCategory = selectedCategory
        self._selectedDate = selectedDate
        self._customStartDate = customStartDate
        self._customEndDate = customEndDate
        self._selectedIncomeCategory = selectedIncomeCategory
        self._selectedExpenseCategory = selectedExpenseCategory
        self._selectedAllCategory = selectedAllCategory
        self._selectedPaymentType = selectedPaymentType
        self.onReset = onReset
    }

    private func internalType(for displayType: String) -> String {
        if displayType == NSLocalizedString("income", comment: "") {
            return "income"
        } else if displayType == NSLocalizedString("expense", comment: "") {
            return "expense"
        } else if displayType == NSLocalizedString("all", comment: "") {
            return "all"
        } else {
            return displayType
        }
    }

    private func loadCategories(for type: String) {
        let request: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AppCategory.name, ascending: true)]

        if internalType(for: type) != "all" {
            let internalTypeValue = internalType(for: type)
            request.predicate = NSPredicate(format: "type == %@", internalTypeValue)
        }

        if let result = try? PersistenceController.shared.container.viewContext.fetch(request) {
            self.fetchedCategories = result
            print("불러온 카테고리: \(result.map { $0.name ?? "nil" })")
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    // 유형 필터 카드
                    FilterCard {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(selectedType != NSLocalizedString("all", comment: "전체") ? highlightColor : Color("HighlightColor"))
                            Text(NSLocalizedString("type", comment: "유형")).appBody()
                                .foregroundColor(selectedType != NSLocalizedString("all", comment: "전체") ? highlightColor : .primary)
                            Spacer()
                        }
                        Picker("", selection: $selectedType) {
                            Text(NSLocalizedString("all", comment: "전체")).tag(NSLocalizedString("all", comment: "전체"))
                            Text(NSLocalizedString("income", comment: "수입")).tag(NSLocalizedString("income", comment: "수입"))
                            Text(NSLocalizedString("expense", comment: "지출")).tag(NSLocalizedString("expense", comment: "지출"))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .accentColor(Color("HighlightColor"))
                    }

                    // === 지출구분 필터를 유형 바로 아래로 이동 ===
                    if selectedType == NSLocalizedString("expense", comment: "지출") {
                        FilterCard {
                            HStack(spacing: 8) {
                                Image(systemName: "creditcard")
                                    .foregroundColor(selectedPaymentType != NSLocalizedString("all", comment: "전체") ? highlightColor : Color("HighlightColor"))
                                Text(NSLocalizedString("payment_type_label", comment: "지출 구분")).appBody()
                                    .foregroundColor(selectedPaymentType != NSLocalizedString("all", comment: "전체") ? highlightColor : .primary)
                                Spacer()
                            }
                            Picker("", selection: $selectedPaymentType) {
                                Text(NSLocalizedString("all", comment: "전체")).tag(NSLocalizedString("all", comment: "전체"))
                                Text(NSLocalizedString("cash", comment: "현금")).tag(NSLocalizedString("cash", comment: "현금"))
                                Text(NSLocalizedString("card", comment: "카드")).tag(NSLocalizedString("card", comment: "카드"))
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .accentColor(Color("HighlightColor"))
                        }
                    }

                    // 카테고리 필터 카드
                    FilterCard {
                        HStack(spacing: 8) {
                            Image(systemName: "tag")
                                .foregroundColor(currentCategoryBinding.wrappedValue != NSLocalizedString("all", comment: "전체") ? highlightColor : Color("HighlightColor"))
                            Text(NSLocalizedString("select_category", comment: "카테고리 선택")).appBody()
                                .foregroundColor(currentCategoryBinding.wrappedValue != NSLocalizedString("all", comment: "전체") ? highlightColor : .primary)
                            Spacer()
                        }
                        CustomDropdown(selectedIndex: $selectedCategoryIndex, options: [NSLocalizedString("all", comment: "전체")] + fetchedCategories.map { NSLocalizedString($0.name ?? "", comment: "") }, placeholder: NSLocalizedString("select_category", comment: "카테고리 선택"))
                            .onChange(of: selectedCategoryIndex) {
                                if let idx = selectedCategoryIndex {
                                    if idx == 0 {
                                        currentCategoryBinding.wrappedValue = NSLocalizedString("all", comment: "전체")
                                    } else if fetchedCategories.indices.contains(idx - 1) {
                                        currentCategoryBinding.wrappedValue = fetchedCategories[idx - 1].name ?? ""
                                    }
                                }
                            }
                    }

                    Spacer()

                    // 적용 버튼
                    Button(action: {
                        selectedCategory = currentCategoryBinding.wrappedValue
                        dismiss()
                    }) {
                        Text(NSLocalizedString("apply", comment: "적용"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("HighlightColor"))
                            .cornerRadius(16)
                            .shadow(radius: 4)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("filter_setting", comment: "필터 설정"))
                        .appSectionTitle()
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onReset()
                        selectedCategoryIndex = 0
                        selectedDateIndex = 0
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(Color("ExpenseColor"))
                }
            }
            .onAppear {
                if selectedDate.isEmpty {
                    selectedDate = NSLocalizedString("month", comment: "한달")
                }
                if selectedIncomeCategory.isEmpty {
                    selectedIncomeCategory = NSLocalizedString("all", comment: "전체")
                }
                if selectedExpenseCategory.isEmpty {
                    selectedExpenseCategory = NSLocalizedString("all", comment: "전체")
                }
                if selectedAllCategory.isEmpty {
                    selectedAllCategory = NSLocalizedString("all", comment: "전체")
                }
                if selectedPaymentType.isEmpty {
                    selectedPaymentType = NSLocalizedString("all", comment: "전체")
                }
                loadCategories(for: selectedType)
                // 카테고리 인덱스
                if let idx = fetchedCategories.firstIndex(where: { $0.name == currentCategoryBinding.wrappedValue }) {
                    selectedCategoryIndex = idx + 1
                } else {
                    selectedCategoryIndex = 0
                }
                // 기간 인덱스
                let dateOptions = [NSLocalizedString("all", comment: "전체"), NSLocalizedString("today", comment: "오늘"), NSLocalizedString("yesterday", comment: "어제"), NSLocalizedString("week", comment: "1주일"), NSLocalizedString("month", comment: "한달"), NSLocalizedString("custom", comment: "직접 선택")]
                if let idx = dateOptions.firstIndex(of: selectedDate) {
                    selectedDateIndex = idx
                } else {
                    selectedDateIndex = 0
                }
            }
            .onChange(of: selectedType) { _, newValue in
                loadCategories(for: newValue)
            }
        }
    }
}

struct FilterCard<Content: View>: View {
    let content: Content
    var isActive: Bool = false
    var highlightColor: Color = .clear
    // customLightSectionColorHex, customDarkSectionColorHex 변수 삭제
    // 배경색, 카드색, 섹션색 사용하는 모든 곳을 AppColors.background, AppColors.card, AppColors.section으로 교체
    // 예시: .background(customBGColor.ignoresSafeArea()) -> .background(AppColors.background.ignoresSafeArea())
    // ZStack, VStack, Section 등에서 배경색 지정 시 AppColors 사용
    @Environment(\.colorScheme) var colorScheme
    var customSectionColor: Color {
        colorScheme == .light ? Color(UIColor(hex: "#F6F7FA")) : Color(UIColor(hex: "#23272F"))
    }
    init(isActive: Bool = false, highlightColor: Color = .clear, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.highlightColor = highlightColor
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(customSectionColor)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? highlightColor : Color.gray.opacity(0.12), lineWidth: isActive ? 2 : 1)
        )
    }
}

