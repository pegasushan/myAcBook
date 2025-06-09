import SwiftUI

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var cardViewModel = CardViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var monthlyIncomeTotals: [String: Double] = [:]
    @State private var monthlyExpenseTotals: [String: Double] = [:]
    @State private var monthlyCategoryIncomeTotals: [String: [String: Double]] = [:]
    @State private var monthlyCategoryExpenseTotals: [String: [String: Double]] = [:]
    @State private var monthlyCardExpenseTotals: [String: [String: Double]] = [:]
    @State private var selectedTypeFilter: String = "all"
    @State private var selectedCategory: String = "all"
    @State private var selectedDateFilter: String = "all"
    @State private var dateRangeText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                ContentView(
                    onStatisticsDataChanged: { income, expense, catIncome, catExpense, cardExpense, typeFilter, category, dateFilter, dateRange in
                        self.monthlyIncomeTotals = income
                        self.monthlyExpenseTotals = expense
                        self.monthlyCategoryIncomeTotals = catIncome
                        self.monthlyCategoryExpenseTotals = catExpense
                        self.monthlyCardExpenseTotals = cardExpense
                        self.selectedTypeFilter = typeFilter
                        self.selectedCategory = category
                        self.selectedDateFilter = dateFilter
                        self.dateRangeText = dateRange
                    }
                )
                .tabItem {
                    Label(NSLocalizedString("ledger_tab", comment: "가계부 탭"), systemImage: "list.bullet.rectangle.portrait")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                }
                StatisticsTabView(
                    monthlyIncomeTotals: monthlyIncomeTotals,
                    monthlyExpenseTotals: monthlyExpenseTotals,
                    monthlyCategoryIncomeTotals: monthlyCategoryIncomeTotals,
                    monthlyCategoryExpenseTotals: monthlyCategoryExpenseTotals,
                    monthlyCardExpenseTotals: monthlyCardExpenseTotals,
                    formattedAmount: { amount in
                        let numberFormatter = NumberFormatter()
                        numberFormatter.numberStyle = .decimal
                        numberFormatter.maximumFractionDigits = 0
                        numberFormatter.groupingSeparator = ","
                        return numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
                    },
                    allCards: cardViewModel.cards,
                    selectedTypeFilter: selectedTypeFilter,
                    selectedCategory: selectedCategory,
                    selectedDateFilter: selectedDateFilter,
                    dateRangeText: dateRangeText,
                    onTap: {},
                    onReset: {}
                )
                .tabItem {
                    Label(NSLocalizedString("statistics_tab", comment: "통계 탭"), systemImage: "chart.pie")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                }
                SettingsView()
                    .tabItem {
                        Label(NSLocalizedString("settings_tab", comment: "설정 탭"), systemImage: "gearshape")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                    }
            }
            BannerAdContainerView()
                .frame(height: 50)
                .ignoresSafeArea(.keyboard)
        }
    }
}
