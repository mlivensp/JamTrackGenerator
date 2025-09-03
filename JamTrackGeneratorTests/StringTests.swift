//
//  StringTests.swift
//  JamTrackGeneratorTests
//
//  Created by Michael Livenspargar on 9/3/25.
//

@testable import JamTrackGenerator
import Testing

struct StringTests {

    @Test func testSplitCamelCase() async throws {
        let input = "helloWorld"
        let expected = "Hello World"
        #expect(input.camelCaseToCapitalizedWords() == expected)
    }
}
