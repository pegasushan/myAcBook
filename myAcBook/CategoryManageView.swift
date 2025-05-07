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
                        Text("카테고리 목록")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                ) {
                    if selectedType == "수입" {
                        ForEach(categoryManager.incomeCategories, id: \.self) { category in
                            Text(category)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                        }
                        .onDelete(perform: categoryManager.deleteIncomeCategory)
                    } else {
                        ForEach(categoryManager.expenseCategories, id: \.self) { category in
                            Text(category)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
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
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                        Button("추가") {
                            let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                if selectedType == "수입" {
                                    categoryManager.addIncomeCategory(trimmed)
                                } else {
                                    categoryManager.addExpenseCategory(trimmed)
                                }
                                newCategoryName = ""
                            } else {
                                showEmptyNameAlert = true
                            }
                        }
                        .alert("내용을 입력하세요", isPresented: $showEmptyNameAlert) {
                            Button("확인", role: .cancel) { }
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
                    Text("카테고리 관리")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
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
