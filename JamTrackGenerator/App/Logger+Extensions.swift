//
//  Logger+Extensions.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/12/26.
//

import OSLog

extension Logger {
    // 1. Define your app's main subsystem (usually your bundle ID)
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.bitpicker.JamTrackGenerator"

    // 2. Create distinct categories for different parts of your app
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let midi = Logger(subsystem: subsystem, category: "MIDI")
    static let database = Logger(subsystem: subsystem, category: "Database")
}
