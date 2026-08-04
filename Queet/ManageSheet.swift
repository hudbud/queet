import SwiftUI
import SwiftData
import WidgetKit

struct ManageSheet: View {
    var onSelect: (Quit) -> Void = { _ in }

    @Query(sort: \Quit.sortOrder) private var quits: [Quit]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showNewQuit = false
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
                        Button("Restart") { confirmRestart = quit }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        Button(role: .destructive) { confirmDelete = quit } label: {
                            Image(systemName: "trash")
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(quit) }
                }
            }
            .navigationTitle("Your quits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewQuit = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showNewQuit) {
                QuitFormView(existingCount: quits.count, onCancel: { showNewQuit = false }) { quit in
                    context.insert(quit)
                    showNewQuit = false
                    WidgetCenter.shared.reloadAllTimelines()
                }
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
