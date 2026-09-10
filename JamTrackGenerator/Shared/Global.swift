//
//  Global.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/27/25.
//

import Foundation

typealias Pulse = UInt32
typealias Velocity = UInt8
typealias Octave = UInt8

struct Global {
    static let pulsesPerQuarterNote: UInt32 = 480
}

extension String {
    func camelCaseToCapitalizedWords() -> String {
        var words: [String] = []
        var currentWord = ""
        
        // Iterate through each character
        for (index, char) in self.enumerated() {
            // If character is uppercase and not the first character, start new word
            if char.isUppercase && !currentWord.isEmpty {
                words.append(currentWord)
                currentWord = String(char)
            } else {
                currentWord.append(char)
            }
            
            // Add the last word if we're at the end
            if index == self.count - 1 {
                words.append(currentWord)
            }
        }
        
        // Capitalize each word and join with spaces
        return words
            .filter { !$0.isEmpty }
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
