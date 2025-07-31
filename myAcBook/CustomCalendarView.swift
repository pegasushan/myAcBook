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
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(
                            day == "일" ? Color(red: 1, green: 0.2, blue: 0.5) :
                            day == "토" ? Color.blue :
                            Color.gray
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            // 날짜 그리드
            let days = makeDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    dayCell(day: day)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
            // 확인 버튼
            Spacer().frame(height: 8)
            Button(action: { onConfirm() }) {
                Text("확인")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .background(Color.white)
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
            let isSunday = calendar.component(.weekday, from: date) == 1
            let isSaturday = calendar.component(.weekday, from: date) == 7
            let info = incomeExpenseByDate[calendar.startOfDay(for: date)]
            VStack(spacing: 0) {
                ZStack {
                    if isSelected {
                        Circle().fill(Color.blue).frame(width: 36, height: 36)
                    } else if isToday {
                        Circle().fill(Color.blue.opacity(0.15)).frame(width: 36, height: 36)
                    } else if isSunday || isSaturday {
                        Circle().fill(Color.gray.opacity(0.08)).frame(width: 36, height: 36)
                    }
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(
                            isSelected ? .white :
                            isToday ? .blue :
                            isSunday ? Color(red: 1, green: 0.2, blue: 0.5) :
                            isSaturday ? .blue :
                            .black
                        )
                }
                .padding(.bottom, 2)
                if let info = info {
                    VStack(spacing: 0) {
                        if info.income != 0 {
                            Text("+\(formatAmount(info.income))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        if info.expense != 0 {
                            Text("-\(formatAmount(info.expense))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Spacer().frame(height: 16)
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