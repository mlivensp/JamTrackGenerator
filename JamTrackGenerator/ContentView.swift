//
//  ContentView.swift
//  JamTrackGenerator
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // MARK: - Data
    @Query var keys: [Key]
    @Query var instruments: [Instrument]
    @Query var harmonicPatterns: [HarmonicPattern]
    @Query var drumPatterns: [DrumPattern]
    @Query var styles: [Style]
    @Query var feels: [Feel]

    // MARK: - UI State
    @State private var selectedCategory: SidebarCategory = .jamTracks
    @State private var contentWidth: CGFloat = 0

    // MARK: - Selection State (Owned here with @State)
    @State private var selectedJamTrack: JamTrack?
    @State private var selectedStyle: Style?
    @State private var selectedFeel: Feel?
    @State private var selectedDrumPatternNavigation: DrumPatternNavigation?
    @State private var selectedHarmonicPattern: HarmonicPattern?

    // MARK: - Navigation Path (iPhone)
    @State private var navPath = NavigationPath()

    // MARK: - Unsaved Changes Guard
    @State private var showUnsavedChangesAlert = false
    @State private var pendingCategory: SidebarCategory?

    var body: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            splitView
        } else {
            stackView
        }
#else
        splitView
#endif
    }

    // MARK: - Split View (iPad & macOS)
    private var splitView: some View {
        NavigationSplitView {
            // Sidebar
            List(SidebarCategory.allCases, selection: $selectedCategory) { category in
                Text(category.rawValue)
                    .tag(category)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { attemptCategoryChange(to: category) }
                    .foregroundColor(selectedCategory == category ? .accentColor : .primary)
                    .background(selectedCategory == category ? Color.accentColor.opacity(0.1) : .clear)
                    .padding(.vertical, 4)
            }
            .navigationTitle("Categories")
        } content: {
            // Content Pane
            CategoryContentView(
                category: selectedCategory,
                navPath: $navPath,
                selectedJamTrack: $selectedJamTrack,           // Pass as Binding
                selectedStyle: $selectedStyle,
                selectedFeel: $selectedFeel,
                selectedDrumPatternNavigation: $selectedDrumPatternNavigation,
                selectedHarmonicPattern: $selectedHarmonicPattern
            )
            .frame(width: contentWidth > 0 ? contentWidth : nil)
            .onPreferenceChange(ContentWidthPreferenceKey.self) { contentWidth = $0 }
        } detail: {
            // Detail Pane
            Group {
                switch selectedCategory {
                case .jamTracks:
                    if let jamTrack = selectedJamTrack {
                        JamTrackDetailView(jamTrack: jamTrack)
                    } else {
                        Text("Select a Jam Track")
                    }

                case .styles:
                    if let style = selectedStyle {
                        StyleEditView(style: style, navPath: $navPath)
                    } else {
                        Text("Select a Style")
                    }

                case .feels:
                    if let feel = selectedFeel {
                        FeelEditView(feel: feel)
                    } else {
                        Text("Select a Feel")
                    }

                case .drumPatterns:
                    if let navigation = selectedDrumPatternNavigation {
                        switch navigation {
                        case .existing(let drumPattern):
                            Text(drumPattern.name) // Replace with detail view
                        case .importOptions(let trackNotes):
                            PatternImportView(
                                trackNotes: trackNotes,
                                selectedDrumPatternNavigation: $selectedDrumPatternNavigation
                            )
                            .environment(\.modelContext, modelContext)
                        }
                    } else {
                        Text("Select a Drum Pattern")
                    }

                case .harmonicPatterns:
                    if let harmonicPattern = selectedHarmonicPattern {
                        Text(harmonicPattern.name)
                    } else {
                        Text("Select a Harmonic Pattern")
                    }
                }
            }
        }
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
        .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
            Button("Discard", role: .destructive) {
                if let jamTrack = selectedJamTrack {
                    let vm = JamTrackDetailView.ViewModel(jamTrack: jamTrack)
                    vm.reset()
                }
                if let pending = pendingCategory {
                    selectedCategory = pending
                    pendingCategory = nil
                }
            }
            Button("Keep Editing", role: .cancel) {
                pendingCategory = nil
            }
        } message: {
            Text("You have unsaved changes in the current Jam Track. Discard them or keep editing?")
        }
    }

    // MARK: - Stack View (iPhone)
    private var stackView: some View {
        NavigationStack(path: $navPath) {
            List {
                ForEach(SidebarCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        Text(category.rawValue)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationDestination(for: SidebarCategory.self) { category in
                CategoryContentView(
                    category: category,
                    navPath: $navPath,
                    selectedJamTrack: $selectedJamTrack,
                    selectedStyle: $selectedStyle,
                    selectedFeel: $selectedFeel,
                    selectedDrumPatternNavigation: $selectedDrumPatternNavigation,
                    selectedHarmonicPattern: $selectedHarmonicPattern
                )
            }
            .navigationDestination(for: JamTrack.self) { jamTrack in
                JamTrackDetailView(jamTrack: jamTrack)
            }
            .navigationDestination(for: Style.self) { style in
                StyleEditView(style: style, navPath: $navPath)
            }
            .navigationDestination(for: Feel.self) { feel in
                FeelEditView(feel: feel)
            }
        }
    }

    // MARK: - Category Change Guard
    private func attemptCategoryChange(to category: SidebarCategory) {
        guard selectedCategory == .jamTracks,
              let jamTrack = selectedJamTrack,
              category != .jamTracks else {
            selectedCategory = category
            return
        }

        let vm = JamTrackDetailView.ViewModel(jamTrack: jamTrack)
        if vm.hasUnsavedChanges {
            pendingCategory = category
            showUnsavedChangesAlert = true
        } else {
            selectedCategory = category
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(for: [
            JamTrack.self, DrumPattern.self, DrumNote.self,
            Style.self, Feel.self, JamTrackSection.self,
            Part.self, SectionPart.self, Key.self, Instrument.self
        ], inMemory: true)
}
