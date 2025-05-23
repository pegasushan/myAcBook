extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

import Foundation
import SwiftUI
import CoreData

public struct CategoryManagerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var categories: FetchedResults<AppCategory>
    var selectedType: String

    @State private var newCategoryName: String = ""
    @State private var showEmptyNameAlert = false
    @State private var selectedFilter: String
    @State private var showDuplicateAlert = false

public init(selectedType: String) {
    self.selectedType = selectedType

    let normalized = (selectedType == NSLocalizedString("income", comment: "수입")) ? "income" :
                     (selectedType == NSLocalizedString("expense", comment: "지출")) ? "expense" :
                     selectedType

    _selectedFilter = State(initialValue: normalized)

    print("📌 전달받은 selectedType: \(selectedType), normalized: \(normalized)")

    _categories = FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AppCategory.name, ascending: true)],
        predicate: nil
    )
}

    public var body: some View {
        VStack {
            Picker("Type Filter", selection: $selectedFilter) {
                Text(LocalizedStringKey("income")).tag("income")
                Text(LocalizedStringKey("expense")).tag("expense")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            List {
                Section(header:
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("category_list"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                ) {
                    if categories.filter({ $0.type == selectedFilter && !($0.name?.isEmpty ?? true) }).isEmpty {
                        Text(LocalizedStringKey("no_categories"))
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    ForEach(categories.filter {
                        !($0.name?.isEmpty ?? true) &&
                        $0.type == selectedFilter
                    }) { category in
                        HStack {
                            Text(LocalizedStringKey(category.name ?? ""))
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                            Spacer()
                            Text(category.type == "income" ? NSLocalizedString("income", comment: "") : NSLocalizedString("expense", comment: ""))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }
                    }
                    .onDelete { indexSet in
                        let filteredCategories = categories.filter {
                            !($0.name?.isEmpty ?? true) &&
                            $0.type == selectedFilter
                        }
                        for index in indexSet {
                            let categoryToDelete = filteredCategories[index]
                            if let context = categoryToDelete.managedObjectContext {
                                context.delete(categoryToDelete)
                                try? context.save()
                            }
                        }
                    }
                }

                Section(header:
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("add_new_category"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)
                ) {
                    HStack(spacing: 12) {
                        TextField(LocalizedStringKey("category_name_placeholder"), text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                        Button(LocalizedStringKey("add")) {
                            let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                            print("➕ 추가 시도: '\(trimmed)', 타입: \(selectedType)")
                            if !trimmed.isEmpty {
                                guard !categories.contains(where: {
                                    let categoryName = $0.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
                                    let matchesName = categoryName == trimmed.lowercased()
                                    let matchesType = $0.type == selectedFilter
                                    return matchesName && matchesType
                                }) else {
                                    showDuplicateAlert = true
                                    return
                                }
                                let newCategory = AppCategory(context: viewContext)
                                newCategory.id = UUID()
                                newCategory.name = trimmed
                                newCategory.type = selectedFilter
                                do {
                                    try viewContext.save()
                                    UIApplication.shared.endEditing()
                                    print("✅ 저장 성공")
                                } catch {
                                    print("❌ 저장 실패: \(error.localizedDescription)")
                                }
                                print("📋 현재 목록: \(categories.map { $0.name ?? "-" })")
                                newCategoryName = ""
                            } else {
                                showEmptyNameAlert = true
                            }
                        }
                        .alert(LocalizedStringKey("empty_input_alert"), isPresented: $showEmptyNameAlert) {
                            Button(LocalizedStringKey("confirm"), role: .cancel) { }
                        }
                        .alert(LocalizedStringKey("duplicate_category_alert"), isPresented: $showDuplicateAlert) {
                            Button(LocalizedStringKey("confirm"), role: .cancel) { }
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 8)
            .listStyle(.insetGrouped)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(NSLocalizedString("manage_category", comment: "카테고리 관리"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizedStringKey("close")) {
                    dismiss()
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
        }
    }
}
