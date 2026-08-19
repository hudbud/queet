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
        let unit = configuration.unit.timeUnit

        var entries: [QuitTimelineEntry] = []

        if unit == .hours {
            // For hours, start at the next hour boundary
            let nextHour = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime) ?? now
            for offset in 0..<24 {
                if let date = calendar.date(byAdding: .hour, value: offset, to: nextHour) {
                    entries.append(QuitTimelineEntry(date: date, quit: quit, metric: configuration.metric, unit: unit))
                }
            }
        } else {
            // For days/weeks/months/years, align to the quit's start time
            if let quit = quit {
                let startComponents = calendar.dateComponents([.hour, .minute, .second], from: quit.startDate)
                let nextBoundary = calendar.nextDate(after: now, matching: startComponents, matchingPolicy: .nextTime) ?? now
                for offset in 0..<30 {
                    if let date = calendar.date(byAdding: .day, value: offset, to: nextBoundary) {
                        entries.append(QuitTimelineEntry(date: date, quit: quit, metric: configuration.metric, unit: unit))
                    }
                }
            } else {
                // Fallback if no quit
                for offset in 0..<30 {
                    if let date = calendar.date(byAdding: .day, value: offset, to: now) {
                        entries.append(QuitTimelineEntry(date: date, quit: quit, metric: configuration.metric, unit: unit))
                    }
                }
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
        if let quit = entry.quit {
            VStack(spacing: 2) {
                if family == .systemSmall {
                    Text(quit.name)
                        .font(.system(.caption2, design: theme.fontDesign.design, weight: .semibold))
                        .foregroundStyle(theme.background.foreground.opacity(0.6))
                        .lineLimit(1)
                        .padding(.bottom, 1)
                }
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
                        .padding(.top, 2)
                }
            }
        } else {
            Text("Add a quit in Queet")
                .font(.caption)
                .foregroundStyle(theme.background.foreground.opacity(0.6))
        }
    }
}

struct QuitWidget: Widget {
    let kind = "QuitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectQuitIntent.self, provider: QuitWidgetProvider()) { entry in
            QuitWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    currentTheme().background.background
                }
        }
        .configurationDisplayName("Queet")
        .description("Track a quit at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
