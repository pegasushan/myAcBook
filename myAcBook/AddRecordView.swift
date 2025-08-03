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

struct CustomDropdown: View {
    @Binding var selectedIndex: Int?
    let options: [String]
    let placeholder: String
    var onDropdownTap: (() -> Void)? = nil
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                onDropdownTap?()
                withAnimation { isExpanded.toggle() }
            }) {
                HStack {
                    // 선택된 카테고리명에 로컬라이징 적용
                    Text(selectedIndex.flatMap { options[safe: $0] } ?? placeholder)
                        .foregroundColor(colorScheme == .light ? .primary : .white)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colorScheme == .light ? Color.white : Color("customDarkCardColor").opacity(0.85))
                        .shadow(color: colorScheme == .light ? Color.gray.opacity(0.08) : Color.black.opacity(0.3), radius: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(colorScheme == .dark ? Color("HighlightColor").opacity(0.25) : Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(options.indices, id: \.self) { idx in
                        Button(action: {
                            print("[CustomDropdown] 선택 idx: \(idx), options.count: \(options.count)")
                            if idx < options.count {
                                selectedIndex = idx
                            }
                            withAnimation { isExpanded = false }
                        }) {
                            HStack {
                                Text(options[idx])
                                    .foregroundColor(colorScheme == .light ? .primary : .white)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .background(colorScheme == .light ? Color.white : Color("customDarkSectionColor").opacity(0.85))
                        .contentShape(Rectangle())
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colorScheme == .light ? Color.white : Color("customDarkSectionColor").opacity(0.85))
                        .shadow(color: colorScheme == .light ? Color.gray.opacity(0.08) : Color.black.opacity(0.3), radius: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: isExpanded)
        .onAppear {
            print("[CustomDropdown] options: \(options), selectedIndex: \(selectedIndex?.description ?? "nil")")
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct CategoryDropdown: View {
    @Binding var selectedCategoryIndex: Int?
    let options: [String]
    let onDropdownTap: () -> Void
    var body: some View {
        CustomDropdown(
            selectedIndex: $selectedCategoryIndex,
            options: options,
            placeholder: NSLocalizedString("select_category", comment: "카테고리 선택"),
            onDropdownTap: onDropdownTap
        )
    }
}

struct AmountInputView: View {
    @Binding var amount: String
    @FocusState var isAmountFieldFocused: Bool
    var colorScheme: ColorScheme
    var body: some View {
        HStack {
            Image(systemName: "wonsign.circle.fill")
                .foregroundColor(Color("HighlightColor"))
                .font(.system(size: 28, weight: .bold))
            TextField(NSLocalizedString("example_amount", comment: ""), text: $amount)
                .keyboardType(.decimalPad)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .padding(12)
                .background(colorScheme == .light ? Color.white.opacity(0.7) : Color("customDarkCardColor").opacity(0.85))
                .foregroundColor(colorScheme == .light ? .primary : .white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorScheme == .dark ? Color("HighlightColor").opacity(0.25) : Color.gray.opacity(0.15), lineWidth: 1)
                )
                .focused($isAmountFieldFocused)
                .onTapGesture {
                    isAmountFieldFocused = true
                }
                .onChange(of: amount) { _,_ in
                    let numberString = amount.replacingOccurrences(of: ",", with: "")
                    if let value = Int(numberString) {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        amount = formatter.string(from: NSNumber(value: value)) ?? ""
                    }
                }
        }
        .padding(.horizontal)
    }
}

struct TypePickerView: View {
    @Binding var type: String
    let types: [String]
    var recordToEdit: Record?
    @FocusState var isAmountFieldFocused: Bool
    @FocusState var isDetailFieldFocused: Bool
    var body: some View {
        HStack {
            Image(systemName: "arrow.2.squarepath")
                .foregroundColor(.gray)
            Picker(NSLocalizedString("type_label", comment: ""), selection: $type) {
                ForEach(types, id: \.self) { t in
                    Text(t)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                }
            }
            .pickerStyle(.segmented)
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .disabled(recordToEdit != nil)
            .onTapGesture {
                isAmountFieldFocused = false
                isDetailFieldFocused = false
            }
        }
        .padding(.horizontal)
    }
}

struct PaymentTypeView: View {
    @Binding var paymentType: String
    @Binding var selectedCardIndex: Int?
    @Binding var selectedCard: Card?
    @ObservedObject var cardViewModel: CardViewModel
    @FocusState var isAmountFieldFocused: Bool
    @FocusState var isDetailFieldFocused: Bool
    var colorScheme: ColorScheme
    let showCardManager: () -> Void // 추가
    var body: some View {
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
                .onTapGesture {
                    isAmountFieldFocused = false
                    isDetailFieldFocused = false
                }
            }
            if paymentType == NSLocalizedString("card", comment: "카드") {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.gray)
                    CustomDropdown(
                        selectedIndex: $selectedCardIndex,
                        options: cardViewModel.cards.map { $0.name ?? "" },
                        placeholder: NSLocalizedString("select_card_placeholder", comment: "카드 선택"),
                        onDropdownTap: {
                            isAmountFieldFocused = false
                            isDetailFieldFocused = false
                        }
                    )
                    .frame(maxWidth: .infinity)
                    Button(action: showCardManager) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(colorScheme == .light ? Color.white.opacity(0.7) : Color("customDarkCardColor").opacity(0.85))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 12)
            }
        }
        .padding(.horizontal)
    }
}

struct CategoryInputView: View {
    @Binding var selectedCategoryIndex: Int?
    let options: [String]
    let onDropdownTap: () -> Void
    let showCategoryManager: () -> Void
    var colorScheme: ColorScheme
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .foregroundColor(.gray)
            CategoryDropdown(
                selectedCategoryIndex: $selectedCategoryIndex,
                options: options,
                onDropdownTap: onDropdownTap
            )
            .frame(maxWidth: .infinity)
            Button(action: showCategoryManager) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(6)
                    .background(colorScheme == .light ? Color.white.opacity(0.7) : Color("customDarkCardColor").opacity(0.85))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
}

struct DetailInputView: View {
    @Binding var detail: String
    @FocusState var isDetailFieldFocused: Bool
    @FocusState var isAmountFieldFocused: Bool
    var colorScheme: ColorScheme
    var body: some View {
        HStack {
            Image(systemName: "text.alignleft")
                .foregroundColor(.gray)
            TextField(NSLocalizedString("detail_placeholder", comment: ""), text: $detail)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .padding(10)
                .background(colorScheme == .light ? Color.white.opacity(0.7) : Color("customDarkCardColor").opacity(0.85))
                .foregroundColor(colorScheme == .light ? .primary : .white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colorScheme == .dark ? Color("HighlightColor").opacity(0.25) : Color.gray.opacity(0.15), lineWidth: 1)
                )
                .focused($isDetailFieldFocused)
                .onTapGesture {
                    isDetailFieldFocused = true
                    isAmountFieldFocused = false
                }
        }
        .padding(.horizontal)
    }
}

