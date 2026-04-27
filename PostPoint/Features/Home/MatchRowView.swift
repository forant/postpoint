import SwiftUI

struct MatchRowView: View {
    let match: Match

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Sport icon
            Image(systemName: match.sport.icon)
                .font(.title3)
                .foregroundStyle(sportColor)
                .frame(width: 36, height: 36)
                .background(sportColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Opponent + result badge
                HStack {
                    Text(match.displayOpponentName)
                        .font(AppFont.headline())

                    Spacer()

                    if let summary = match.resultSummary {
                        Text(summary)
                            .font(AppFont.caption())
                            .foregroundStyle(resultColor)
                    } else {
                        Text(match.sport.rawValue)
                            .font(AppFont.caption())
                            .foregroundStyle(AppColors.secondaryLabel)
                    }
                }

                // Date
                Text(match.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.tertiaryLabel)

                // Debrief primary issue or notes preview
                if let issue = match.debriefResult?.primaryIssue {
                    Text(issue)
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColors.secondaryLabel)
                        .lineLimit(2)
                } else if !match.notes.isEmpty {
                    Text(match.notes)
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColors.secondaryLabel)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var sportColor: Color {
        switch match.sport {
        case .tennis: return AppColors.tennis
        case .pickleball: return AppColors.pickleball
        case .padel: return AppColors.padel
        }
    }

    private var resultColor: Color {
        guard let result = match.debriefInput?.result else { return AppColors.secondaryLabel }
        switch result {
        case .wonComfortably, .wonClose: return AppColors.tennis
        case .lostClose, .lostBadly: return .red
        }
    }
}
