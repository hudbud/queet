import SwiftUI
import SwiftData
import WidgetKit

struct MainView: View {
    @Query(sort: \Quit.sortOrder) private var quits: [Quit]
    @Environment(\.modelContext) private var context

    @AppStorage("backgroundTheme", store: .queetGroup) private var background: BackgroundTheme = .trueBlack
    @AppStorage("fontDesign", store: .queetGroup) private var fontDesign: QueetFontDesign = .system
    @AppStorage("activeQuitIDString", store: .queetGroup) private var activeQuitIDString: String = ""
    @AppStorage("topRightQuitIDString", store: .queetGroup) private var topRightQuitIDString: String = ""

    @Namespace private var heroNS
    @State private var unit: QueetTimeUnit = .days
    @State private var displayCurrency: String = Locale.current.currency?.identifier ?? "USD"
    @State private var showAddQuit = false
    @State private var showManage = false
    @State private var showPaywall = false
    @State private var perspective: (text: String, index: Int)?
    @State private var store = Store()

    private var theme: QueetTheme { QueetTheme(fontDesign: fontDesign, background: background) }

    private var activeQuit: Quit? {
        if let id = UUID(uuidString: activeQuitIDString), let match = quits.first(where: { $0.id == id }) {
            return match
        }
        return quits.first
    }

    /// The quit pinned to the top-right slot. Falls back to the next quit after
    /// the active one (wrapping) so it's always populated when there's more than one track.
    private var topRightQuit: Quit? {
        if let id = UUID(uuidString: topRightQuitIDString),
           let match = quits.first(where: { $0.id == id }),
           match.id != activeQuit?.id {
            return match
        }
        return nextQuit(after: activeQuit)
    }

    private func nextQuit(after quit: Quit?) -> Quit? {
        guard let quit, let idx = quits.firstIndex(where: { $0.id == quit.id }), quits.count > 1 else {
            return quits.first(where: { $0.id != quit?.id })
        }
        for offset in 1..<quits.count {
            let candidate = quits[(idx + offset) % quits.count]
            if candidate.id != quit.id { return candidate }
        }
        return nil
    }

    /// Swaps a quit into the hero position; whatever was active becomes the new top-right pin.
    private func setActive(_ quit: Quit) {
        guard quit.id != activeQuit?.id else { return }
        let previousActive = activeQuit
        withAnimation(.spring(duration: 0.55, bounce: 0.22)) {
            activeQuitIDString = quit.id.uuidString
            if let previousActive {
                topRightQuitIDString = previousActive.id.uuidString
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some View {
        ZStack {
            theme.background.background
                .ignoresSafeArea()
                .onLongPressGesture(minimumDuration: 0.5) {
                    if store.isProUnlocked {
                        withAnimation(.easeInOut) { background = background.next }
                    } else {
                        showPaywall = true
                    }
                }

            if quits.isEmpty {
                QuitFormView(existingCount: 0, theme: theme) { quit in
                    withAnimation { context.insert(quit) }
                    activeQuitIDString = quit.id.uuidString
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .transition(.opacity)
            } else {
                content
            }
        }
        .onAppear {
            syncUnit()
            regeneratePerspective()
        }
        .onChange(of: activeQuit?.id) { _, _ in
            syncUnit()
            regeneratePerspective()
        }
        .sheet(isPresented: $showAddQuit) {
            QuitFormView(existingCount: quits.count, theme: theme, onCancel: { showAddQuit = false }) { quit in
                context.insert(quit)
                showAddQuit = false
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .sheet(isPresented: $showManage) {
            ManageSheet(onSelect: { quit in
                setActive(quit)
                showManage = false
            })
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(store: store)
        }
    }

    @ViewBuilder
    private var content: some View {
        TimelineView(.periodic(from: .now, by: unit.refreshInterval)) { timelineContext in
            ZStack {
                VStack {
                    HStack(alignment: .top) {
                        topLeftNode
                        Spacer()
                        if let pinned = topRightQuit {
                            topRightNode(pinned, date: timelineContext.date)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                heroStack(date: timelineContext.date)

                VStack {
                    Spacer()
                    HStack {
                        glassButton(systemImage: "plus") { showAddQuit = true }
                        Spacer()
                        glassButton(systemImage: "line.3.horizontal") { showManage = true }
                    }
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private var topLeftNode: some View {
        if let quit = activeQuit {
            CornerNode(text: Money.format(Money.convert(Money.saved(quit: quit), from: quit.currencyCode, to: displayCurrency), currencyCode: displayCurrency), theme: theme) {
                withAnimation(.snappy) { displayCurrency = Money.next(after: displayCurrency) }
            }
        }
    }

    @ViewBuilder
    private func topRightNode(_ quit: Quit, date: Date) -> some View {
        let days = Int(QueetTimeUnit.days.value(for: date.timeIntervalSince(quit.startDate)))
        HStack(spacing: 6) {
            Text(quit.emoji)
                .font(.system(size: 18))
                .matchedGeometryEffect(id: quit.id, in: heroNS)
            Text("\(days)d")
                .font(.system(.footnote, design: theme.fontDesign.design, weight: .semibold))
                .foregroundStyle(theme.background.foreground.opacity(0.55))
                .contentTransition(.numericText())
        }
        .onTapGesture { setActive(quit) }
    }

    @ViewBuilder
    private func heroStack(date: Date) -> some View {
        if let quit = activeQuit {
            let value = Int(unit.value(for: date.timeIntervalSince(quit.startDate)))
            VStack(spacing: 4) {
                Text(quit.emoji)
                    .font(.system(size: 22))
                    .opacity(0.85)
                    .matchedGeometryEffect(id: quit.id, in: heroNS)
                    .padding(.bottom, 4)

                Text("\(value)")
                    .font(.system(size: 120, weight: theme.fontDesign.heroWeight, design: theme.fontDesign.design))
                    .tracking(theme.fontDesign.heroTracking)
                    .monospacedDigit()
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .foregroundStyle(theme.background.foreground)
                    .contentTransition(.numericText(value: Double(value)))
                    .onLongPressGesture(minimumDuration: 0.4) {
                        if store.isProUnlocked {
                            withAnimation(.easeInOut) { fontDesign = fontDesign.next }
                        } else {
                            showPaywall = true
                        }
                    }

                Text(unit.label)
                    .font(.system(.subheadline, design: theme.fontDesign.design, weight: .semibold))
                    .tracking(theme.fontDesign.labelTracking)
                    .foregroundStyle(theme.background.foreground.opacity(0.55))
                    .textCase(.lowercase)
                    .onTapGesture {
                        withAnimation(.snappy) { unit = unit.next }
                        PerQuitUnitStore.setUnit(unit, for: quit.id)
                    }

                if let perspective {
                    PerspectiveLine(text: perspective.text, theme: theme) {
                        withAnimation(.easeInOut) { regeneratePerspective() }
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 40)
                }
            }
        }
    }

    private func glassButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.glass)
        .clipShape(Circle())
    }

    private func syncUnit() {
        guard let quit = activeQuit else { return }
        unit = PerQuitUnitStore.unit(for: quit.id)
    }

    private func regeneratePerspective() {
        guard let quit = activeQuit else {
            perspective = nil
            return
        }
        let interval = Date.now.timeIntervalSince(quit.startDate)
        if let result = Perspective.line(for: interval, excluding: perspective?.index) {
            perspective = result
        }
    }
}
