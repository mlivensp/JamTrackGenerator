//import Foundation
//import AudioToolbox
//import AVFoundation
//
//enum PlaybackState {
//    case stopped
//    case playing
//    case paused
//}
//
//@Observable
//class MIDIPlayer {
//    private var musicSequence: MusicSequence?
//    private var musicPlayer: MusicPlayer?
//    private var playbackTimer: Timer?
//
//    var playbackState: PlaybackState = .stopped
//    var isLooping: Bool = false
//    var volume: Float = 0.8
//    var onPlaybackEnded: (() -> Void)?
//
//    init() throws {
//        #if os(iOS)
//        let session = AVAudioSession.sharedInstance()
//        try session.setCategory(.playback, mode: .default)
//        try session.setActive(true)
//        #endif
//    }
//
//    func playMIDIFile(from fileURL: URL, loop: Bool = false) throws {
//        isLooping = loop
//
//        var seq: MusicSequence?
//        NewMusicSequence(&seq)
//        guard let sequence = seq else {
//            throw NSError(
//                domain: "MIDIPlayer",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "Failed to create MusicSequence"]
//            )
//        }
//        musicSequence = sequence
//
//        let fileType = MusicSequenceFileTypeID.midiType
//        let status = MusicSequenceFileLoad(
//            sequence,
//            fileURL as CFURL,
//            fileType,
//            MusicSequenceLoadFlags()
//        )
//        guard status == noErr else {
//            throw NSError(
//                domain: "MIDIPlayer",
//                code: Int(status),
//                userInfo: [NSLocalizedDescriptionKey: "Failed to load MIDI file (OSStatus \(status))"]
//            )
//        }
//
//        var player: MusicPlayer?
//        NewMusicPlayer(&player)
//        guard let musicPlayer = player else {
//            throw NSError(
//                domain: "MIDIPlayer",
//                code: -2,
//                userInfo: [NSLocalizedDescriptionKey: "Failed to create MusicPlayer"]
//            )
//        }
//        self.musicPlayer = musicPlayer
//
//        MusicPlayerSetSequence(musicPlayer, sequence)
//        MusicPlayerPreroll(musicPlayer)
//
//        MusicPlayerStart(musicPlayer)
//        playbackState = .playing
//        print("▶️ Started MIDI playback: \(fileURL.lastPathComponent)")
//
//        startPlaybackMonitoring()
//    }
//
//    func pauseMIDIFile() {
//        guard let musicPlayer = musicPlayer else { return }
//        MusicPlayerStop(musicPlayer)
//        playbackState = .paused
//        print("⏸️ Paused MIDI playback")
//        stopPlaybackMonitoring()
//    }
//
//    func resumeMIDIFile() {
//        guard let musicPlayer = musicPlayer else { return }
//        MusicPlayerStart(musicPlayer)
//        playbackState = .playing
//        print("▶️ Resumed MIDI playback")
//        startPlaybackMonitoring()
//    }
//
//    func stopMIDIFile() {
//        guard let musicPlayer = musicPlayer else { return }
//        MusicPlayerStop(musicPlayer)
//        playbackState = .stopped
//        print("⏹️ Stopped MIDI playback")
//        stopPlaybackMonitoring()
//    }
//
//    // MARK: - Playback Monitoring
//
//    private func startPlaybackMonitoring() {
//        playbackTimer?.invalidate()
//        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
//            self?.checkPlaybackStatus()
//        }
//    }
//
//    private func stopPlaybackMonitoring() {
//        playbackTimer?.invalidate()
//        playbackTimer = nil
//    }
//
//    private func checkPlaybackStatus() {
//        guard let musicPlayer = musicPlayer, let musicSequence = musicSequence else { return }
//
//        // Get current playback time in seconds
//        var currentTime: MusicTimeStamp = 0
//        MusicPlayerGetTime(musicPlayer, &currentTime)
//
//        // Get sequence duration in beats
//        var sequenceDurationBeats: MusicTimeStamp = 0
//        var trackCount: UInt32 = 0
//        MusicSequenceGetTrackCount(musicSequence, &trackCount)
//        for i in 0..<trackCount {
//            var track: MusicTrack?
//            MusicSequenceGetIndTrack(musicSequence, i, &track)
//            if let track = track {
//                var trackLength: MusicTimeStamp = 0
//                var propertyLength: UInt32 = 0
//                MusicTrackGetProperty(track, kSequenceTrackProperty_TrackLength, &trackLength, &propertyLength)
//                sequenceDurationBeats = max(sequenceDurationBeats, trackLength)
//            }
//        }
//
//        // Convert sequence duration from beats to seconds
//        var sequenceDurationSeconds: TimeInterval = 0
//        MusicSequenceGetSecondsForBeats(musicSequence, sequenceDurationBeats, &sequenceDurationSeconds)
//
//        print("currentTime: \(currentTime), sequenceDurationSeconds: \(sequenceDurationSeconds)")
//        // Check if playback has reached the end
//        if currentTime >= sequenceDurationSeconds {
//            if isLooping {
//                MusicPlayerSetTime(musicPlayer, 0)
//                MusicPlayerStart(musicPlayer)
//                print("🔄 Looping MIDI playback")
//            } else {
//                stopMIDIFile()
//                onPlaybackEnded?()
//                print("🏁 MIDI playback ended")
//            }
//        }
//    }
//
//    deinit {
//        stopPlaybackMonitoring()
//        if let musicPlayer = musicPlayer {
//            MusicPlayerStop(musicPlayer)
//            DisposeMusicPlayer(musicPlayer)
//        }
//        if let musicSequence = musicSequence {
//            DisposeMusicSequence(musicSequence)
//        }
//    }
//}
