//
//  DrumPatternEditView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 11/13/25.
//

import SwiftData
import SwiftUI

struct DrumPatternEditView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var navManager: NavigationStateManager
    @Query(sort: \Style.name) private var styles: [Style]
    @Query(sort: \Feel.name) private var feels: [Feel]

    @Binding var navPath: NavigationPath
    @State private var viewModel: ViewModel
    
    @Binding var drumPattern: DrumPattern
    
    init(drumPattern: Binding<DrumPattern>, navPath: Binding<NavigationPath>) {
        self._drumPattern = drumPattern
        self._navPath = navPath
        self.viewModel = .init(drumPattern: drumPattern.wrappedValue)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Drum Pattern Info")) {
                VStack {
                    TextField("Name", text: $viewModel.name)
                    
                    Picker("Style", selection: $viewModel.style) {
                        Text("< None >").tag(nil as Style?)
                        ForEach(styles, id: \.self) { style in
                            Text(style.name).tag(style as Style?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Feel", selection: $viewModel.feel) {
                        Text("< None >>").tag(nil as Feel?)
                        ForEach(feels, id: \.self) { feel in
                            Text(feel.name).tag(feel as Feel?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
//            Section(header: Text("Drum Patterns")) {
//                if viewModel.drumPatterns.isEmpty {
//                    Text("No drum patterns")
//                        .foregroundStyle(.secondary)
//                } else {
//                    ForEach(viewModel.drumPatterns) { pattern in
//                        Text(pattern.name)
//                    }
//                }
//            }
//            
//            Section(header: Text("Harmonic Patterns")) {
//                if viewModel.harmonicPatterns.isEmpty {
//                    Text("No harmonic patterns")
//                        .foregroundStyle(.secondary)
//                } else {
//                    ForEach(viewModel.harmonicPatterns) { pattern in
//                        Text(pattern.name)
//                    }
//                }
//            }
            
        }
        .navigationTitle(viewModel.name.isEmpty ? "New Drum Pattern" : viewModel.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        .onAppear {
            viewModel.modelContext = self.modelContext
            viewModel.navManager = self.navManager
        }
#if os(iOS)
        .navigationBarBackButtonHidden(true)
#endif
        .toolbar {
            // Check if we are likely in a NavigationStack (i.e., not a wide master-detail layout).
            // `horizontalSizeClass == .compact` is generally true on iPhone and half-screen iPads,
            // which usually means we are pushed in a stack and need a back button.
            if horizontalSizeClass == .compact {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        navManager.requestNavigation {
                            navPath.removeLast() // Go back
                        }
                    } label: {
                        // Use a system icon that looks like the native back button
                        Image(systemName: "chevron.backward")
                            .accessibilityLabel("Back")
                    }
                }
            }
            
            ToolbarItemGroup {
                Button("Revert") {
                    viewModel.reset()
                }
                .disabled(!viewModel.hasUnsavedChanges)
                
                Button("Save") {
                    viewModel.save(modelContext: self.modelContext)
                }
                .disabled(!viewModel.hasUnsavedChanges)
            }
        }
        .onChange(of: drumPattern) {
            // If the bound model instance changed underneath us, reset draft and clear dirty
            viewModel = .init(drumPattern: drumPattern)
            viewModel.navManager = self.navManager
            navManager.isDirty = false
        }
        .onDisappear {
            // Ensure global dirty state is cleared when editor is removed
            navManager.isDirty = false
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DrumPattern.self, configurations: config)
    
    let drumPattern = DrumPattern(name: "Preview Drum Pattern")
    container.mainContext.insert(drumPattern)
    
    return DrumPatternEditView(drumPattern: .constant(drumPattern), navPath: .constant(NavigationPath()))
        .modelContainer(container)
        .environmentObject(NavigationStateManager())
}
