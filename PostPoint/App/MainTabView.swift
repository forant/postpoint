import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }

            Tab("History", systemImage: "clock.fill") {
                HistoryView()
            }

            Tab("Opponents", systemImage: "person.2.fill") {
                OpponentsView()
            }

            Tab("Insights", systemImage: "chart.xyaxis.line") {
                InsightsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Match.self, inMemory: true)
}
