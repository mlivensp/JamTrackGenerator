import SwiftData
import SwiftUI

struct CategoryContentView: View {
    @Environment(\.modelContext) private var modelContext
    let category: SidebarCategory
    @Binding var selectedJamTrack: JamTrack?
    @Binding var selectedStyle: Style?
    @Binding var selectedFeel: Feel?
    @Binding var selectedDrumPatternNavigation: DrumPatternNavigation?
    @Binding var selectedHarmonicPattern: HarmonicPattern?
    @Query var harmonicPatterns: [HarmonicPattern]
    @Query var drumPatterns: [DrumPattern]
    @Query var styles: [Style]
    @Query var feels: [Feel]
    
    var body: some View {
        Group {
            switch category {
            case .jamTracks:
                JamTracksView(selectedJamTrack: $selectedJamTrack)
            case .drumPatterns:
                DrumPatternsView(selectedDrumPatternNavigation: $selectedDrumPatternNavigation)
            default:
                Text("This is category \(category.rawValue)")
            }
        }
        .navigationTitle(category.rawValue)
//        .navigationDestination(for: JamTrack.self) { JamTrackDetailView(jamTrack: $0) }
        .navigationDestination(for: Style.self) { Text($0.name) }
        .navigationDestination(for: Feel.self) { Text($0.name) }
        .navigationDestination(for: HarmonicPattern.self) { Text($0.name) }
        .onAppear {
            print("CategoryContentView appeared for category: \(category.rawValue)")
        }
    }
}
