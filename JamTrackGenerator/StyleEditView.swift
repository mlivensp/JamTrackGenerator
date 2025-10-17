import SwiftUI
import SwiftData

struct StyleEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var style: SchemaV1.Style
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section(header: Text("Style Info")) {
                TextField("Name", text: $style.name)
            }

            Section(header: Text("Drum Patterns")) {
                if style.drumPatterns.isEmpty {
                    Text("No drum patterns")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(style.drumPatterns) { pattern in
                        Text(pattern.name)
                    }
                }
            }

            Section(header: Text("Harmonic Patterns")) {
                if style.harmonicPatterns.isEmpty {
                    Text("No harmonic patterns")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(style.harmonicPatterns) { pattern in
                        Text(pattern.name)
                    }
                }
            }

            Section(header: Text("JamTrack Definitions")) {
                if style.definitions.isEmpty {
                    Text("No jam tracks")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(style.definitions) { track in
                        Text(track.name)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Style", systemImage: "trash")
                }
            }
        }
        .navigationTitle(style.name.isEmpty ? "New Style" : style.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Delete Style?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(style)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the style and all associated patterns and tracks.")
        }
    }
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: JamTrack.self, configurations: config)

    let style = Style(name: "Test Style")
    
    StyleEditView(style: style)
        .modelContainer(container)
}
