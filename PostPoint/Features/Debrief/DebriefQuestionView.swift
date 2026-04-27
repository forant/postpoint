import SwiftUI

struct DebriefQuestionView<Option: Hashable & Identifiable>: View where Option: RawRepresentable<String> {
    let prompt: String
    let options: [Option]
    let iconForOption: (Option) -> String
    let selection: Set<Option>
    let multiSelect: Bool
    let maxSelections: Int
    let onSelect: (Option) -> Void

    init(
        prompt: String,
        options: [Option],
        icon: @escaping (Option) -> String,
        selection: Set<Option>,
        multiSelect: Bool = false,
        maxSelections: Int = 1,
        onSelect: @escaping (Option) -> Void
    ) {
        self.prompt = prompt
        self.options = options
        self.iconForOption = icon
        self.selection = selection
        self.multiSelect = multiSelect
        self.maxSelections = maxSelections
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(prompt)
                .font(AppFont.largeTitle())
                .fixedSize(horizontal: false, vertical: true)

            if multiSelect {
                Text("Select up to \(maxSelections)")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.secondaryLabel)
            }

            VStack(spacing: AppSpacing.sm) {
                ForEach(options) { option in
                    DebriefOptionCard(
                        title: option.rawValue,
                        icon: iconForOption(option),
                        isSelected: selection.contains(option)
                    ) {
                        onSelect(option)
                    }
                }
            }
        }
    }
}
