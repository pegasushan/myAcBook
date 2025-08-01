import SwiftUI

struct MonthPickerView: View {
    @Binding var selectedMonth: Date
    var onConfirm: () -> Void

    // 연/월 데이터 생성
    private let years: [Int] = Array(2000...2100)
    private let months: [Int] = Array(1...12)

    @State private var selectedYear: Int
    @State private var selectedMonthValue: Int

    init(selectedMonth: Binding<Date>, onConfirm: @escaping () -> Void) {
        self._selectedMonth = selectedMonth
        self.onConfirm = onConfirm

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth.wrappedValue)
        _selectedYear = State(initialValue: components.year ?? calendar.component(.year, from: Date()))
        _selectedMonthValue = State(initialValue: components.month ?? calendar.component(.month, from: Date()))
    }

    var body: some View {
        VStack {
            HStack {
                Picker("연도", selection: $selectedYear) {
                    ForEach(years, id: \ .self) { year in
                        Text("\(String(year))년").tag(year)
                    }
                }
                .frame(width: 100)
                Picker("월", selection: $selectedMonthValue) {
                    ForEach(months, id: \ .self) { month in
                        Text("\(month)월").tag(month)
                    }
                }
                .frame(width: 80)
            }
            .pickerStyle(WheelPickerStyle())
            .labelsHidden()

            Button(action: {
                // 연/월로 Date 생성 (항상 1일)
                let calendar = Calendar.current
                if let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonthValue, day: 1)) {
                    selectedMonth = date
                }
                onConfirm()
            }) {
                Text("확인")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 1.0, green: 0.5, blue: 0.7)) // 파스텔 핑크
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.top, 16)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
    }
}