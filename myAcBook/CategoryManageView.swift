import Foundation
import SwiftUI

public struct CategoryManagerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var categoryManager: CategoryManager
    var selectedType: String

    @State private var newCategoryName: String = ""
    @State private var showEmptyNameAlert = false

    public var body: some View {
        NavigationView {
            List {
                Section(header:
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("category_list"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                ) {
                    if selectedType == NSLocalizedString("income", comment: "") {
                        ForEach(categoryManager.incomeCategories, id: \.self) { category in
                            Text(LocalizedStringKey(category))
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                        }
                        .onDelete(perform: categoryManager.deleteIncomeCategory)
                    } else {
                        ForEach(categoryManager.expenseCategories, id: \.self) { category in
                            Text(LocalizedStringKey(category))
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                        }
                        .onDelete(perform: categoryManager.deleteExpenseCategory)
                    }
                }

                Section(header:
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("add_new_category"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
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
                            if !trimmed.isEmpty {
                                if selectedType == NSLocalizedString("income", comment: "") {
                                    categoryManager.addIncomeCategory(trimmed)
                                } else {
                                    categoryManager.addExpenseCategory(trimmed)
                                }
                                newCategoryName = ""
                            } else {
                                showEmptyNameAlert = true
                            }
                        }
                        .alert(LocalizedStringKey("empty_input_alert"), isPresented: $showEmptyNameAlert) {
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LocalizedStringKey("manage_category"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("close")) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }
}
