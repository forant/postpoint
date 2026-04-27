import SwiftUI

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Insights Coming Soon",
                systemImage: "chart.xyaxis.line",
                description: Text("Track patterns and improve your game over time.")
            )
            .navigationTitle("Insights")
        }
    }
}

#Preview {
    InsightsView()
}
