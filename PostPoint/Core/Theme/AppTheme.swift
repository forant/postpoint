import SwiftUI

// MARK: - Colors

enum AppColors {
    static let primary = Color("AccentColor")
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let tertiaryLabel = Color(.tertiaryLabel)

    // Sport-specific accent colors
    static let tennis = Color.green
    static let pickleball = Color.orange
    static let padel = Color.blue
}

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Typography

enum AppFont {
    static func title() -> Font { .title.bold() }
    static func headline() -> Font { .headline }
    static func subheadline() -> Font { .subheadline }
    static func body() -> Font { .body }
    static func caption() -> Font { .caption }
    static func largeTitle() -> Font { .largeTitle.bold() }
}
