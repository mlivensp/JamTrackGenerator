import SwiftUI

struct PlaybackControlsView: View {
    @Bindable var viewModel: JamTrackDetailView.ViewModel
    @Environment(\.modelContext) var modelContext

    @State private var playIsPressed = false
    @State private var stopIsPressed = false
    @State private var loopIsPressed = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Spacer()

                // Play/Pause button
                Button(action: togglePlayback) {
                    Image(systemName: playButtonIcon)
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.primary)
                        .accessibilityLabel(playButtonIcon == "play.fill" ? "Play" : "Pause")
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .scaleEffect(playIsPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.2), value: playIsPressed)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in playIsPressed = true }
                        .onEnded { _ in playIsPressed = false }
                )

                // Stop button
                Button(action: { viewModel.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.primary)
                        .accessibilityLabel("Stop")
                        .clipShape(Circle())
                }
                .disabled(viewModel.midiPlayer?.playbackState == .stopped)
                .buttonStyle(.plain)
                .scaleEffect(stopIsPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.2), value: stopIsPressed)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in stopIsPressed = true }
                        .onEnded { _ in stopIsPressed = false }
                )

                Spacer(minLength: 0)

                // Loop toggle
                Button(action: { viewModel.midiPlayer?.isLooping.toggle() }) {
                    Image(systemName: viewModel.midiPlayer?.isLooping ?? false ? "repeat.1" : "repeat")
                        .font(.title3)
                        .foregroundStyle(viewModel.midiPlayer?.isLooping ?? false ? Color.accentColor : .primary)
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .scaleEffect(loopIsPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.2), value: loopIsPressed)
                .accessibilityLabel(viewModel.midiPlayer?.isLooping ?? false ? "Disable Loop" : "Enable Loop")
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in loopIsPressed = true }
                        .onEnded { _ in loopIsPressed = false }
                )
                .padding()
            }
        }
        .border(.primary, width: 1)
        .padding()
    }

    private var playButtonIcon: String {
        switch viewModel.midiPlayer?.playbackState {
        case .playing: return "pause.fill"
        case .paused, .stopped, .none: return "play.fill"
        }
    }

    private func togglePlayback() {
        switch viewModel.midiPlayer?.playbackState {
        case .stopped, .paused, .none:
            viewModel.play(modelContext: modelContext)
        case .playing:
            viewModel.pause()
        }
    }
}
