//
//  EditSectionView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/2/25.
//

import SwiftUI

struct EditSectionView: View {
    @Binding var section: Section
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Form {
            HStack {
                Text("Section")
                Spacer()
                Text(section.section.description)
            }
         }
        .navigationTitle("Edit Section")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    dismiss()
                }
            }
        }
    }
}
//
//#Preview {
//    var section = Section(section: SongSection.intro)
//    EditSectionView(section: Binding( get: { section }, set: { newItem in }))
//}
