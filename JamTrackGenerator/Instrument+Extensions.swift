//
//  Instrument+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 10/2/25.
//

import Foundation

extension Instrument {
    var isDrums: Bool {
        return name.lowercased().contains("drum")
    }
}
