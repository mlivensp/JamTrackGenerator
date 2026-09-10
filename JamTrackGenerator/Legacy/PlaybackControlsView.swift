////
////  PlaybackControlsView.swift
////  JamTrackGenerator
////
////  Created by Michael Livenspargar on 9/1/25.
////
//
//import SwiftUI
//
//
///// Playback controls section
//struct PlaybackControlsView: View {
//    @ObservedObject var midiPlayer: MIDIPlayer
//    let score: MusicScore
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            // Main playback controls
//            HStack(spacing: 20) {
//                // Previous/Rewind (future feature)
//                Button(action: { midiPlayer.seek(to: 0) }) {
//                    Image(systemName: "backward.end.fill")
//                        .font(.title2)
//                }
//                .disabled(midiPlayer.playbackState != .stopped)
//                
//                // Play/Pause button
//                Button(action: togglePlayback) {
//                    Image(systemName: playButtonIcon)
//                        .font(.title)
//                        .frame(width: 50, height: 50)
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .clipShape(Circle())
//                }
//                
//                // Stop button
//                Button(action: { midiPlayer.stop() }) {
//                    Image(systemName: "stop.fill")
//                        .font(.title2)
//                }
//                .disabled(midiPlayer.playbackState == .stopped)
//                
//                // Next (future feature)
//                Button(action: { /* TODO */ }) {
//                    Image(systemName: "forward.end.fill")
//                        .font(.title2)
//                }
//                .disabled(true)
//            }
//            
//            // Progress bar
//            VStack(spacing: 8) {
//                ProgressView(value: midiPlayer.currentTime,
//                           total: midiPlayer.totalDuration)
//                    .progressViewStyle(LinearProgressViewStyle())
//                
//                HStack {
//                    Text(formatTime(midiPlayer.currentTime))
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                    
//                    Text(formatTime(midiPlayer.totalDuration))
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            
//            // Additional controls
//            HStack {
//                // Tempo control
//                VStack {
//                    Text("Tempo")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    HStack {
//                        Button("-") {
//                            midiPlayer.setTempo(midiPlayer.currentTempo - 10)
//                        }
//                        .disabled(midiPlayer.currentTempo <= 30)
//                        
//                        Text("\(Int(midiPlayer.currentTempo))")
//                            .font(.caption)
//                            .frame(width: 40)
//                        
//                        Button("+") {
//                            midiPlayer.setTempo(midiPlayer.currentTempo + 10)
//                        }
//                        .disabled(midiPlayer.currentTempo >= 300)
//                    }
//                }
//                
//                Spacer()
//                
//                // Volume control
//                VStack {
//                    Text("Volume")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    HStack {
//                        Image(systemName: "speaker.fill")
//                            .font(.caption)
//                        
//                        Slider(value: $midiPlayer.volume, in: 0...1)
//                            .frame(width: 80)
//                        
//                        Image(systemName: "speaker.wave.3.fill")
//                            .font(.caption)
//                    }
//                }
//                
//                Spacer()
//                
//                // Loop toggle
//                Button(action: { midiPlayer.isLooping.toggle() }) {
//                    Image(systemName: midiPlayer.isLooping ? "repeat.1" : "repeat")
//                        .font(.title3)
//                        .foregroundColor(midiPlayer.isLooping ? .blue : .gray)
//                }
//            }
//        }
//        .padding()
//        .background(Color(UIColor.secondarySystemBackground))
//    }
//    
//    private var playButtonIcon: String {
//        switch midiPlayer.playbackState {
//        case .playing:
//            return "pause.fill"
//        case .paused, .stopped:
//            return "play.fill"
//        }
//    }
//
//#Preview {
//    PlaybackControlsView()
//}
