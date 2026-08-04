import SwiftUI

struct QuitFormView: View {
    let existingCount: Int
    var theme: QueetTheme = QueetTheme(fontDesign: .system, background: .trueBlack)
    var onCancel: (() -> Void)? = nil
    var onSave: (Quit) -> Void

    @State private var name = ""
    @State private var emoji = "🚭"
    @State private var startDate = Date.now
    @State private var costText = ""
    @FocusState private var nameFocused: Bool

    private static let emojiChoices = ["🚭", "🍺", "🍷", "☕️", "🍬", "📱", "🎰", "💊", "🍔"]

    var body: some View {
        ZStack {
            theme.background.background.ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                Text(existingCount == 0 ? "What are you quitting?" : "Add another")
                    .font(.system(.title2, design: theme.fontDesign.design, weight: .bold))
                    .foregroundStyle(theme.background.foreground)

                HStack(spacing: 10) {
                    ForEach(Self.emojiChoices, id: \.self) { choice in
                        Text(choice)
                            .font(.system(size: 26))
                            .padding(9)
                            .background(
                                Circle().fill(theme.background.foreground.opacity(choice == emoji ? 0.18 : 0))
                            )
                            .onTapGesture { emoji = choice }
                    }
                }

                TextField("", text: $name, prompt: Text("Name it").foregroundStyle(theme.background.foreground.opacity(0.35)))
                    .multilineTextAlignment(.center)
                    .font(.system(.title, design: theme.fontDesign.design, weight: .semibold))
                    .foregroundStyle(theme.background.foreground)
                    .focused($nameFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 32)

                VStack(spacing: 8) {
                    Text("Since when?")
                        .font(.system(.caption, design: theme.fontDesign.design, weight: .semibold))
                        .foregroundStyle(theme.background.foreground.opacity(0.5))
                    DatePicker("", selection: $startDate, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .colorScheme(theme.background == .paper ? .light : .dark)
                }

                VStack(spacing: 8) {
                    Text("Cost per day (optional)")
                        .font(.system(.caption, design: theme.fontDesign.design, weight: .semibold))
                        .foregroundStyle(theme.background.foreground.opacity(0.5))
                    TextField("", text: $costText, prompt: Text("0").foregroundStyle(theme.background.foreground.opacity(0.35)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(.title3, design: theme.fontDesign.design))
                        .foregroundStyle(theme.background.foreground)
                        .frame(width: 120)
                }

                Spacer()

                Button {
                    let quit = Quit(
                        name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : name,
                        emoji: emoji,
                        startDate: startDate,
                        costPerDay: Decimal(string: costText) ?? 0,
                        sortOrder: existingCount
                    )
                    onSave(quit)
                } label: {
                    Text(existingCount == 0 ? "Start" : "Add")
                        .font(.system(.headline, design: theme.fontDesign.design, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .padding(.horizontal, 40)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                if let onCancel {
                    Button("Cancel", action: onCancel)
                        .font(.system(.footnote, design: theme.fontDesign.design))
                        .foregroundStyle(theme.background.foreground.opacity(0.5))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
