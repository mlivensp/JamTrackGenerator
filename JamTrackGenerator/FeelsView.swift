//
//  FeelsView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import SwiftUI
import SwiftData

struct FeelsView: View {
    @Query(sort: \SchemaV1.Feel.name) private var feels: [SchemaV1.Feel]
    @Binding var selectedFeel: SchemaV1.Feel?

    var body: some View {
        List(selection: $selectedFeel) {
            ForEach(feels) { feel in
                Text(feel.name).tag(feel)
            }
        }
        .navigationTitle("Feels")
        .onChange(of: selectedFeel) {
            if let feel = selectedFeel {
                print("selectedFeel is \(feel.name)")
            } else {
                print("selectedFeel is nil")
            }
        }
    }
}
//#Preview {
//    FeelsView()
//}