struct DateInputView: View {
    @Binding var date: Date
    var colorScheme: ColorScheme
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.gray)
            DatePicker(NSLocalizedString("date", comment: ""), selection: $date, displayedComponents: .date)
                .font(.system(size: 15, weight: .regular, design: .rounded))
        }
        .padding(.horizontal)
    }
}

struct RecordFormView: View {
    @Binding var amount: String
    @Binding var type: String
    let types: [String]
    var recordToEdit: Record?
    @Binding var paymentType: String
    @Binding var selectedCardIndex: Int?
    @Binding var selectedCard: Card?
    @ObservedObject var cardViewModel: CardViewModel
    @Binding var selectedCategoryIndex: Int?
    let categoryOptions: [String]
    @Binding var detail: String
    @Binding var date: Date
    @FocusState var isAmountFieldFocused: Bool
    @FocusState var isDetailFieldFocused: Bool
    let expenseText: String
    let colorScheme: ColorScheme
    let showCategoryManager: () -> Void
    let showCardManager: () -> Void // 추가
    let onDropdownTap: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                AmountInputView(amount: $amount, isAmountFieldFocused: _isAmountFieldFocused, colorScheme: colorScheme)
                TypePickerView(
                    type: $type,
                    types: types,
                    recordToEdit: recordToEdit,
                    isAmountFieldFocused: _isAmountFieldFocused,
                    isDetailFieldFocused: _isDetailFieldFocused
                )
                if type == expenseText {
                    PaymentTypeView(
                        paymentType: $paymentType,
                        selectedCardIndex: $selectedCardIndex,
                        selectedCard: $selectedCard,
                        cardViewModel: cardViewModel,
                        isAmountFieldFocused: _isAmountFieldFocused,
                        isDetailFieldFocused: _isDetailFieldFocused,
                        colorScheme: colorScheme,
                        showCardManager: showCardManager // 전달
                    )
                }
                CategoryInputView(
                    selectedCategoryIndex: $selectedCategoryIndex,
                    options: categoryOptions,
                    onDropdownTap: onDropdownTap,
                    showCategoryManager: showCategoryManager,
                    colorScheme: colorScheme
                )
                DetailInputView(
                    detail: $detail,
                    isDetailFieldFocused: _isDetailFieldFocused,
                    isAmountFieldFocused: _isAmountFieldFocused,
                    colorScheme: colorScheme
                )
                DateInputView(date: $date, colorScheme: colorScheme)
            }
            .padding(.top, 48)
            .padding(.bottom, 32)
        }
        .background(Color.clear)
        .onTapGesture {
            isAmountFieldFocused = false
            isDetailFieldFocused = false
        }
    }
}

