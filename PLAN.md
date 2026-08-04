# Queet — Implementation Plan

A hyper-minimal iOS app for quitting things. One giant number in the middle of the screen. No gamification, no streak-shaming, no badges. Everything on screen is touchable and cycles/configures through direct manipulation — ideally zero settings screens.

## Product spec

### Main screen

```
┌─────────────────────────────┐
│ $1,284              🍺 12   │   ← corner nodes (small text)
│                             │
│                             │
│           142               │   ← giant number (the count)
│           days              │   ← unit label
│                             │
│   That's 47 butterfly       │   ← perspective line
│       lifetimes             │
│                             │
│                             │
│  (+)                 (≡)    │   ← glass action buttons
└─────────────────────────────┘
```

- **Center**: huge typography, count since quit date. Default unit: days.
- **Unit label** ("days"): tapping cycles units → days → hours → minutes → seconds → weeks → months → years → back. Seconds/minutes tick live.
- **Top-left node**: money saved (default). Tap cycles display currency.
- **Top-right node**: customizable; default shows *another* quit (icon/emoji + its count). Tapping it swaps that quit into the center with a matched-geometry animation (the center quit flies to the corner, corner quit expands to center).
- **Perspective line**: below the number+label, e.g. "That's 47 butterfly lifetimes" / "That's 4.2 trips around the moon". Tap to cycle to another equivalence.
- **Bottom-left / bottom-right**: floating glass action buttons (iOS 26 Liquid Glass, `.glassEffect()` / `GlassButtonStyle`). Bottom-left: add a new quit. Bottom-right: quit list / manage (rename, edit cost, reset, delete).
- Long-press any corner node → small glass menu to choose what that slot shows (money, another quit, best streak, units avoided, nothing).

### Interaction philosophy

Everything visible is a control. Tap = cycle, long-press = configure. No chrome, no nav bars, no tab bars. Haptics (light `.sensoryFeedback`) on every cycle/swap.

### Reset / relapse

Keep it dignified and minimal: in the manage sheet, a "restart" action (with confirm). Restart archives the attempt (for "best streak" stat) and sets a new start date. No guilt UI.

### Widgets (big part of the concept)

WidgetKit extension with:
- **Lock screen**: `accessoryCircular` (just the number), `accessoryRectangular` (number + unit + name), `accessoryInline` (e.g. "Queet · 142 days").
- **Home screen**: `systemSmall` — giant number + unit + quit name, optional money line. `systemMedium` — two quits side by side.
- Widget configuration (`AppIntent`-based) picks which quit and which metric (time vs. money).
- Timelines: for days/money, one entry per day boundary is enough. For hour display, hourly entries. (Live seconds aren't feasible in widgets; don't offer seconds there.)

## Architecture

- **Targets**: `Queet` (app) + `QueetWidgets` (widget extension). Shared code in a local Swift package or shared target-membership folder `Shared/`.
- **Min target**: iOS 26 (needed for Liquid Glass; no fallbacks).
- **Persistence**: SwiftData, `ModelContainer` in an App Group container (`group.<bundle-id-prefix>.queet`) so widgets read the same store. Reload widget timelines (`WidgetCenter.shared.reloadAllTimelines()`) on any model change.
- **No backend.** Optional later: iCloud sync via SwiftData + CloudKit.

### Data model

```swift
@Model final class Quit {
    var name: String            // "Drinking"
    var emoji: String           // "🍺"
    var startDate: Date
    var costPerDay: Decimal     // user enters cost/day (or cost/unit × units/day at creation)
    var currencyCode: String    // what they entered cost in, e.g. "USD"
    var sortOrder: Int
    var attempts: [Attempt]     // archived previous runs, for best-streak
}

@Model final class Attempt {
    var startDate: Date
    var endDate: Date
}
```

App-level prefs (small, `UserDefaults` in the app group — widgets need them too):
- `activeQuitID`, per-quit selected time unit, display currency, corner slot assignments, last-chosen perspective category.

### Key implementation notes

- **Live ticking**: `TimelineView(.periodic(from:by:))` drives the center number; period depends on selected unit (1s for seconds, 60s for minutes, ~1h otherwise). Count = `Date.now.timeIntervalSince(startDate)` converted per unit — never an incrementing counter.
- **Swap animation**: `@Namespace` + `matchedGeometryEffect` on the quit's number/emoji between corner node and center. Spring animation, one shared namespace on the main screen.
- **Unit cycling**: `ContentTransition.numericText()` on the big number for the roll effect when unit or value changes.
- **Money**: `savings = daysElapsed × costPerDay`. Display formatting via `Decimal.FormatStyle.Currency`. Currency *cycling* needs FX rates: ship a bundled static rate table (approximate is fine for this purpose, note "≈" in UI), optionally refresh from frankfurter.app when online and cache. Don't block MVP on live rates.
- **Perspective engine**: pure function `(TimeInterval) -> [Equivalence]`. Static table of equivalences with valid ranges so lines stay sensible, e.g.:
  - mayfly lifetimes (1 day), butterfly lifetimes (~3 days? use ~2 weeks for monarch — pick one, cite in comment), full moons (29.5 d), ISS orbits (92 min), heartbeats (~100k/day), breaths (~20k/day), Mercury years (88 d), seasons, Everest climbs (avg 40 d expedition)…
  - Pick the equivalence whose count lands in a satisfying range (roughly 2–10,000). Format with `formatted(.number)`.
