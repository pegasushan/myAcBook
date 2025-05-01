import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("가계부", systemImage: "list.bullet.rectangle.portrait")
                }
            ChartView()
                .tabItem {
                    Label("통계", systemImage: "chart.pie")
                }
        }
    }
}
