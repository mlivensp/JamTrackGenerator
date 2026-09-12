//
//  ModelContext+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/10/25.
//

import Foundation
import SwiftData

extension ModelContext {
    var sqliteCommand: String {
        if let url = container.configurations.first?.url.path(percentEncoded: false) {
            return "sqlite3 \"\(url)\""
        } else {
            return "No SQLite database found."
        }
    }
}
