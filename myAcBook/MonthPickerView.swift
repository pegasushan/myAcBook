import SwiftUI

struct MonthPickerView: View {
    @Binding var selectedMonth: Date
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            DatePicker(
                "월 선택",
                selection: $selectedMonth,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            Button(action: onConfirm) {
                Text("확인")
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
        .padding(.top, 16)
        .background(Color.white)
        .cornerRadius(18)
    }
}