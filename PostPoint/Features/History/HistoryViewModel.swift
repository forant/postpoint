import Foundation

@Observable
final class HistoryViewModel {
    var searchText = ""

    func filteredMatches(_ matches: [Match]) -> [Match] {
        guard !searchText.isEmpty else { return matches }
        return matches.filter { match in
            match.opponentName.localizedCaseInsensitiveContains(searchText) ||
            match.sport.rawValue.localizedCaseInsensitiveContains(searchText) ||
            match.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
}
