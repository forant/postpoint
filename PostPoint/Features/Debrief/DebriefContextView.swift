import SwiftUI

struct DebriefContextView: View {
    @Binding var selectedContexts: Set<NotableContext>
    @Binding var contextNote: String
    @FocusState private var noteFieldFocused: Bool

    private let maxSelections = 2

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Anything that affected your play?")
                .font(AppFont.largeTitle())
                .fixedSize(horizontal: false, vertical: true)

            Text("Optional \u{2014} add context so your debrief is smarter.")
                .font(AppFont.caption())
                .foregroundStyle(AppColors.secondaryLabel)

            // Pills
            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(NotableContext.allCases) { context in
                    ContextPill(
                        context: context,
                        isSelected: selectedContexts.contains(context)
                    ) {
                        toggleContext(context)
                    }
                }
            }

            // Free-text note
            TextField("e.g. I was working on serve and volley, but it wasn't clicking", text: $contextNote, axis: .vertical)
                .font(AppFont.body())
                .lineLimit(2...4)
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($noteFieldFocused)
        }
    }

    private func toggleContext(_ context: NotableContext) {
        noteFieldFocused = false
        if selectedContexts.contains(context) {
            selectedContexts.remove(context)
        } else if selectedContexts.count < maxSelections {
            selectedContexts.insert(context)
        }
    }
}

// MARK: - Context Pill

private struct ContextPill: View {
    let context: NotableContext
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: context.icon)
                    .font(.caption)
                Text(context.rawValue)
                    .font(AppFont.subheadline())
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? AppColors.primary.opacity(0.15) : AppColors.secondaryBackground)
            .foregroundStyle(isSelected ? AppColors.primary : AppColors.label)
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if index < rows.count - 1 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += size.width + spacing
        }
        return rows
    }
}

#Preview {
    @Previewable @State var contexts: Set<NotableContext> = [.fatigued]
    @Previewable @State var note = ""
    DebriefContextView(selectedContexts: $contexts, contextNote: $note)
        .padding()
}
