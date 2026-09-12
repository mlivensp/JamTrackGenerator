//
//  Part+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/19/25.
//

import Foundation

extension Part {
    var isDrumPart: Bool {
        return instrument?.name.lowercased().contains("drum") ?? false
    }
}
