import SwiftUI
import CoreData
import Combine

// 키보드 상태 감지용 ObservableObject
class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var cancellables: Set<AnyCancellable> = []
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in self?.isKeyboardVisible = true }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in self?.isKeyboardVisible = false }
            .store(in: &cancellables)
    }
}

struct AddRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: String = NSLocalizedString("expense", comment: "") // ✨ 기본값 로컬라이즈된 '지출'
    @State private var selectedCategory: AppCategory?
    @State private var detail: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var newCategory: String = ""
    @State private var showCategoryManager = false
    @State private var showCardManager = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var paymentType: String = "현금"
    @State private var selectedCard: Card?
    @StateObject private var cardViewModel = CardViewModel(context: PersistenceController.shared.container.viewContext)
    @StateObject private var keyboard = KeyboardObserver()

    let types = [
        NSLocalizedString("income", comment: ""),
        NSLocalizedString("expense", comment: "")
    ]
    @State private var categories: [String] = []
    @State private var fetchedCategories: [AppCategory] = []

    var recordToEdit: Record?

    var body: some View {
        let expenseText = NSLocalizedString("expense", comment: "")
        NavigationView {
            ZStack {
                Color("BackgroundSolidColor").ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 금액 입력란 강조
                            HStack {
                                Image(systemName: "wonsign.circle.fill")
                                    .foregroundColor(Color("HighlightColor"))
                                    .font(.system(size: 28, weight: .bold))
                                TextField(NSLocalizedString("example_amount", comment: ""), text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .padding(12)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(12)
                                    .onChange(of: amount) {
                                        let numberString = amount.replacingOccurrences(of: ",", with: "")
                                        if let value = Int(numberString) {
                                            let formatter = NumberFormatter()
                                            formatter.numberStyle = .decimal
                                            amount = formatter.string(from: NSNumber(value: value)) ?? ""
                                        }
                                    }
                            }
                            .padding(.horizontal)
                            // 유형 선택
                            HStack {
                                Image(systemName: "arrow.2.squarepath")
                                    .foregroundColor(.gray)
                                Picker(NSLocalizedString("type_label", comment: ""), selection: $type) {
                                    ForEach(types, id: \.self) { Text($0).font(.system(size: 15, weight: .regular, design: .rounded)) }
                                }
                                .pickerStyle(.segmented)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .disabled(recordToEdit != nil)
                            }
                            .padding(.horizontal)
                            // 결제수단/카드
                            if type == expenseText {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "creditcard")
                                            .foregroundColor(.gray)
                                        Picker(NSLocalizedString("payment_type_label", comment: "지출 구분"), selection: $paymentType) {
                                            Text(NSLocalizedString("cash", comment: "현금")).tag(NSLocalizedString("cash", comment: "현금"))
                                            Text(NSLocalizedString("card", comment: "카드")).tag(NSLocalizedString("card", comment: "카드"))
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .font(.system(size: 15, weight: .regular, design: .rounded))
                                    }
                                    if paymentType == NSLocalizedString("card", comment: "카드") {
                                        HStack(spacing: 8) {
                                            Image(systemName: "creditcard.fill")
                                                .foregroundColor(.gray)
                                            Picker(NSLocalizedString("select_card", comment: "카드 선택"), selection: $selectedCard) {
                                                Text(NSLocalizedString("카드선택", comment: "카드선택")).tag(nil as Card?)
                                                ForEach(cardViewModel.cards, id: \.self) { card in
                                                    Text(card.name ?? "").tag(card as Card?)
                                                }
                                            }
                                            .font(.system(size: 15, weight: .regular, design: .rounded))
                                            Spacer()
                                            Button(action: { showCardManager = true }) {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.blue)
                                                    .padding(6)
                                                    .background(Color.white.opacity(0.7))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(.top, 2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            // 카테고리
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.gray)
                                Picker(NSLocalizedString("category", comment: ""), selection: $selectedCategory) {
                                    Text(NSLocalizedString("카테고리 선택", comment: "카테고리 선택")).tag(nil as AppCategory?)
                                    ForEach(fetchedCategories, id: \.self) { category in
                                        Text(category.name ?? "").tag(category as AppCategory?)
                                    }
                                }
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                Spacer()
                                Button(action: { showCategoryManager = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.blue)
                                        .padding(6)
                                        .background(Color.white.opacity(0.7))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                            // 상세내용
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.gray)
                                TextField(NSLocalizedString("detail_placeholder", comment: ""), text: $detail)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .padding(10)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            // 날짜
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                DatePicker(NSLocalizedString("date", comment: ""), selection: $date, displayedComponents: .date)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 24)
                    }
                    // 하단 저장 버튼 (키보드가 올라올 때는 숨김)
                    if !keyboard.isKeyboardVisible {
                        Button(action: {
                            saveRecord()
                        }) {
                            Text(recordToEdit == nil ? NSLocalizedString("save", comment: "저장") : NSLocalizedString("edit_done", comment: "수정 완료"))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color("HighlightColor"))
                                .cornerRadius(16)
                                .shadow(radius: 4)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: keyboard.isKeyboardVisible)
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(NSLocalizedString("input_error", comment: "")), message: Text(alertMessage), dismissButton: .default(Text(NSLocalizedString("confirm", comment: ""))))
                }
                .sheet(isPresented: $showCategoryManager, onDismiss: {
                    fetchCategories()
                }) {
                    NavigationStack {
                        CategoryManagerView(selectedType: type)
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(NSLocalizedString("manage_category", comment: "카테고리 관리"))
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                            }
                    }
                }
                .sheet(isPresented: $showCardManager, onDismiss: {
                    cardViewModel.fetchCards()
                }) {
                    NavigationStack {
                        CardListView()
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(NSLocalizedString("card_management", comment: "카드 관리"))
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                            }
                    }
                }
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
                        detail = record.detail ?? ""
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        amount = formatter.string(from: NSNumber(value: Int(record.amount))) ?? ""
                        date = record.date ?? Date()
                        paymentType = record.paymentType ?? "현금"
                        selectedCard = record.card
                        selectedCategory = record.categoryRelation
                    } else {
                        type = NSLocalizedString("expense", comment: "")
                        selectedCategory = nil
                    }
                    fetchCategories()
                }
                .onChange(of: type) {
                    fetchCategories()
                }
            }
            .background(Color("BackgroundSolidColor"))
        }
    }

    private func saveRecord() {
        let numberString = amount.replacingOccurrences(of: ",", with: "")
        guard !numberString.isEmpty, let intValue = Int(numberString), intValue > 0 else {
            alertMessage = NSLocalizedString("invalid_amount_alert", comment: "금액을 입력해주세요.")
            showAlert = true
            return
        }

        // 카드 결제 시 카드 선택 필수
        if type == NSLocalizedString("expense", comment: "") && paymentType == "카드" && selectedCard == nil {
            alertMessage = NSLocalizedString("select_card_alert", comment: "카드를 선택해주세요.")
            showAlert = true
            return
        }

        guard selectedCategory != nil else {
            alertMessage = NSLocalizedString("select_category_alert", comment: "카테고리를 선택해주세요.")
            showAlert = true
            return
        }

        let record = recordToEdit ?? Record(context: viewContext)

        if recordToEdit == nil {
            record.id = UUID()
        }

        record.type = type
        record.detail = detail
        record.amount = Double(intValue)
        record.date = date
        record.paymentType = paymentType
        record.card = selectedCard
        record.categoryRelation = selectedCategory

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }
    
    private func fetchCategories() {
        let request: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AppCategory.name, ascending: true)]
        request.predicate = NSPredicate(format: "type == %@", type == NSLocalizedString("income", comment: "") ? "income" : "expense")

        do {
            let results = try viewContext.fetch(request)
            // 필터: 이름이 비어 있지 않고 실제로 사용되거나 추가된 것으로 간주
            fetchedCategories = results.filter { !($0.name?.isEmpty ?? true) }
        } catch {
            print("❌ 카테고리 불러오기 실패: \(error)")
        }
    }
}
