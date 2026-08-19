# Queet — Polish Plan

A fine-tooth-comb pass over the whole app. Ordered by priority: P0 = visible bugs/overlap/jank, P1 = interaction feel, P2 = correctness & persistence, P3 = gaps vs. PLAN.md.

---

## P0 — Visible layout bugs & jank

### 1. Emoji picker row overflows the screen (NewQuitFlow.swift:28–38)
9 choices × (26pt emoji + 18pt padding) + 8 × 10pt spacing ≈ **476pt wide** inside a ~342pt content area on a standard iPhone. The row spills past both screen edges — this is the most likely "visuals overlap" you're seeing, since the create form is the first screen on a fresh install.
**Fix:** two-row `LazyVGrid` (or a horizontally scrolling row with edge fade). While there, make selection a spring-animated circle and add a haptic.

### 2. Hero number jumps vertically when the perspective line changes (MainView.swift:174–218)
The hero VStack (emoji + number + unit + perspective line) is centered as one block. When the perspective text wraps 1↔2 lines (tap to cycle, or quit swap), the whole block re-centers and the giant number visibly shifts. Same jump when a fresh quit has no perspective line at all.
**Fix:** anchor the *number* to screen center; give the perspective line a fixed-height slot (e.g. `.frame(height: 44, alignment: .top)`) below it, and position emoji/unit relative to the number, not as flexible stack content. The number should never move except during an intentional swap.

### 3. Manage sheet rows: buttons + row tap fight each other (ManageSheet.swift:19–39)
The trash `Button` has no explicit style — inside a `List` row it can fire on a whole-row tap, and the row's own `.onTapGesture` (select quit) competes with both buttons. Tapping a row to switch quits can pop the delete confirm.
**Fix:** row tap = select only. Move Restart/Delete to `.swipeActions` + a context menu. Also gives the rows breathing room.

### 4. Create-form keyboard jank (NewQuitFlow.swift)
The form is `Spacer()`-balanced, so when the keyboard appears the whole layout compresses and everything lurches. The decimal pad for cost has **no Done/dismiss** (no return key on decimal pads), so the keyboard gets stuck over the Start button.
**Fix:** wrap fields in a `ScrollView` with `.scrollDismissesKeyboard(.interactively)`, add a keyboard `.toolbar` Done button, and pin the Start button to the bottom outside the scroll area. Auto-focus the name field (`nameFocused = true` on appear — the `@FocusState` exists but is never set).

### 5. Sheets ignore the app theme (ManageSheet, PaywallSheet, ManageSheet→QuitFormView)
- `ManageSheet` is a system `List` — follows device light/dark, so on a light-mode phone a **white sheet slides over the black app**.
- `PaywallSheet` hardcodes true-black — wrong on Paper theme.
- The add-quit form opened *from ManageSheet* doesn't receive the theme (defaults to true black).
**Fix:** pass `theme` everywhere; at minimum force the color scheme to match the theme (`.preferredColorScheme(theme.background == .paper ? .light : .dark)`), style the List background to the theme color.

### 6. New quit doesn't become active — feels broken (MainView.swift:98–104)
Adding a quit via "+" inserts it but keeps the old quit centered; the only feedback is a corner node appearing with no animation. Users will think the save failed.
**Fix:** on save, set the new quit active with the spring animation (previous active drops to the corner slot), and animate the sheet dismissal → hero entrance as one sequence.

---

## P1 — Interaction feel

### 7. The hero swap animation doesn't actually fly (MainView.swift:159–181)
Both emoji `Text`s persist across the swap, so `matchedGeometryEffect` never gets an insertion/removal to match — the emojis just crossfade in place. The signature interaction from PLAN.md (corner quit expands to center) is currently a no-op.
**Fix:** give the hero and corner views identity tied to the quit (`.id(quit.id)`) so the swap inserts/removes views, with proper `isSource` pairing; keep the number's `.numericText` roll.

### 8. No haptics anywhere
PLAN.md: "Haptics on every cycle/swap." Zero `sensoryFeedback` in the codebase.
**Fix:** `.sensoryFeedback(.selection, …)` on unit cycle, currency cycle, perspective cycle, emoji pick; `.impact(.medium)` on quit swap, save, restart; `.success` on purchase.

### 9. Hero number is unformatted (MainView.swift:184)
`Text("\(value)")` — at seconds/minutes you get `4423680` with no grouping.
**Fix:** `value.formatted()` (respects locale grouping). Keep `monospacedDigit()` only for ticking units (seconds/minutes); use proportional figures for day-scale, per PLAN.md.

