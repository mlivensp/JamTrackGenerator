import Foundation
import AudioToolbox
import AVFoundation

enum PlaybackState {
    case stopped
    case playing
    case paused
}

@Observable
class MIDIPlayer {
    private var musicSequence: MusicSequence?
    private var musicPlayer: MusicPlayer?

    var playbackState: PlaybackState = .stopped
    var isLooping: Bool = false
    var volume: Float = 0.8

    init() throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        #endif
    }

    /// Load & play a `.mid` file from disk
    func playMIDIFile(from fileURL: URL, loop: Bool = false) throws {
        isLooping = loop

        // 1) Create a new MusicSequence
        var seq: MusicSequence?
        NewMusicSequence(&seq)
        guard let sequence = seq else {
            throw NSError(
                domain: "MIDIPlayer",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create MusicSequence"]
            )
        }
        musicSequence = sequence

        // 2) Load the file URL into the sequence
        //    Use the Swift-native constant for MIDI type
        let fileType = MusicSequenceFileTypeID.midiType
        let status = MusicSequenceFileLoad(
            sequence,
            fileURL as CFURL,
            fileType,
            MusicSequenceLoadFlags()
        )
        guard status == noErr else {
            throw NSError(
                domain: "MIDIPlayer",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Failed to load MIDI file (OSStatus \(status))"]
            )
        }

        // 3) Create & configure the MusicPlayer
        var player: MusicPlayer?
        NewMusicPlayer(&player)
        guard let musicPlayer = player else {
            throw NSError(
                domain: "MIDIPlayer",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create MusicPlayer"]
            )
        }
        self.musicPlayer = musicPlayer

        MusicPlayerSetSequence(musicPlayer, sequence)
        MusicPlayerPreroll(musicPlayer)

        // 4) Start playback
        MusicPlayerStart(musicPlayer)
        playbackState = .playing
        print("▶️ Started MIDI playback: \(fileURL.lastPathComponent)")
    }

    func pauseMIDIFile() {
        guard let musicPlayer = musicPlayer else { return }
        MusicPlayerStop(musicPlayer)
        playbackState = .paused
        print("⏸️ Paused MIDI playback")
    }

    func resumeMIDIFile() {
        guard let musicPlayer = musicPlayer else { return }
        MusicPlayerStart(musicPlayer)
        playbackState = .playing
        print("▶️ Resumed MIDI playback")
    }

    func stopMIDIFile() {
        guard let musicPlayer = musicPlayer else { return }
        MusicPlayerStop(musicPlayer)
        playbackState = .stopped
        print("⏹️ Stopped MIDI playback")
    }
}
