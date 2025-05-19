import SwiftUI

struct AddRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: String = NSLocalizedString("expense", comment: "") // ✨ 기본값 로컬라이즈된 '지출'
    @State private var category: String = NSLocalizedString("select", comment: "") // ✨ 기본값 '선택'
    @State private var detail: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var newCategory: String = ""
    @State private var showCategoryManager = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var categoryManager: CategoryManager

    let types = [
        NSLocalizedString("income", comment: ""),
        NSLocalizedString("expense", comment: "")
    ]
    @State private var categories: [String] = []

    var recordToEdit: Record?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text(recordToEdit == nil ? NSLocalizedString("add_item", comment: "") : NSLocalizedString("edit_item", comment: ""))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .padding(.vertical, 6)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section {
                    TextField(NSLocalizedString("example_amount", comment: ""), text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .onChange(of: amount) {
                            let numberString = amount.replacingOccurrences(of: ",", with: "")
                            if let value = Int(numberString) {
                                let formatter = NumberFormatter()
                                formatter.numberStyle = .decimal
                                amount = formatter.string(from: NSNumber(value: value)) ?? ""
                            }
                        }
                }

                Picker(NSLocalizedString("type_label", comment: ""), selection: $type) {
                    ForEach(types, id: \.self) { Text($0).font(.system(size: 15, weight: .regular, design: .rounded)) }
                }
                .pickerStyle(.segmented)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .disabled(recordToEdit != nil)

                Section {
                    Picker(NSLocalizedString("category", comment: ""), selection: $category) {
                        Text(NSLocalizedString("select", comment: "")).font(.system(size: 15, weight: .regular, design: .rounded)).tag(NSLocalizedString("select", comment: ""))
                        ForEach(categories, id: \.self) { Text($0).font(.system(size: 15, weight: .regular, design: .rounded)).tag($0) }
                    }
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    Button(action: {
                        showCategoryManager = true
                    }) {
                        Label(NSLocalizedString("manage_category", comment: ""), systemImage: "folder")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }

                Section {
                    TextField(NSLocalizedString("detail_placeholder", comment: ""), text: $detail)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }

                Section {
                    DatePicker(NSLocalizedString("date", comment: ""), selection: $date, displayedComponents: .date)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(NSLocalizedString("input_error", comment: "")), message: Text(alertMessage), dismissButton: .default(Text(NSLocalizedString("confirm", comment: ""))))
            }
            .sheet(isPresented: $showCategoryManager, onDismiss: {
                categories = type == NSLocalizedString("income", comment: "") ? categoryManager.incomeCategories : categoryManager.expenseCategories
            }) {
                CategoryManagerView(categoryManager: categoryManager, selectedType: type)
            }
            // .navigationTitle(recordToEdit == nil ? "항목 추가" : "항목 수정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(recordToEdit == nil ? NSLocalizedString("save", comment: "") : NSLocalizedString("edit_done", comment: "")) {
                        saveRecord()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
            .onAppear {
                if let record = recordToEdit {
                    type = record.type ?? NSLocalizedString("expense", comment: "")
                    category = record.category ?? NSLocalizedString("select", comment: "")
                    detail = record.detail ?? ""
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    amount = formatter.string(from: NSNumber(value: Int(record.amount))) ?? ""
                    date = record.date ?? Date()
                }
                categories = type == NSLocalizedString("income", comment: "") ? categoryManager.incomeCategories : categoryManager.expenseCategories
            }
            .onChange(of: type) {
                categories = type == NSLocalizedString("income", comment: "") ? categoryManager.incomeCategories : categoryManager.expenseCategories
            }
        }
    }

    private func saveRecord() {
        guard category != NSLocalizedString("select", comment: "") else {
            alertMessage = NSLocalizedString("select_category_alert", comment: "")
            showAlert = true
            return
        }

        let numberString = amount.replacingOccurrences(of: ",", with: "")
        guard !numberString.isEmpty, let intValue = Int(numberString), intValue > 0 else {
            alertMessage = NSLocalizedString("invalid_amount_alert", comment: "")
            showAlert = true
            return
        }

        let record = recordToEdit ?? Record(context: viewContext)

        if recordToEdit == nil {
            record.id = UUID()
        }

        record.type = type
        record.category = category
        record.detail = detail
        record.amount = Double(intValue)
        record.date = date

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }
}
