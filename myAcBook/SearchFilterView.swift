// SearchFilterView.swift

import SwiftUI

struct SearchFilterView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedType: String
    @Binding var selectedCategory: String
    @Binding var selectedDate: String
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date

    @ObservedObject var categoryManager: CategoryManager

    var body: some View {
        NavigationView {
            Form {
                Section {
                    EmptyView()
                        .frame(height: 8)
                }

                Section(header: Text("유형")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)) {
                    Picker("유형", selection: $selectedType) {
                        Text("전체").tag("전체")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                        Text("수입").tag("수입")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                        Text("지출").tag("지출")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.bottom, 8)

                Section {
                    VStack(alignment: .leading) {
                        Text("카테고리 선택")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                        Picker(selection: $selectedCategory) {
                            Text("전체").tag("전체")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                            let categories = selectedType == "수입" ? categoryManager.incomeCategories : categoryManager.expenseCategories
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                            }
                        } label: {
                            Text("카테고리").font(.system(size: 14, weight: .regular, design: .rounded))
                        }
                    }
                }
                .headerProminence(.increased)
                .padding(.bottom, 8)

                Section(header: Text("기간")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)) {
                    Picker(selection: $selectedDate) {
                        Text("전체")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag("전체")
                        Text("오늘")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag("오늘")
                        Text("어제")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag("어제")
                        Text("1주일")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag("1주일")
                        Text("한달")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag("한달")
                        Text("직접 선택")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .tag("직접 선택")
                    } label: {
                        Text("기간").font(.system(size: 14, weight: .regular, design: .rounded))
                    }
                    if selectedDate == "직접 선택" {
                        DatePicker("시작 날짜", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("종료 날짜", selection: $customEndDate, displayedComponents: .date)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("필터 설정")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("적용") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }
}
