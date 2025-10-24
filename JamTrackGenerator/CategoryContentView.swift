import SwiftData
import SwiftUI

struct CategoryContentView: View {
    @Environment(\.modelContext) private var modelContext
    let category: SidebarCategory
    @Binding var navPath: NavigationPath
    @Binding var selectedJamTrack: JamTrack?
    @Binding var selectedStyle: Style?
    @Binding var selectedFeel: Feel?
    @Binding var selectedDrumPatternNavigation: DrumPatternNavigation?
    @Binding var selectedHarmonicPattern: HarmonicPattern?
    
    var body: some View {
        Group {
            switch category {
            case .jamTracks:
                JamTracksView(selectedJamTrack: $selectedJamTrack)
            case .styles:
                StylesView(
                    selectedStyle: $selectedStyle,
                    navPath: $navPath
                )
            case .feels:
                FeelsView(selectedFeel: $selectedFeel)
            
            case .drumPatterns:
                DrumPatternsView(selectedDrumPatternNavigation: $selectedDrumPatternNavigation)
            default:
                Text("This is category \(category.rawValue)")
            }
        }
        .navigationTitle(category.rawValue)
    }
}
