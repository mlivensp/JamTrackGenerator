////
////  PlayPauseButtonView.swift
////  JamTrackGenerator
////
////  Created by Michael Livenspargar on 10/10/25.
////
//
//import SwiftUI
//
//struct PlayPauseButtonView: View {
//    @State private var playIsPressed = false
//    
//    var body: some View {
//        Button(action: togglePlayback) {
//            Image(systemName: playButtonIcon)
//                .font(.title)
//                .frame(width: 50, height: 50)
//                .foregroundStyle(.primary)
//                .accessibilityLabel(playButtonIcon == "play.fill" ? "Play" : "Pause")
//                .clipShape(Circle())
//        }
//        .buttonStyle(.plain)
//        .scaleEffect(playIsPressed ? 0.95 : 1.0)
//        .animation(.easeOut(duration: 0.2), value: playIsPressed)
//        .gesture(
//            DragGesture(minimumDistance: 0)
//                .onChanged { _ in playIsPressed = true }
//                .onEnded { _ in playIsPressed = false }
//        )
//    }
//    
//    private var playButtonIcon: String {
//        if viewModel.isPlaying {
//            return "pause.fill"
//        } else {
//            return "play.fill"
//        }
//    }
//
//    private func togglePlayback() {
//        do {
//            try viewModel.togglePlayback()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//    }
//}
//
//#Preview {
//    PlayPauseButtonView()
//}
