//
//  DrumPart.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/23/25.
//

import Foundation

enum MidiDrumNote: UInt8, CaseIterable {
    // General MIDI Level 1 Drum Map (Channel 10)
    case acousticBassDrum = 35
    case bassDrum1 = 36
    case sideStick = 37
    case acousticSnare = 38
    case handClap = 39
    case electricSnare = 40
    case lowFloorTom = 41
    case closedHiHat = 42
    case highFloorTom = 43
    case pedalHiHat = 44
    case lowTom = 45
    case openHiHat = 46
    case lowMidTom = 47
    case hiMidTom = 48
    case crashCymbal1 = 49
    case highTom = 50
    case rideCymbal1 = 51
    case chineseCymbal = 52
    case rideBell = 53
    case tambourine = 54
    case splashCymbal = 55
    case cowbell = 56
    case crashCymbal2 = 57
    case vibraslap = 58
    case rideCymbal2 = 59
    case hiBongo = 60
    case lowBongo = 61
    case muteHiConga = 62
    case openHiConga = 63
    case lowConga = 64
    case highTimbale = 65
    case lowTimbale = 66
    case highAgogo = 67
    case lowAgogo = 68
    case cabasa = 69
    case maracas = 70
    case shortWhistle = 71
    case longWhistle = 72
    case shortGuiro = 73
    case longGuiro = 74
    case claves = 75
    case hiWoodBlock = 76
    case lowWoodBlock = 77
    case muteCuica = 78
    case openCuica = 79
    case muteTriangle = 80
    case openTriangle = 81
    
    // Optional: Display name for UI or debugging
    var displayName: String {
        String(describing: self).capitalized
    }
}
