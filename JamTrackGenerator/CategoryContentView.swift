//
//  CategoryContentView.swift
//  JamTrackGenerator
//

import SwiftUI

struct CategoryContentView: View {
    let category: SidebarCategory
    @Binding var navPath: NavigationPath
    
    // Use @Binding — NOT @Bindable
    @Binding var selectedJamTrack: JamTrack?
    @Binding var selectedStyle: Style?
    @Binding var selectedFeel: Feel?
    @Binding var selectedDrumPatternNavigation: DrumPatternNavigation?
    @Binding var selectedHarmonicPattern: HarmonicPattern?
    
    var body: some View {
        Group {
            switch category {
//            case .jamTracks:
//                Text("Waffle0")
////                JamTracksView(selectedJamTrack: $selectedJamTrack)
//                
//            case .styles:
//                Text("Waffle1")
////                StylesView(selectedStyle: $selectedStyle, navPath: $navPath)
//                
//            case .feels:
//                FeelsView(selectedFeel: $selectedFeel)
//                
//            case .drumPatterns:
//                DrumPatternsView(selectedDrumPatternNavigation: $selectedDrumPatternNavigation)
//                
//            case .harmonicPatterns:
//                // Placeholder or future view
//                Text("Harmonic Patterns coming soon")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .background(backgroundColor)   // Cross-platform
//                    .foregroundColor(.secondary)
            default:
                Text("Default Category")
            }
        }
        .navigationTitle(category.rawValue)
    }
    
    private var backgroundColor: Color {
#if os(iOS)
        Color(.systemBackground)
#else
        Color(.windowBackgroundColor) // macOS
#endif
    }
}
