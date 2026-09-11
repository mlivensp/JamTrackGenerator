//
//  EventBuilder.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 9/9/25.
//

import Foundation

protocol EventBuilder {
    func buildEvents(startingPulse: UInt) -> [EventDescriptor]
}
