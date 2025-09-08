//
//  EditPartView.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/3/25.
//

import SwiftUI

struct EditPartView: View {
    @Binding var part: Part
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Form {
            HStack {
                Text("Part")
                Spacer()
                Text(part.instrument.name)
            }
         }
        .navigationTitle("Edit Part")
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

//#Preview {
//    @Previewable @State var part = Part(instrument: .accordion)
//    EditPartView(part: $part)
//}
