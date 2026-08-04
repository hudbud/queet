import WidgetKit
import SwiftUI
import SwiftData

struct QuitTimelineEntry: TimelineEntry {
    let date: Date
    let quit: Quit?
    let metric: WidgetMetric
    let unit: QueetTimeUnit
}

struct QuitWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> QuitTimelineEntry {
        QuitTimelineEntry(date: .now, quit: nil, metric: .time, unit: .days)
    }

    func snapshot(for configuration: SelectQuitIntent, in context: Context) async -> QuitTimelineEntry {
        QuitTimelineEntry(date: .now, quit: resolveQuit(configuration), metric: configuration.metric, unit: configuration.unit.timeUnit)
    }

    func timeline(for configuration: SelectQuitIntent, in context: Context) async -> Timeline<QuitTimelineEntry> {
        let quit = resolveQuit(configuration)
        let now = Date.now
        let calendar = Calendar.current
        let isHourly = configuration.unit.timeUnit == .hours
        let count = isHourly ? 24 : 30
        let step: Calendar.Component = isHourly ? .hour : .day

        var entries: [QuitTimelineEntry] = []
        for offset in 0..<count {
            if let date = calendar.date(byAdding: step, value: offset, to: now) {
                entries.append(QuitTimelineEntry(date: date, quit: quit, metric: configuration.metric, unit: configuration.unit.timeUnit))
            }
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func resolveQuit(_ configuration: SelectQuitIntent) -> Quit? {
        let context = ModelContext(ModelContainerFactory.make())
        if let id = configuration.quit?.id {
            return try? context.fetch(FetchDescriptor<Quit>(predicate: #Predicate { $0.id == id })).first
        }
        return try? context.fetch(FetchDescriptor<Quit>(sortBy: [SortDescriptor(\.sortOrder)])).first
    }
}

private func currentTheme() -> QueetTheme {
    let defaults = UserDefaults.queetGroup
    let font = defaults.string(forKey: "fontDesign").flatMap(QueetFontDesign.init) ?? .system
    let bg = defaults.string(forKey: "backgroundTheme").flatMap(BackgroundTheme.init) ?? .trueBlack
    return QueetTheme(fontDesign: font, background: bg)
}

struct QuitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuitTimelineEntry

    var body: some View {
        let theme = currentTheme()
        ZStack {
            theme.background.background
            if let quit = entry.quit {
                VStack(spacing: 2) {
                    Text(quit.emoji).font(.title3)
                    Group {
                        if entry.metric == .money {
                            Text(Money.format(Money.saved(quit: quit, at: entry.date), currencyCode: quit.currencyCode))
                        } else {
                            Text(Int(entry.unit.value(for: entry.date.timeIntervalSince(quit.startDate))).formatted())
                        }
                    }
                    .font(.system(size: 34, weight: .heavy, design: theme.fontDesign.design))
                    .foregroundStyle(theme.background.foreground)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                    Text(entry.metric == .money ? quit.currencyCode : entry.unit.label)
                        .font(.system(.caption2, design: theme.fontDesign.design, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(theme.background.foreground.opacity(0.55))

                    if family == .systemMedium {
                        Text(quit.name)
                            .font(.system(.footnote, design: theme.fontDesign.design))
                            .foregroundStyle(theme.background.foreground.opacity(0.7))
                    }
                }
            } else {
                Text("Add a quit in Queet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

struct QuitWidget: Widget {
    let kind = "QuitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectQuitIntent.self, provider: QuitWidgetProvider()) { entry in
            QuitWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("Queet")
        .description("Track a quit at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
