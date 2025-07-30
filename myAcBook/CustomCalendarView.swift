import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let incomeExpenseByDate: [Date: (income: Double, expense: Double)]
    let onConfirm: () -> Void
    let onToday: (() -> Void)?
    
    @State private var displayMonth: Date = Date()
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 네비게이션
            HStack {
                Button(action: { moveMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                Spacer()
                Text(monthTitle(displayMonth))
                    .font(.title3).bold()
                    .foregroundColor(.blue)
                Spacer()
                Button(action: { moveMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                Button(action: {
                    displayMonth = Date()
                    onToday?()
                }) {
                    Text("오늘")
                        .font(.subheadline).bold()
                        .foregroundColor(.blue)
                        .padding(.leading, 8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            // 요일 헤더
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \ .self) { day in
                    Text(day)
                        .font(.subheadline).bold()
                        .foregroundColor(day == "일" ? .pink : (day == "토" ? .blue : .primary))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            // 날짜 그리드
            let days = makeDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \ .self) { day in
                    dayCell(day: day)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
            // 확인 버튼
            Button(action: { onConfirm() }) {
                Text("확인")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(radius: 8)
    }
    
    // MARK: - Helpers
    func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }
    func moveMonth(_ offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayMonth) {
            displayMonth = newMonth
        }
    }
    func makeDays() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysCount = calendar.range(of: .day, in: .month, for: displayMonth)?.count ?? 0
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 1...daysCount {
            if let date = calendar.date(bySetting: .day, value: day, of: monthInterval.start) {
                days.append(date)
            }
        }
        return days
    }
    @ViewBuilder
    func dayCell(day: Date?) -> some View {
        if let date = day {
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            let isToday = calendar.isDateInToday(date)
            let info = incomeExpenseByDate[calendar.startOfDay(for: date)]
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle().fill(Color.blue.opacity(0.2)).frame(width: 36, height: 36)
                    } else if isToday {
                        Circle().stroke(Color.blue, lineWidth: 2).frame(width: 36, height: 36)
                    }
                    Text("\(calendar.component(.day, from: date))")
                        .font(.headline)
                        .foregroundColor(isSelected ? .blue : (isToday ? .blue : .primary))
                }
                if let info = info {
                    Text("+\(formatAmount(info.income))")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("-\(formatAmount(info.expense))")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else {
                    Spacer().frame(height: 18)
                }
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedDate = date
            }
        } else {
            Spacer().frame(height: 48)
        }
    }
    func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// 미리보기용
struct CustomCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCalendarView(
            selectedDate: .constant(Date()),
            incomeExpenseByDate: [
                Calendar.current.startOfDay(for: Date()): (income: 100000, expense: 50000)
            ],
            onConfirm: {},
            onToday: nil
        )
        .frame(height: 420)
    }
}