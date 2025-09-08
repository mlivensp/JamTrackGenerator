//
//  ModelContainer+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/8/25.
//

import Foundation
import SwiftData

extension ModelContainer {
    @MainActor
    func setup() {
        let seedImporter = SeedImporter()
        seedImporter.importSeedData(container: self)
    }
}
