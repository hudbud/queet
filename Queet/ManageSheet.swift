import SwiftUI
import SwiftData
import WidgetKit

struct ManageSheet: View {
    var theme: QueetTheme = QueetTheme(fontDesign: .system, background: .trueBlack)
    var onSelect: (Quit) -> Void = { _ in }

    @Query(sort: \Quit.sortOrder) private var quits: [Quit]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showNewQuit = false
    @State private var editingQuit: Quit?
    @State private var confirmRestart: Quit?
    @State private var confirmDelete: Quit?

    var body: some View {
        NavigationStack {
            List {
                ForEach(quits) { quit in
                    HStack(spacing: 12) {
                        Text(quit.emoji).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(quit.name).font(.headline)
                            Text("Since \(quit.startDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(quit) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            confirmDelete = quit
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            confirmRestart = quit
                        } label: {
                            Label("Restart", systemImage: "arrow.counterclockwise")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingQuit = quit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background.background)
            .navigationTitle("Your quits")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.background == .paper ? .light : .dark)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewQuit = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showNewQuit) {
                QuitFormView(existingCount: quits.count, theme: theme, onCancel: { showNewQuit = false }) { quit in
                    context.insert(quit)
                    showNewQuit = false
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .sheet(item: $editingQuit) { quit in
                EditQuitSheet(quit: quit, theme: theme)
            }
            .confirmationDialog(
                "Restart this quit? Your current run will be saved as a past attempt.",
                isPresented: Binding(get: { confirmRestart != nil }, set: { if !$0 { confirmRestart = nil } }),
                titleVisibility: .visible
            ) {
                Button("Restart", role: .destructive) {
                    if let quit = confirmRestart {
                        quit.attempts.append(Attempt(startDate: quit.startDate, endDate: .now))
                        quit.startDate = .now
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                    confirmRestart = nil
                }
            }
            .confirmationDialog(
                "Delete this quit? This can't be undone.",
                isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let quit = confirmDelete { context.delete(quit) }
                    confirmDelete = nil
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
