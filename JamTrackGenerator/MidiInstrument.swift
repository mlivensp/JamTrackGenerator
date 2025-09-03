//
//  MidiInstrument.swift
//  JamTrackGenerator
//
//  Created by Michael Livenspargar on 8/29/25.
//

enum MidiInstrument: UInt8, Identifiable, CaseIterable {
    var id: Self { self }
    // Piano
    case acousticGrandPiano = 0
    case brightAcousticPiano = 1
    case electricGrandPiano = 2
    case honkyTonkPiano = 3
    case electricPiano1 = 4
    case electricPiano2 = 5
    case harpsichord = 6
    case clavinet = 7

    // Chromatic Percussion
    case celesta = 8
    case glockenspiel = 9
    case musicBox = 10
    case vibraphone = 11
    case marimba = 12
    case xylophone = 13
    case tubularBells = 14
    case dulcimer = 15

    // Organ
    case drawbarOrgan = 16
    case percussiveOrgan = 17
    case rockOrgan = 18
    case churchOrgan = 19
    case reedOrgan = 20
    case accordion = 21
    case harmonica = 22
    case tangoAccordion = 23

    // Guitar
    case acousticGuitarNylon = 24
    case acousticGuitarSteel = 25
    case electricGuitarJazz = 26
    case electricGuitarClean = 27
    case electricGuitarMuted = 28
    case overdrivenGuitar = 29
    case distortionGuitar = 30
    case guitarHarmonics = 31

    // Bass
    case acousticBass = 32
    case electricBassFinger = 33
    case electricBassPick = 34
    case fretlessBass = 35
    case slapBass1 = 36
    case slapBass2 = 37
    case synthBass1 = 38
    case synthBass2 = 39

    // Strings
    case violin = 40
    case viola = 41
    case cello = 42
    case contrabass = 43
    case tremoloStrings = 44
    case pizzicatoStrings = 45
    case orchestralHarp = 46
    case timpani = 47

    // Ensemble
    case stringEnsemble1 = 48
    case stringEnsemble2 = 49
    case synthStrings1 = 50
    case synthStrings2 = 51
    case choirAahs = 52
    case voiceOohs = 53
    case synthVoice = 54
    case orchestralHit = 55

    // Brass
    case trumpet = 56
    case trombone = 57
    case tuba = 58
    case mutedTrumpet = 59
    case frenchHorn = 60
    case brassSection = 61
    case synthBrass1 = 62
    case synthBrass2 = 63

    // Reed
    case sopranoSax = 64
    case altoSax = 65
    case tenorSax = 66
    case baritoneSax = 67
    case oboe = 68
    case englishHorn = 69
    case bassoon = 70
    case clarinet = 71

    // Pipe
    case piccolo = 72
    case flute = 73
    case recorder = 74
    case panFlute = 75
    case blownBottle = 76
    case shakuhachi = 77
    case whistle = 78
    case ocarina = 79

    // Synth Lead
    case lead1Square = 80
    case lead2Sawtooth = 81
    case lead3Calliope = 82
    case lead4Chiff = 83
    case lead5Charang = 84
    case lead6Voice = 85
    case lead7Fifths = 86
    case lead8BassLead = 87

    // Synth Pad
    case pad1NewAge = 88
    case pad2Warm = 89
    case pad3Polysynth = 90
    case pad4Choir = 91
    case pad5Bowed = 92
    case pad6Metallic = 93
    case pad7Halo = 94
    case pad8Sweep = 95

    // Synth Effects
    case fx1Rain = 96
    case fx2Soundtrack = 97
    case fx3Crystal = 98
    case fx4Atmosphere = 99
    case fx5Brightness = 100
    case fx6Goblins = 101
    case fx7Echoes = 102
    case fx8SciFi = 103

    // Ethnic
    case sitar = 104
    case banjo = 105
    case shamisen = 106
    case koto = 107
    case kalimba = 108
    case bagpipe = 109
    case fiddle = 110
    case shanai = 111

