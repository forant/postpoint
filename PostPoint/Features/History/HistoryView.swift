import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView(
                        "No Matches",
                        systemImage: "sportscourt",
                        description: Text("Your match history will appear here after you debrief.")
                    )
                } else {
                    List(viewModel.filteredMatches(matches)) { match in
                        MatchRowView(match: match)
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Search matches")
                }
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: Match.self, inMemory: true)
}
