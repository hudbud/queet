import SwiftUI
import StoreKit

struct PaywallSheet: View {
    var store: Store
    @Environment(\.dismiss) private var dismiss

    private let theme = QueetTheme(fontDesign: .system, background: .trueBlack)

    var body: some View {
        ZStack {
            theme.background.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("🎨")
                    .font(.system(size: 56))

                Text("Custom Themes")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Unlock every font and background — Rounded, Serif, Mono, Ink, Oxblood, Forest, Paper, and more. Long-press the number or background to cycle once unlocked.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                Spacer()

                if store.isProUnlocked {
                    Label("Unlocked", systemImage: "checkmark.circle.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.green)
                        .padding(.vertical, 16)
                } else {
                    Button {
                        Task {
                            await store.purchaseThemes()
                            if store.isProUnlocked { dismiss() }
                        }
                    } label: {
                        HStack {
                            Text("Unlock")
                            if let product = store.themesProduct {
                                Text("· \(product.displayPrice)")
                                    .opacity(0.7)
                            }
                        }
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(store.themesProduct == nil || store.isLoading)
                    .padding(.horizontal, 40)

                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                }

                Button("Not now") { dismiss() }
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
