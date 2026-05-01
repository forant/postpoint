import Foundation

/// Generates post-match debrief analysis via the PostPoint backend.
struct DebriefService {

    // MARK: - Public API

    func generateDebrief(from input: DebriefInput, opponentHistory: String? = nil, playerProfile: PlayerProfile? = nil) async throws -> DebriefResult {
        return try await callBackend(input: input, opponentHistory: opponentHistory, playerProfile: playerProfile)
    }

    // MARK: - Backend Call

    private func callBackend(input: DebriefInput, opponentHistory: String? = nil, playerProfile: PlayerProfile? = nil) async throws -> DebriefResult {
        var request = URLRequest(url: APIConfig.debriefURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let isDoubles = input.matchFormat == .doubles || input.matchFormat == .mixed

        let body = DebriefRequest(
            result: input.result.rawValue,
            score: input.scoreDisplay,
            matchFormat: input.matchFormat.rawValue,
            biggestProblems: input.biggestProblems.isEmpty ? nil : input.biggestProblems.map(\.rawValue),
            matchPattern: input.matchPattern.rawValue,
            opponentLevel: input.opponentLevel.rawValue,
            context: buildContextString(from: input),
            whatWorked: input.allWhatWorked.isEmpty ? nil : input.allWhatWorked.map(\.rawValue).joined(separator: ", "),
            improvementAreas: input.improvementAreas?.map(\.rawValue),
            sport: input.sport.rawValue,
            scoringSystem: input.scoringSystem.rawValue,
            opponentNames: input.opponentNames.isEmpty ? nil : input.opponentNames,
            isDoubles: isDoubles,
            opponentHistory: opponentHistory,
            playerContext: playerProfile?.promptContext
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DebriefError.networkFailure
        }

        guard httpResponse.statusCode == 200 else {
            if let errorBody = try? JSONDecoder().decode(BackendError.self, from: data) {
                throw DebriefError.backendError(errorBody.detail)
            }
            throw DebriefError.networkFailure
        }

        let result = try JSONDecoder().decode(DebriefResponse.self, from: data)

        return DebriefResult(
            primaryIssue: result.primaryIssue,
            explanation: result.explanation,
            nextMatchAdjustment: result.nextMatchAdjustment,
            aiContext: AIContext(
                sport: input.sport,
                promptVersion: "opponent-insights-v1",
                generatedAt: Date(),
                model: "gpt-4o-mini"
            ),
            opponentInsights: result.opponentInsights
        )
    }

    // MARK: - Context Formatting

    private func buildContextString(from input: DebriefInput) -> String? {
        var parts: [String] = input.notableContexts.map(\.rawValue)

        if let note = input.contextNote, !note.isEmpty {
            parts.append(note)
        }

        return parts.isEmpty ? nil : parts.joined(separator: "; ")
    }
}

// MARK: - Request/Response DTOs

private struct DebriefRequest: Encodable {
    let result: String
    let score: String?
    let matchFormat: String
    let biggestProblems: [String]?
    let matchPattern: String
    let opponentLevel: String
    let context: String?
    let whatWorked: String?
    let improvementAreas: [String]?
    let sport: String
    let scoringSystem: String
    let opponentNames: [String]?
    let isDoubles: Bool
    let opponentHistory: String?
    let playerContext: String?
}

private struct DebriefResponse: Decodable {
    let primaryIssue: String
    let explanation: String
    let nextMatchAdjustment: String
    let opponentInsights: OpponentInsights?
}

private struct BackendError: Decodable {
    let detail: String
}

// MARK: - Errors

enum DebriefError: LocalizedError {
    case networkFailure
    case backendError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "Network error. Check your connection and try again."
        case .backendError(let detail):
            return detail
        case .invalidResponse:
            return "Couldn't parse the response. Try again."
        }
    }
}
