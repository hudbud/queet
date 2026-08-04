import WidgetKit
import SwiftUI

struct QuitAccessoryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuitTimelineEntry

    var body: some View {
        if let quit = entry.quit {
            let displayValue = entry.metric == .money
                ? Money.format(Money.saved(quit: quit, at: entry.date), currencyCode: quit.currencyCode)
                : Int(entry.unit.value(for: entry.date.timeIntervalSince(quit.startDate))).formatted()
            let displayLabel = entry.metric == .money ? quit.currencyCode : entry.unit.label
            switch family {
            case .accessoryCircular:
                VStack(spacing: 0) {
                    Text(displayValue).font(.system(.title3, design: .rounded, weight: .bold))
                    Text(displayLabel).font(.system(size: 9))
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(quit.emoji) \(quit.name)").font(.caption2)
                    Text("\(displayValue) \(displayLabel)").font(.system(.title3, design: .rounded, weight: .bold))
                }
            default:
                Text("\(quit.emoji) \(displayValue) \(displayLabel)")
            }
        } else {
            Text("Queet")
        }
    }
}

struct QuitAccessoryWidget: Widget {
    let kind = "QuitAccessoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectQuitIntent.self, provider: QuitWidgetProvider()) { entry in
            QuitAccessoryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Queet")
        .description("Your count on the lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
