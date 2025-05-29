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
            Form {
                Section {
                    EmptyView()
                        .frame(height: 8)
                }

                Section(header: Text(NSLocalizedString("type", comment: "유형"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)) {
                    Picker("유형", selection: $selectedType) {
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
                            let categories: [String] = fetchedCategories.map { $0.name ?? "" }
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
                ToolbarItem(placement: .destructiveAction) {
                    Button(NSLocalizedString("reset", comment: "초기화")) {
                        onReset()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("apply", comment: "적용")) {
                        selectedCategory = currentCategoryBinding.wrappedValue
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
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
