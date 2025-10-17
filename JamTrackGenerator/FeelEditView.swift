import SwiftUI
import SwiftData

struct FeelEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var feel: SchemaV1.Feel
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section(header: Text("Feel Info")) {
                TextField("Name", text: $feel.name)
            }

            Section(header: Text("Drum Patterns")) {
                if feel.drumPatterns.isEmpty {
                    Text("No drum patterns")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(feel.drumPatterns) { pattern in
                        Text(pattern.name)
                    }
                }
            }

            Section(header: Text("Harmonic Patterns")) {
                if feel.harmonicPatterns.isEmpty {
                    Text("No harmonic patterns")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(feel.harmonicPatterns) { pattern in
                        Text(pattern.name)
                    }
                }
            }

            Section(header: Text("JamTrack Definitions")) {
                if feel.definitions.isEmpty {
                    Text("No jam tracks")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(feel.definitions) { track in
                        Text(track.name)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Feel", systemImage: "trash")
                }
            }
        }
        .navigationTitle(feel.name.isEmpty ? "New Feel" : feel.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Delete Feel?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(feel)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the feel and unlink associated patterns and tracks.")
        }
    }
}