- **Onboarding**: if no quits exist, the main screen *is* the creation flow — inline "What are you quitting?" → name/emoji → "When did you stop?" (date picker, default now) → "What did it cost per day?" (optional). No separate onboarding screens.
## Typography & appearance

Typography is the product. The number is the interface — it has to be gorgeous before anything else ships. Treat the hero numeral like a poster, not a label.

**Default look**: pure black background (`#000000`, true black — OLED-flush, no elevation grays) with pure white type. No cards, no dividers, no chrome. The corner nodes and perspective line at reduced opacity (~0.45–0.6) so the hierarchy is carried entirely by scale and weight.

**Hero numeral craft**:
- SF Pro at display optical size (automatic with system font at large sizes), heavy/black weight.
- Negative tracking at hero sizes — large numerals need tightening; tune by eye with `.tracking()`, roughly −2…−4% of point size.
- `monospacedDigit()` so live ticking doesn't jitter. Note the tradeoff: tabular figures look boxier; consider proportional figures for day-scale units (no ticking) and tabular only for seconds/minutes.
- Size-to-fit the screen width: measure with `ViewThatFits`/`minimumScaleFactor`, but the number should feel like it *fills* the screen — err enormous. 4+ digit counts scale down gracefully.
- Baseline-align the unit label to the numeral; label in the same family at small size, wide tracking (+5–8%), lowercase.
- `contentTransition(.numericText())` for value/unit rolls; keep animation curves soft (spring, no bounce).

**Customization** (fits the direct-manipulation philosophy — no settings screen):
- **Font**: cycle through the four system designs free of licensing — `.fontDesign(.default)` (SF Pro), `.rounded` (SF Rounded), `.serif` (New York), `.monospaced` (SF Mono). Each gets hand-tuned tracking/weight presets — don't just swap the design and keep SF Pro's metrics. Long-press the hero number → small glass palette to pick. Bundled third-party fonts are a later option (licensing).
- **Background**: default true black; offer a small curated set — true black, near-black warm/cool, deep pigment colors (ink blue, oxblood, forest), paper white with black type. Curated, not a color wheel — every combo must be one we'd ship. Long-press the background → palette.
- Theme is global (not per-quit) for v1; stored in app-group prefs so widgets match the app.
- Widgets inherit the theme where WidgetKit allows (home screen: yes; lock screen accessories are system-rendered, accept that).

## File structure

```
Queet/
  QueetApp.swift
  MainView.swift            // the one screen: center + corners + glass buttons
  CornerNode.swift
  PerspectiveLine.swift
  ManageSheet.swift         // list, edit, restart, delete
  NewQuitFlow.swift
Shared/
  Models.swift              // Quit, Attempt, ModelContainer factory (app group)
  Prefs.swift               // app-group UserDefaults wrapper
  TimeUnit.swift            // unit enum + conversion + cycling order
  Money.swift               // savings calc, currency cycling, bundled rates
  Perspective.swift         // equivalence table + picker
QueetWidgets/
  QueetWidgets.swift        // bundle
  QuitWidget.swift          // home screen small/medium
  QuitAccessoryWidget.swift // lock screen circular/rect/inline
  SelectQuitIntent.swift    // AppIntent configuration
```

## Milestones

1. **M1 — Core**: Xcode project (app + widget targets, app group), SwiftData model, main screen with one quit: giant count, unit cycling with live tick, inline creation flow. Includes the default typographic pass (true black, tuned hero numeral) — the type quality bar is set here, not bolted on later.
2. **M2 — Multi-quit**: corner nodes, top-right quit swap with matched geometry, manage sheet (add/edit/restart/delete), glass action buttons.
3. **M3 — Delight**: money saved + currency cycling, perspective line + engine, haptics, number roll transitions.
4. **M4 — Widgets**: lock screen accessories + home screen widgets, AppIntent config, timeline reload wiring.
5. **M5 — Polish**: theme customization (font design + background palettes via long-press), long-press slot configuration, app icon, empty/edge states (quit deleted while in a corner slot, future start dates), accessibility (Dynamic Type on everything except the hero number, VoiceOver labels like "142 days since quitting drinking").

## Open questions (safe defaults chosen, revisit later)

- Best streak vs. current streak display — default: current only; best streak available as a corner-slot option.
- iCloud sync — skip for v1.
- Should tapping the center number itself do anything? Default: same as tapping the unit label (cycle units) — biggest touch target should do the most common thing.
