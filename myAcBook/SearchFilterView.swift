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
                            .font(.subheadline)
                            .foregroundColor(.secondary)) {
                    Picker("유형", selection: $selectedType) {
                        Text("전체").tag("전체")
                        Text("수입").tag("수입")
                        Text("지출").tag("지출")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.bottom, 8)

                Section {
                    VStack(alignment: .leading) {
                        Text("카테고리 선택")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Picker("카테고리", selection: $selectedCategory) {
                            Text("전체").tag("전체")
                            let categories = selectedType == "수입" ? categoryManager.incomeCategories : categoryManager.expenseCategories
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                }
                .headerProminence(.increased)
                .padding(.bottom, 8)

                Section(header: Text("기간")
                            .font(.subheadline)
                            .foregroundColor(.secondary)) {
                    Picker("기간", selection: $selectedDate) {
                        Text("전체").tag("전체")
                        Text("오늘").tag("오늘")
                        Text("어제").tag("어제")
                        Text("1주일").tag("1주일")
                        Text("한달").tag("한달")
                        Text("직접 선택").tag("직접 선택")
                    }
                    if selectedDate == "직접 선택" {
                        DatePicker("시작 날짜", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("종료 날짜", selection: $customEndDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("필터 설정")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("적용") {
                        dismiss()
                    }
                }
            }
        }
    }
}
