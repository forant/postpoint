import SwiftUI

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var text = ""
    StyledTextField(placeholder: "Opponent name", text: $text)
        .padding()
}
