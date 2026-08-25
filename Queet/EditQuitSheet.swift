import SwiftUI

struct EditQuitSheet: View {
    @Bindable var quit: Quit
    var theme: QueetTheme
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var costText: String
    @State private var startDate: Date
    @FocusState private var nameFocused: Bool

    private static let emojiChoices = ["🚭", "🍺", "🍷", "☕️", "🍬", "📱", "🎰", "💊", "🍔"]

    init(quit: Quit, theme: QueetTheme) {
        self.quit = quit
        self.theme = theme
        _name = State(initialValue: quit.name)
        _emoji = State(initialValue: quit.emoji)
        _costText = State(initialValue: quit.costPerDay > 0 ? "\(quit.costPerDay)" : "")
        _startDate = State(initialValue: quit.startDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 26) {
                        Spacer().frame(height: 20)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 10)], spacing: 10) {
                            ForEach(Self.emojiChoices, id: \.self) { choice in
                                Text(choice)
                                    .font(.system(size: 26))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(theme.background.foreground.opacity(choice == emoji ? 0.18 : 0))
                                            .scaleEffect(choice == emoji ? 1.0 : 0.9)
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(duration: 0.25, bounce: 0.4)) {
                                            emoji = choice
                                        }
                                    }
                                    .sensoryFeedback(.selection, trigger: emoji)
                            }
                        }

                        TextField("", text: $name, prompt: Text("Name").foregroundStyle(theme.background.foreground.opacity(0.35)))
                            .multilineTextAlignment(.center)
                            .font(.system(.title, design: theme.fontDesign.design, weight: .semibold))
                            .foregroundStyle(theme.background.foreground)
                            .focused($nameFocused)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 32)

                        VStack(spacing: 8) {
                            Text("Start date")
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
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            nameFocused = false
                                        }
                                    }
                                }
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.background == .paper ? .light : .dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        quit.name = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : name
                        quit.emoji = emoji
                        quit.startDate = startDate
                        quit.costPerDay = Decimal(string: costText) ?? 0
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
