//
//  MidiDocumentTests.swift
//  JamTrackGeneratorTests
//
//  Created by Michael Livenspargar on 8/25/25.
//

import Foundation
@testable import JamTrackGenerator
import Testing

struct MidiDocumentTests {

    @Test func testHeaderToData() async throws {
        let payload = MidiDocument.Payload(tracks: [])
        let data = payload.encodeToData()
        let expected = Data([0x4d, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x01, 0x00, 0x00, 0x01, 0xE0])
        #expect(data == expected)
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
