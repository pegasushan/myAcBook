import Foundation
import SwiftUI

class CategoryManager: ObservableObject {
    @Published var incomeCategories: [String] = [
        NSLocalizedString("salary", comment: ""),
        NSLocalizedString("side_income", comment: "")
    ]
    @Published var expenseCategories: [String] = [
        NSLocalizedString("transportation", comment: ""),
        NSLocalizedString("food", comment: ""),
        NSLocalizedString("shopping", comment: ""),
        NSLocalizedString("leisure", comment: ""),
        NSLocalizedString("etc", comment: "")
    ]

    func addIncomeCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !incomeCategories.contains(trimmed) {
            incomeCategories.append(trimmed)
        }
    }

    func addExpenseCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !expenseCategories.contains(trimmed) {
            expenseCategories.append(trimmed)
        }
    }

    func updateIncomeCategory(oldName: String, newName: String) {
        if let index = incomeCategories.firstIndex(of: oldName) {
            let trimmed = newName.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                incomeCategories[index] = trimmed
            }
        }
    }

    func updateExpenseCategory(oldName: String, newName: String) {
        if let index = expenseCategories.firstIndex(of: oldName) {
            let trimmed = newName.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                expenseCategories[index] = trimmed
            }
        }
    }

    func deleteIncomeCategory(at offsets: IndexSet) {
        incomeCategories.remove(atOffsets: offsets)
    }

    func deleteExpenseCategory(at offsets: IndexSet) {
        expenseCategories.remove(atOffsets: offsets)
    }

    func deleteIncomeCategory(at index: Int) {
        guard incomeCategories.indices.contains(index) else { return }
        incomeCategories.remove(at: index)
    }

    func deleteExpenseCategory(at index: Int) {
        guard expenseCategories.indices.contains(index) else { return }
        expenseCategories.remove(at: index)
    }
}
