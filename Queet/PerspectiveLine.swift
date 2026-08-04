import SwiftUI

struct PerspectiveLine: View {
    let text: String
    let theme: QueetTheme
    var onTap: () -> Void = {}

    var body: some View {
        Text(text)
            .font(.system(.footnote, design: theme.fontDesign.design, weight: .medium))
            .foregroundStyle(theme.background.foreground.opacity(0.45))
            .multilineTextAlignment(.center)
            .contentTransition(.opacity)
            .onTapGesture(perform: onTap)
    }
}
