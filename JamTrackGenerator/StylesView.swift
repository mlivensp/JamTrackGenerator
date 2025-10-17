//
//  StylesView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/13/25.
//

import SwiftData
import SwiftUI

struct StylesView: View {
    @Query(sort: \SchemaV1.Style.name) private var styles: [SchemaV1.Style]
    @Binding var selectedStyle: SchemaV1.Style?

    var body: some View {
        List(selection: $selectedStyle) {
            ForEach(styles) { style in
                Text(style.name).tag(style)
            }
        }
        .navigationTitle("Styles")
    }
}
//#Preview {
//    StylesView()
//}
