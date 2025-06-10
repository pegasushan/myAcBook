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

    var customBGColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightBGColorHex)) : Color(UIColor(hex: customDarkBGColorHex))
    }
    var customCardColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightCardColorHex)) : Color(UIColor(hex: customDarkCardColorHex))
    }
    var customSectionColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightSectionColorHex)) : Color(UIColor(hex: customDarkSectionColorHex))
    }
    @Environment(\.colorScheme) var colorScheme
    @FetchRequest private var categories: FetchedResults<AppCategory>
    var selectedType: String

    @State private var newCategoryName: String = ""
    @State private var showEmptyNameAlert = false
    @State private var selectedFilter: String
    @State private var showDuplicateAlert = false

    private var filteredCategories: [AppCategory] {
        let nonEmpty = Array(categories.filter { !($0.name?.isEmpty ?? true) })
        return nonEmpty.filter { $0.type == selectedFilter }
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
        VStack {
            // 상단 타이틀
            HStack(spacing: 10) {
                // Image(systemName: "folder.fill") // 이모티콘 제거
                // 상단 텍스트도 이미 제거됨
            }
            .padding(.top, 24)
            .padding(.bottom, 8)
            // 리스트와 타이틀 사이 여백
            Spacer().frame(height: 8)
            Picker("Type Filter", selection: $selectedFilter) {
                Text(LocalizedStringKey("income")).tag("income")
                Text(LocalizedStringKey("expense")).tag("expense")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            List {
                Section(header:
                    Text(NSLocalizedString("category_list", comment: "카테고리 목록"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("HighlightColor"))
                        .padding(.top, 8)
                ) {
                    if filteredCategories.isEmpty {
                        Text(LocalizedStringKey("no_categories"))
                            .foregroundColor(.gray)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    ForEach(filteredCategories.compactMap { $0.id != nil ? $0 : nil }, id: \.id) { category in
                        HStack {
                            Text(LocalizedStringKey(category.name ?? ""))
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                            Spacer()
                            Text(category.type == "income" ? NSLocalizedString("income", comment: "") : NSLocalizedString("expense", comment: ""))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color("HighlightColor"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color("SectionBGColor"))
                                .cornerRadius(6)
                        }
                    }
                    .onDelete { indexSet in
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
                    Text(NSLocalizedString("add_new_category", comment: "카테고리 추가"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("HighlightColor"))
                        .padding(.top, 12)
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.gray)
                        TextField(LocalizedStringKey("category_name_placeholder"), text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                        Spacer()
                        Button(action: {
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
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(6)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .alert(LocalizedStringKey("empty_input_alert"), isPresented: $showEmptyNameAlert) {
                            Button(LocalizedStringKey("confirm"), role: .cancel) { }
                        }
                        .alert(LocalizedStringKey("duplicate_category_alert"), isPresented: $showDuplicateAlert) {
                            Button(LocalizedStringKey("confirm"), role: .cancel) { }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 8)
            .listStyle(.insetGrouped)
            .listRowBackground(Color("BackgroundSolidColor"))
            .scrollContentBackground(.hidden)
            .background(customBGColor)
            .onAppear {
                UITableView.appearance().backgroundColor = UIColor.clear
            }
        }
        .background(customBGColor)
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
