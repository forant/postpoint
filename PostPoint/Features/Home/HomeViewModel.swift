import Foundation
import SwiftData
import SwiftUI

@Observable
final class HomeViewModel {
    var showingDebrief = false

    func matchCount(_ matches: [Match]) -> Int {
        matches.count
    }

    func recentMatches(_ matches: [Match], limit: Int = 5) -> [Match] {
        Array(matches.prefix(limit))
    }
}
