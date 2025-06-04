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

    var onReset: () -> Void

    @State private var fetchedCategories: [AppCategory] = []

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

    init(
        selectedType: Binding<String>,
        selectedCategory: Binding<String>,
        selectedDate: Binding<String>,
        customStartDate: Binding<Date>,
        customEndDate: Binding<Date>,
        selectedIncomeCategory: Binding<String>,
        selectedExpenseCategory: Binding<String>,
        selectedAllCategory: Binding<String>,
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
                Color("BackgroundSolidColor").ignoresSafeArea()
                VStack(spacing: 18) {
                    // 유형 필터
                    FilterCard {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(Color("HighlightColor"))
                            Text(NSLocalizedString("type", comment: "유형"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
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
                    // 카테고리 필터
                    FilterCard {
                        HStack(spacing: 8) {
                            Image(systemName: "tag")
                                .foregroundColor(Color("HighlightColor"))
                            Text(NSLocalizedString("select_category", comment: "카테고리 선택"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Spacer()
                        }
                        Picker("", selection: currentCategoryBinding) {
                            Text(NSLocalizedString("all", comment: "전체")).tag(NSLocalizedString("all", comment: "전체"))
                            ForEach(fetchedCategories.map { $0.name ?? "" }, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    // 기간 필터
                    FilterCard {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(Color("HighlightColor"))
                            Text(NSLocalizedString("period", comment: "기간"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Spacer()
                        }
                        Picker("", selection: $selectedDate) {
                            Text(NSLocalizedString("all", comment: "전체")).tag(NSLocalizedString("all", comment: "전체"))
                            Text(NSLocalizedString("today", comment: "오늘")).tag(NSLocalizedString("today", comment: "오늘"))
                            Text(NSLocalizedString("yesterday", comment: "어제")).tag(NSLocalizedString("yesterday", comment: "어제"))
                            Text(NSLocalizedString("week", comment: "1주일")).tag(NSLocalizedString("week", comment: "1주일"))
                            Text(NSLocalizedString("month", comment: "한달")).tag(NSLocalizedString("month", comment: "한달"))
                            Text(NSLocalizedString("custom", comment: "직접 선택")).tag(NSLocalizedString("custom", comment: "직접 선택"))
                        }
                        .pickerStyle(MenuPickerStyle())
                        if selectedDate == NSLocalizedString("custom", comment: "직접 선택") {
                            DatePicker(NSLocalizedString("start_date", comment: "시작 날짜"), selection: $customStartDate, displayedComponents: .date)
                            DatePicker(NSLocalizedString("end_date", comment: "종료 날짜"), selection: $customEndDate, displayedComponents: .date)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                // 하단 고정 적용/초기화 버튼
                VStack {
                    Spacer()
                    HStack {
                        Button(NSLocalizedString("reset", comment: "초기화")) {
                            onReset()
                        }
                        .foregroundColor(Color("ExpenseColor"))
                        Spacer()
                        Button(action: {
                            selectedCategory = currentCategoryBinding.wrappedValue
                            dismiss()
                        }) {
                            Text(NSLocalizedString("apply", comment: "적용"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: 120)
                                .padding(.vertical, 12)
                                .background(Color("HighlightColor"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitle(Text(NSLocalizedString("filter_setting", comment: "필터 설정")), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "취소")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedDate.isEmpty {
                    selectedDate = NSLocalizedString("all", comment: "전체")
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
                loadCategories(for: selectedType)
            }
            .onChange(of: selectedType) { _, newValue in
                loadCategories(for: newValue)
            }
        }
    }
}

struct FilterCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(Color("SectionBGColor"))
        .cornerRadius(14)
    }
}

