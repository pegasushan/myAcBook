import SwiftUI
import UIKit

struct CustomCalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedDate: Date
    let incomeExpenseByDate: [Date: (income: Double, expense: Double)]
    let onConfirm: () -> Void
    let onToday: (() -> Void)?
    
    @State private var displayMonth: Date = Date()
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 네비게이션
            HStack(spacing: 4) {
                HStack(spacing: 4) {
                    Button(action: { moveMonth(-1) }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    Text(monthTitle(displayMonth))
                        .font(.title3).bold()
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .frame(minWidth: 90) // 최소 너비 확보
                    Button(action: { moveMonth(1) }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
                Button(action: {
                    displayMonth = Date()
                    onToday?()
                }) {
                    Text("오늘")
                        .font(.subheadline).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(red: 1.0, green: 0.5, blue: 0.7)) // 파스텔 핑크
                        .cornerRadius(12)
                        .padding(.leading, 6)
                }
            }
            .padding(.horizontal)
            .padding(.top, 2)
            .padding(.bottom, 12)
            // 요일 헤더
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(
                            day == "일" ? Color(red: 1, green: 0.6, blue: 0.7) : // 파스텔 핑크
                            day == "토" ? Color(red: 0.5, green: 0.7, blue: 1.0) : // 파스텔 블루
                            Color(white: 0.85) // 더 밝은 회색
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
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
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 1.0, green: 0.5, blue: 0.7)) // 파스텔 핑크
                    .cornerRadius(16)
                    .shadow(radius: 4)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(18)
        .shadow(radius: 12)
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
            VStack(spacing: 0) {
                ZStack {
                    if isSelected {
                        Circle().fill(Color(red: 1.0, green: 0.5, blue: 0.7)).frame(width: 36, height: 36) // 진한 파스텔 핑크
                    } else if isToday {
                        Circle().fill(Color(red: 1.0, green: 0.5, blue: 0.7).opacity(0.18)).frame(width: 36, height: 36) // 연한 파스텔 핑크
                    } else if info != nil {
                        Circle().fill(Color(red: 1.0, green: 0.85, blue: 0.92).opacity(0.7)).frame(width: 36, height: 36) // 연한 파스텔 핑크
                    }
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(
                            isSelected ? .white :
                            isToday ? Color(red: 1.0, green: 0.5, blue: 0.7) :
                            calendar.component(.weekday, from: date) == 1 ? Color(red: 1, green: 0.6, blue: 0.7) :
                            calendar.component(.weekday, from: date) == 7 ? Color(red: 1.0, green: 0.5, blue: 0.7) :
                            .primary
                        )
                }
                .padding(.top, 6)
                .padding(.bottom, 2)
                if let info = info {
                    // 항상 두 줄 공간 확보
                    if info.income != 0 {
                        Text("+\(formatAmount(info.income))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0)) // 파스텔 블루
                    } else {
                        Text(" ")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.clear)
                    }
                    if info.expense != 0 {
                        Text("-\(formatAmount(info.expense))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.5)) // 파스텔 레드
                    } else {
                        Text(" ")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.clear)
                    }
                } else {
                    // 둘 다 없는 경우에도 두 줄 확보
                    Text(" ").font(.system(size: 10, weight: .bold)).foregroundColor(.clear)
                    Text(" ").font(.system(size: 10, weight: .bold)).foregroundColor(.clear)
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