### 10. Tiny tap targets
Unit label, perspective line, and both corner nodes are footnote-size text with no padded hit area (well under 44pt).
**Fix:** `.contentShape(Rectangle())` with `.padding(8–12)` (inset visually, expanded hit box) on CornerNode, PerspectiveLine, and the unit label. Tapping the hero *number* should also cycle units (PLAN.md open-question default: biggest target does the most common thing).

### 11. Glass buttons: clip vs. shape (MainView.swift:221–229)
`.clipShape(Circle())` applied *outside* `.buttonStyle(.glass)` clips the glass highlight/shadow.
**Fix:** `.buttonBorderShape(.circle)` instead.

### 12. First-run save → content snap (MainView.swift:79–88)
Empty-state form → main content is `.opacity` on the form only; content pops in, potentially with the keyboard still up.
**Fix:** dismiss keyboard first, cross-fade + slight scale on the incoming hero, single spring.

### 13. Long-press discoverability & paywall collision
Background long-press (0.5s) and number long-press (0.4s) both jump straight to the paywall for non-pro users — a user idly pressing the screen gets a paywall with no context. Also nothing hints these gestures exist.
**Fix:** small glass "theme palette" popover on long-press showing swatches/fonts with lock badges on paid ones; paywall only when a locked item is chosen. One-time subtle hint after first quit is created.

---

## P2 — Correctness & persistence

### 14. Widget counts go stale for up to a day (QuitWidget.swift:21–36)
Timeline entries are `now + k days`, but the day count actually rolls over at the quit's start *time-of-day*. The widget can show yesterday's number for hours.
**Fix:** align entries to real unit boundaries: `startDate + n·unitLength` after now. Same for hours.

### 15. Home widget background mismatch (QuitWidget.swift:60–104)
`containerBackground { Color.black }` is hardcoded while the inner ZStack paints the theme color — on Paper theme you get a paper rectangle floating inside black widget margins.
**Fix:** put `theme.background.background` in `containerBackground` and drop the inner fill. Add quit name to `systemSmall` (currently unidentifiable) and `minimumScaleFactor` on the accessory-circular money text.

### 16. Money node shows "$0" forever when cost was skipped (MainView.swift:150–156)
Cost is optional in the form, but the top-left node still renders `$0`.
**Fix:** when `costPerDay == 0`, hide the node (or show best-streak instead); tapping it could offer "add a cost".

### 17. Display currency resets every launch (MainView.swift:16)
`displayCurrency` is `@State`; PLAN.md says app-group prefs (widgets need it too).
**Fix:** move to `@AppStorage(store: .queetGroup)`; use it in the widget money display.

### 18. Perspective line is stale / never appears for young quits (MainView.swift:236–245)
Generated only on appear/quit-change: the count in "That's 47 butterfly lifetimes" freezes, and a quit under ~3h old (no equivalence in range yet) never gets a line until relaunch.
**Fix:** recompute the *count* every timeline tick (keep the chosen equivalence stable, re-roll only on tap/quit-change); retry selection on tick while nil. Fixed-height slot from item #2 makes its appearance non-disruptive.

### 19. Restart doesn't restart the ticking baseline visibly
After Restart in the manage sheet the hero silently becomes 0 behind the sheet.
**Fix:** dismiss the sheet on restart and roll the number down with `.numericText` — the reset should feel deliberate and dignified (it's the emotional low-point of the app; don't make it feel like a glitch).

---

## P3 — Feature gaps vs. PLAN.md (smaller scope, still "polish" adjacent)

20. **No rename / edit-cost anywhere** — manage sheet only offers restart/delete. Add an edit screen (or inline) per quit: name, emoji, cost, start date.
21. **No corner-slot configuration** — long-press on corner nodes (money / another quit / best streak / units avoided / nothing) is unimplemented.
22. **Best streak** is stored (attempts) but surfaced nowhere.
23. **Accessibility** — hero has no VoiceOver label ("142 days since quitting drinking"), corner nodes/unit label unlabeled; Dynamic Type untested on the form and manage sheet.
24. **Custom emoji** — the 9 hardcoded choices can't cover real quits; allow any emoji via text field, or an expanded grid.

---

## Suggested sequencing

1. **Pass 1 (layout truth):** items 1, 2, 5, 15 — nothing overlaps, nothing shifts, everything matches the theme.
2. **Pass 2 (creation flow):** items 4, 6, 12, 24 — creating a quit feels smooth end-to-end.
3. **Pass 3 (touch feel):** items 3, 7, 8, 10, 11, 13, 19 — every touch is intentional, animated, haptic.
4. **Pass 4 (correctness):** items 9, 14, 16, 17, 18.
5. **Pass 5 (gaps):** items 20–23.

Each pass is independently shippable; verify on iPhone SE-size and Pro Max-size simulators, both light and dark system settings, with 1 quit and with 3+ quits, and with a quit created seconds ago vs. years ago.
