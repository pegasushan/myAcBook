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
    @AppStorage("customLightBGColor") private var customLightBGColorHex: String = "#FEEAF2"
    @AppStorage("customDarkBGColor") private var customDarkBGColorHex: String = "#181A20"
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    @AppStorage("customLightSectionColor") private var customLightSectionColorHex: String = "#F6F7FA"
    @AppStorage("customDarkSectionColor") private var customDarkSectionColorHex: String = "#23272F"

    // customBGColor, customCardColor, customSectionColor 등 변수 선언부 모두 삭제
    @Environment(\.colorScheme) var colorScheme
    @FetchRequest private var categories: FetchedResults<AppCategory>
    var selectedType: String

    @State private var newCategoryName: String = ""
    @State private var showEmptyNameAlert = false
    @State private var selectedFilter: String
    @State private var showDuplicateAlert = false
    @State private var editingCategory: AppCategory? = nil

    private var filteredCategories: [AppCategory] {
        let nonEmpty = Array(categories.filter { !($0.name?.isEmpty ?? true) })
        return nonEmpty.filter { $0.type == selectedFilter }
    }
    private var validCategories: [AppCategory] {
        filteredCategories.filter { $0.id != nil }
    }

    // CategoryRowData 구조체 추가
    struct CategoryRowData: Identifiable {
        let id: UUID
        let name: String
        let type: String
        let managedObject: AppCategory
    }

    // CategoryRowView 뷰 추가
    struct CategoryRowView: View {
        let row: CategoryRowData
        let customCardColor: Color
        let onEdit: () -> Void
        let onDelete: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "tag")
                    .foregroundColor(.primary)
                Text(NSLocalizedString(row.name, comment: ""))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text(row.type == "income" ? NSLocalizedString("income", comment: "") : NSLocalizedString("expense", comment: ""))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(row.type == "income" ? Color(red: 0.7, green: 0.9, blue: 0.7) : Color(red: 1.0, green: 0.7, blue: 0.7))
                    .cornerRadius(8)
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.7))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 14).fill(customCardColor).shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 2))
        }
    }

    private var categoryRows: [CategoryRowData] {
        filteredCategories.compactMap { category in
            guard let id = category.id, let name = category.name else { return nil }
            return CategoryRowData(id: id, name: name, type: category.type ?? "", managedObject: category)
        }
    }

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
        VStack(spacing: 0) {
            // 상단 아이콘과 타이틀
            VStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.primary)
                    .padding(.top, 24)
                Text(NSLocalizedString("category_management", comment: "카테고리 관리"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 32) // 제목과 탭 사이 간격 넓힘

            // 수입/지출 탭
            Picker("Type Filter", selection: $selectedFilter) {
                Text(LocalizedStringKey("income")).tag("income")
                Text(LocalizedStringKey("expense")).tag("expense")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 12)

            // 스크롤 영역 (카테고리 리스트 or 없음 안내)
            ScrollView {
                if filteredCategories.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray.opacity(0.4))
                        Text(NSLocalizedString("no_categories", comment: "카테고리가 없습니다."))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 20) {
                        ForEach(categoryRows) { row in
                            CategoryRowView(
                                row: row,
                                customCardColor: AppColors.card,
                                onEdit: {
                                    editingCategory = row.managedObject
                                    newCategoryName = row.name
                                },
                                onDelete: {
                                    if let context = row.managedObject.managedObjectContext {
                                        context.delete(row.managedObject)
                                        try? context.save()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                Spacer(minLength: 0)
            }

            Spacer() // 하단 고정용

            // 새 카테고리 추가 (항상 하단 고정)
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("add_new_category", comment: "카테고리 추가"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 18)
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.gray)
                    TextField(LocalizedStringKey("category_name_placeholder"), text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                    Spacer()
                    Button(action: {
                        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
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
                                // 강제 새로고침: selectedFilter를 토글했다가 원래대로 복원
                                let old = selectedFilter
                                selectedFilter = (old == "income" ? "expense" : "income")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    selectedFilter = old
                                }
                            } catch {}
                            newCategoryName = ""
                        } else {
                            showEmptyNameAlert = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.card).shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 2))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            // 하단 안내문구
            Text(NSLocalizedString("category_usage_hint", comment: "카테고리는 내역 추가/수정에서 선택할 수 있습니다."))
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
        .background(AppColors.background.ignoresSafeArea())
        .alert(LocalizedStringKey("empty_input_alert"), isPresented: $showEmptyNameAlert) {
            Button(LocalizedStringKey("confirm"), role: .cancel) { }
        }
        .alert(LocalizedStringKey("duplicate_category_alert"), isPresented: $showDuplicateAlert) {
            Button(LocalizedStringKey("confirm"), role: .cancel) { }
        }
    }
}