    // Percussive
    case tinkleBell = 112
    case agogo = 113
    case steelDrums = 114
    case woodblock = 115
    case taikoDrum = 116
    case melodicTom = 117
    case synthDrum = 118
    case reverseCymbal = 119

    // Sound Effects
    case guitarFretNoise = 120
    case breathNoise = 121
    case seashore = 122
    case birdTweet = 123
    case telephoneRing = 124
    case helicopter = 125
    case applause = 126
    case gunshot = 127
    
    var description: String {
        "\(self)".camelCaseToCapitalizedWords()
    }
}

enum MidiInstrumentFamily: String, CaseIterable {
    case piano
    case chromaticPercussion
    case organ
    case guitar
    case bass
    case strings
    case ensemble
    case brass
    case reed
    case pipe
    case synthLead
    case synthPad
    case synthEffects
    case ethnic
    case percussive
    case soundEffects
}

extension MidiInstrument {
    var family: MidiInstrumentFamily {
        switch self {
        case .acousticGrandPiano, .brightAcousticPiano, .electricGrandPiano,
             .honkyTonkPiano, .electricPiano1, .electricPiano2,
             .harpsichord, .clavinet:
            return .piano

        case .celesta, .glockenspiel, .musicBox, .vibraphone,
             .marimba, .xylophone, .tubularBells, .dulcimer:
            return .chromaticPercussion

        case .drawbarOrgan, .percussiveOrgan, .rockOrgan, .churchOrgan,
             .reedOrgan, .accordion, .harmonica, .tangoAccordion:
            return .organ

        case .acousticGuitarNylon, .acousticGuitarSteel, .electricGuitarJazz,
             .electricGuitarClean, .electricGuitarMuted, .overdrivenGuitar,
             .distortionGuitar, .guitarHarmonics:
            return .guitar

        case .acousticBass, .electricBassFinger, .electricBassPick,
             .fretlessBass, .slapBass1, .slapBass2, .synthBass1, .synthBass2:
            return .bass

        case .violin, .viola, .cello, .contrabass, .tremoloStrings,
             .pizzicatoStrings, .orchestralHarp, .timpani:
            return .strings

        case .stringEnsemble1, .stringEnsemble2, .synthStrings1,
             .synthStrings2, .choirAahs, .voiceOohs, .synthVoice, .orchestralHit:
            return .ensemble

        case .trumpet, .trombone, .tuba, .mutedTrumpet, .frenchHorn,
             .brassSection, .synthBrass1, .synthBrass2:
            return .brass

        case .sopranoSax, .altoSax, .tenorSax, .baritoneSax,
             .oboe, .englishHorn, .bassoon, .clarinet:
            return .reed

        case .piccolo, .flute, .recorder, .panFlute, .blownBottle,
             .shakuhachi, .whistle, .ocarina:
            return .pipe

        case .lead1Square, .lead2Sawtooth, .lead3Calliope, .lead4Chiff,
             .lead5Charang, .lead6Voice, .lead7Fifths, .lead8BassLead:
            return .synthLead

        case .pad1NewAge, .pad2Warm, .pad3Polysynth, .pad4Choir,
             .pad5Bowed, .pad6Metallic, .pad7Halo, .pad8Sweep:
            return .synthPad

        case .fx1Rain, .fx2Soundtrack, .fx3Crystal, .fx4Atmosphere,
             .fx5Brightness, .fx6Goblins, .fx7Echoes, .fx8SciFi:
            return .synthEffects

        case .sitar, .banjo, .shamisen, .koto, .kalimba,
             .bagpipe, .fiddle, .shanai:
            return .ethnic

        case .tinkleBell, .agogo, .steelDrums, .woodblock,
             .taikoDrum, .melodicTom, .synthDrum, .reverseCymbal:
            return .percussive

        case .guitarFretNoise, .breathNoise, .seashore, .birdTweet,
             .telephoneRing, .helicopter, .applause, .gunshot:
            return .soundEffects
        }
    }
}
