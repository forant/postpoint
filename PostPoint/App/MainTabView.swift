import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView(tabSelection: $selectedTab)
            }

            Tab("History", systemImage: "clock.fill", value: 1) {
                HistoryView()
            }

            Tab("Opponents", systemImage: "person.2.fill", value: 2) {
                OpponentsView()
            }

            Tab("Insights", systemImage: "chart.xyaxis.line", value: 3) {
                InsightsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Match.self, inMemory: true)
}
