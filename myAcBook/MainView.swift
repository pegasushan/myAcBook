import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label(NSLocalizedString("ledger_tab", comment: "가계부 탭"), systemImage: "list.bullet.rectangle.portrait")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                }
            ChartView()
                .tabItem {
                    Label(NSLocalizedString("statistics_tab", comment: "통계 탭"), systemImage: "chart.pie")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                }
        }
    }
}
