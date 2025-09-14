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
    @Query var harmonicPatterns: [HarmonicPattern]
    @Query var drumPatterns: [DrumPattern]
    @Query var styles: [Style]
    @Query var feels: [Feel]

    var body: some View {
        // Remove the outer List and switch the body directly
        switch category {
        case .jamTracks:
            JamTracksView(selectedJamTrack: $selectedJamTrack)
        case .styles:
            List {
                ForEach(styles) { style in
                    NavigationLink(value: style) {
                        Text(style.name)
                    }
                }
            }
        case .feels:
            List {
                ForEach(feels) { feel in
                    NavigationLink(value: feel) {
                        Text(feel.name)
                    }
                }
            }
        case .drumPatterns:
            List {
                ForEach(drumPatterns) { pattern in
                    NavigationLink(value: pattern) {
                        Text(pattern.name)
                    }
                }
            }
        case .harmonicPatterns:
            List {
                ForEach(harmonicPatterns) { pattern in
                    NavigationLink(value: pattern) {
                        Text(pattern.name)
                    }
                }
            }
        }
    }
}

//#Preview {
//    CategoryContentView()
//}
