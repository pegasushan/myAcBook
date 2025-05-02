import Foundation
import SwiftUI

public struct CategoryManagerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var categoryManager: CategoryManager
    var selectedType: String

    @State private var newCategoryName: String = ""

    public var body: some View {
        NavigationView {
            List {
                Section(header:
                    VStack(alignment: .leading) {
                        Text("카테고리 목록")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                ) {
                    if selectedType == "수입" {
                        ForEach(categoryManager.incomeCategories, id: \.self) { category in
                            Text(category)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .onDelete(perform: categoryManager.deleteIncomeCategory)
                    } else {
                        ForEach(categoryManager.expenseCategories, id: \.self) { category in
                            Text(category)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .onDelete(perform: categoryManager.deleteExpenseCategory)
                    }
                }

                Section(header:
                    VStack(alignment: .leading) {
                        Text("새 카테고리 추가")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)
                ) {
                    HStack(spacing: 12) {
                        TextField("카테고리 이름", text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 15, design: .rounded))
                        Button("추가") {
                            let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                if selectedType == "수입" {
                                    categoryManager.addIncomeCategory(trimmed)
                                } else {
                                    categoryManager.addExpenseCategory(trimmed)
                                }
                                newCategoryName = ""
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 8)
            .listStyle(.insetGrouped)
            .navigationTitle("카테고리 관리")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
    }
}
