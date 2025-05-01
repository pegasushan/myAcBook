import SwiftUI

struct AddRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: String = "지출" // ✨ 기본값 '지출'
    @State private var category: String = "선택" // ✨ 기본값 '선택'
    @State private var detail: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var newCategory: String = ""
    @State private var showCategoryManager = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var categoryManager: CategoryManager

    let types = ["수입", "지출"]
    @State private var categories: [String] = []

    var recordToEdit: Record?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text(recordToEdit == nil ? "📥 항목 추가" : "✏️ 항목 수정")
                            .font(.title3.bold())
                            .padding(.vertical, 6)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section(header: Text("금액").font(.caption)) {
                    TextField("예: 10,000", text: $amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) {
                            let numberString = amount.replacingOccurrences(of: ",", with: "")
                            if let value = Int(numberString) {
                                let formatter = NumberFormatter()
                                formatter.numberStyle = .decimal
                                amount = formatter.string(from: NSNumber(value: value)) ?? ""
                            }
                        }
                }

                Picker("구분", selection: $type) {
                    ForEach(types, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .disabled(recordToEdit != nil)

                Section(header: Text("카테고리")) {
                    Picker("카테고리", selection: $category) {
                        Text("선택").tag("선택")
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    Button(action: {
                        showCategoryManager = true
                    }) {
                        Label("카테고리 관리", systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("설명").font(.caption)) {
                    TextField("항목에 대한 설명", text: $detail)
                }

                Section(header: Text("날짜").font(.caption)) {
                    DatePicker("날짜", selection: $date, displayedComponents: .date)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("입력 오류"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
            }
            .sheet(isPresented: $showCategoryManager, onDismiss: {
                categories = type == "수입" ? categoryManager.incomeCategories : categoryManager.expenseCategories
            }) {
                CategoryManagerView(categoryManager: categoryManager, selectedType: type)
            }
            // .navigationTitle(recordToEdit == nil ? "항목 추가" : "항목 수정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(recordToEdit == nil ? "저장" : "수정 완료") {
                        saveRecord()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let record = recordToEdit {
                    type = record.type ?? "지출"
                    category = record.category ?? "식대"
                    detail = record.detail ?? ""
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    amount = formatter.string(from: NSNumber(value: Int(record.amount))) ?? ""
                    date = record.date ?? Date()
                }
                categories = type == "수입" ? categoryManager.incomeCategories : categoryManager.expenseCategories
            }
            .onChange(of: type) {
                categories = type == "수입" ? categoryManager.incomeCategories : categoryManager.expenseCategories
            }
        }
    }

    private func saveRecord() {
        guard category != "선택" else {
            alertMessage = "카테고리를 선택하세요."
            showAlert = true
            return
        }

        let numberString = amount.replacingOccurrences(of: ",", with: "")
        guard !numberString.isEmpty, let intValue = Int(numberString), intValue > 0 else {
            alertMessage = "금액을 올바르게 입력하세요."
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
            print("저장 에러: \(error.localizedDescription)")
        }
    }
}
