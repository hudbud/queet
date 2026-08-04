import SwiftUI

struct CornerNode: View {
    let text: String
    let theme: QueetTheme
    var action: (() -> Void)? = nil

    var body: some View {
        Text(text)
            .font(.system(.footnote, design: theme.fontDesign.design, weight: .semibold))
            .tracking(theme.fontDesign.labelTracking)
            .foregroundStyle(theme.background.foreground.opacity(0.55))
            .contentTransition(.numericText())
            .onTapGesture { action?() }
    }
}
