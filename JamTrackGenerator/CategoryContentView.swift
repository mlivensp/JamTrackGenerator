//
//  CategoryContentView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import SwiftData
import SwiftUI

import SwiftUI
import SwiftData

struct CategoryContentView: View {
    @Environment(\.modelContext) private var modelContext
    let category: SidebarCategory
    @Binding var selectedJamTrack: JamTrack?
    @Binding var selectedStyle: Style?
    @Binding var selectedFeel: Feel?
    @Binding var selectedDrumPattern: DrumPattern?
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
//            case .styles:
//                ForEach(styles) { style in
//                    NavigationLink(value: style) {
//                        Text(style.name)
//                    }
//                    .onTapGesture { selectedStyle = style }
//                }
//            case .feels:
//                ForEach(feels) { feel in
//                    NavigationLink(value: feel) {
//                        Text(feel.name)
//                    }
//                    .onTapGesture { selectedFeel = feel }
//                }
            case .drumPatterns:
                DrumPatternsView(selectedDrumPattern: $selectedDrumPattern)
//            case .harmonicPatterns:
//                ForEach(harmonicPatterns) { pattern in
//                    NavigationLink(value: pattern) {
//                        Text(pattern.name)
//                    }
//                    .onTapGesture { selectedHarmonicPattern = pattern }
//                }
            default:
                Text("This is category \(category.rawValue)")
            }
        }
        .navigationTitle(category.rawValue)
        .navigationDestination(for: JamTrack.self) { JamTrackDetailView(jamTrack: $0) }
        .navigationDestination(for: Style.self) { Text($0.name) } // Replace with StyleDetailView
        .navigationDestination(for: Feel.self) { Text($0.name) } // Replace with FeelDetailView
        .navigationDestination(for: DrumPattern.self) { Text($0.name) } // Replace with DrumPatternDetailView
        .navigationDestination(for: HarmonicPattern.self) { Text($0.name) } // Replace with HarmonicPatternDetailView
    }
    
    private func importDrumPattern() {
        print("Importing drum pattern...")
    }
}
//#Preview {
//    CategoryContentView()
//}