struct AddRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("customLightBGColor") private var customLightBGColorHex: String = "#FEEAF2"
    @AppStorage("customDarkBGColor") private var customDarkBGColorHex: String = "#181A20"
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    @AppStorage("customLightSectionColor") private var customLightSectionColorHex: String = "#F6F7FA"
    @AppStorage("customDarkSectionColor") private var customDarkSectionColorHex: String = "#23272F"

    // customBGColor, customCardColor, customSectionColor 등 변수 선언부 모두 삭제
    // 배경색, 카드색, 섹션색 사용하는 모든 곳을 AppColors.background, AppColors.card, AppColors.section으로 교체
    // 예시: .background(customBGColor.ignoresSafeArea()) -> .background(AppColors.background.ignoresSafeArea())
    // ZStack, VStack, Section 등에서 배경색 지정 시 AppColors 사용
    @Environment(\.colorScheme) var colorScheme

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
    @FetchRequest(
        entity: AppCategory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AppCategory.name, ascending: true)]
    ) var fetchedCategories: FetchedResults<AppCategory>

    var categoryOptions: [String] {
        let typeKey: String
        if type == NSLocalizedString("income", comment: "") || type == "수입" {
            typeKey = "income"
        } else {
            typeKey = "expense"
        }
        return fetchedCategories
            .filter { ($0.type == typeKey) && !($0.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
            .map { $0.name ?? "" }
    }

    var recordToEdit: Record?
    var onSave: (() -> Void)? = nil
    var defaultDate: Date? = nil // 추가: 외부에서 날짜를 받을 수 있도록

    @State private var showCardDropdown = false
    @State private var showCategoryDropdown = false

    @State private var selectedCategoryIndex: Int? = nil
    @State private var selectedCardIndex: Int? = nil

    @FocusState private var isAmountFieldFocused: Bool
    @FocusState private var isDetailFieldFocused: Bool

    init(defaultDate: Date? = nil, recordToEdit: Record? = nil, onSave: (() -> Void)? = nil) {
        self.defaultDate = defaultDate
        self.recordToEdit = recordToEdit
        self.onSave = onSave
        // date State 초기값 세팅
        if let record = recordToEdit {
            _date = State(initialValue: record.date ?? Date())
        } else if let defaultDate = defaultDate {
            _date = State(initialValue: defaultDate)
        } else {
            _date = State(initialValue: Date())
        }
    }

    var body: some View {
        let expenseText = NSLocalizedString("expense", comment: "")
        NavigationView {
            ZStack(alignment: .bottom) {
                AppColors.background.ignoresSafeArea()
                RecordFormView(
                    amount: $amount,
                    type: $type,
                    types: types,
                    recordToEdit: recordToEdit,
                    paymentType: $paymentType,
                    selectedCardIndex: $selectedCardIndex,
                    selectedCard: $selectedCard,
                    cardViewModel: cardViewModel,
                    selectedCategoryIndex: $selectedCategoryIndex,
                    categoryOptions: categoryOptions,
                    detail: $detail,
                    date: $date,
                    isAmountFieldFocused: _isAmountFieldFocused,
                    isDetailFieldFocused: _isDetailFieldFocused,
                    expenseText: expenseText,
                    colorScheme: colorScheme,
                    showCategoryManager: { showCategoryManager = true },
                    showCardManager: { showCardManager = true },
                    onDropdownTap: {
                        isAmountFieldFocused = false
                        isDetailFieldFocused = false
                    }
                )
                VStack {
                    Spacer()
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
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(NSLocalizedString("input_error", comment: "")), message: Text(alertMessage), dismissButton: .default(Text(NSLocalizedString("confirm", comment: ""))))
                }
                .sheet(isPresented: $showCategoryManager) {
                    NavigationStack {
                        CategoryManagerView(selectedType: type)
                    }
                }
                .sheet(isPresented: $showCardManager, onDismiss: {
                    cardViewModel.fetchCards()
                }) {
                    NavigationStack {
                        CardListView()
                    }
                }
                .onAppear {
                    if let record = recordToEdit {
                        // 1. type을 가장 먼저 세팅
                        type = record.type ?? NSLocalizedString("expense", comment: "")
                        detail = record.detail ?? ""
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        amount = formatter.string(from: NSNumber(value: Int(record.amount))) ?? ""
                        date = record.date ?? Date()
                        paymentType = record.paymentType ?? "현금"
                        selectedCard = record.card
                        // 2. selectedCategory를 세팅
                        selectedCategory = record.categoryRelation
                        // 3. categoryOptions 최신화 후 인덱스 동기화
                        DispatchQueue.main.async {
                            print("categoryOptions: \(categoryOptions)")
                            print("record.categoryRelation?.name: '\(record.categoryRelation?.name ?? "nil")'")
                            if let categoryKey = record.categoryRelation?.name,
                               let idx = categoryOptions.firstIndex(of: categoryKey) {
                                selectedCategoryIndex = idx
                            } else {
                                selectedCategoryIndex = nil
                            }
                            print("selectedCategoryIndex: \(selectedCategoryIndex?.description ?? "nil")")
                        }
                        if let card = record.card, let idx = cardViewModel.cards.firstIndex(where: { $0.objectID == card.objectID }) {
                            selectedCardIndex = idx
                        }
                    }
                }
                .onChange(of: selectedCategoryIndex) { _,_ in
                    if let idx = selectedCategoryIndex, categoryOptions.indices.contains(idx) {
                        let name = categoryOptions[idx]
                        if let cat = fetchedCategories.first(where: { $0.name == name }) {
                            selectedCategory = cat
                        }
                    }
                }
                .onChange(of: selectedCardIndex) { _,_ in
                    if let idx = selectedCardIndex, cardViewModel.cards.indices.contains(idx) {
                        selectedCard = cardViewModel.cards[idx]
                    }
                }
                .onReceive(fetchedCategories.publisher.collect()) { _ in
                    // selectedCategoryIndex를 fetchedCategories 기준으로 세팅하는 코드를 제거하여, 항상 categoryOptions 기준으로만 동기화되도록 한다.
                }
                .onChange(of: cardViewModel.cards) { _,_ in
                    if let selected = selectedCard,
                       let idx = cardViewModel.cards.firstIndex(where: { $0.objectID == selected.objectID }) {
                        selectedCardIndex = idx
                    }
                }
                .onChange(of: type) { _,_ in
                    // type(지출/수입)이 바뀔 때마다 선택된 카테고리와 인덱스를 모두 초기화
                    selectedCategory = nil
                    selectedCategoryIndex = nil
                    print("[type changed] type: \(type), categoryOptions: \(categoryOptions), selectedCategoryIndex: nil (reset)")
                }
                .onChange(of: categoryOptions) { _,_ in
                    // categoryOptions가 바뀔 때마다 selectedCategoryIndex를 재동기화
                    if let selectedCategory = selectedCategory,
                       let name = selectedCategory.name,
                       let idx = categoryOptions.firstIndex(of: name) {
                        selectedCategoryIndex = idx
                    } else {
                        selectedCategoryIndex = nil
                    }
                    print("[categoryOptions changed] new options: \(categoryOptions), selectedCategoryIndex: \(selectedCategoryIndex?.description ?? "nil")")
                }
                .onChange(of: amount) { _,_ in
                    let numberString = amount.replacingOccurrences(of: ",", with: "")
                    if let value = Int(numberString) {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        amount = formatter.string(from: NSNumber(value: value)) ?? ""
                    }
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
        let dateOnly = Calendar.current.startOfDay(for: date)
        record.date = dateOnly
        record.paymentType = paymentType
        record.card = selectedCard
        record.categoryRelation = selectedCategory

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try viewContext.save()
                DispatchQueue.main.async {
                    onSave?()
                    dismiss()
                }
            } catch {
                print("Save error: \(error.localizedDescription)")
            }
        }
        NotificationCenter.default.post(name: Notification.Name("RecordAdded"), object: date)
    }
    
    private func fetchCategories() {
        // This function is no longer needed as fetchedCategories is a @FetchRequest
    }

    // 금액 입력란 왼쪽 아이콘에 사용할 통화별 SF Symbol 반환 함수 추가
    private func currencySymbolSystemName() -> String {
        if Locale.current.language.languageCode?.identifier == "en" {
            return "dollarsign.circle.fill"
        }
        switch Locale.current.currency?.identifier {
        case "USD": return "dollarsign.circle.fill"
        case "EUR": return "eurosign.circle.fill"
        case "JPY": return "yensign.circle.fill"
        case "KRW": return "wonsign.circle.fill"
        default: return "banknote.fill"
        }
    }
}

extension AddRecordView {
    var expenseText: String {
        NSLocalizedString("expense", comment: "")
    }
}
