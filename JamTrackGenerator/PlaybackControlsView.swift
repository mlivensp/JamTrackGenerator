import SwiftData
import SwiftUI

struct PlaybackControlsView: View {
    
    @State private var viewModel: ViewModel

    @State private var playIsPressed = false
    @State private var stopIsPressed = false
    @State private var loopIsPressed = false

    init(jamTrack: JamTrack, modelContext: ModelContext) {
        self._viewModel = .init(wrappedValue: .init(jamTrack: jamTrack, modelContext: modelContext))
    }
    
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
                .disabled(viewModel.isStopped)
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
                Button(action: { viewModel.toggleLooping() }) {
                    Image(systemName: viewModel.isLooping ? "repeat.1" : "repeat")
                        .font(.title3)
                        .foregroundStyle(viewModel.isLooping ? Color.accentColor : .primary)
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .scaleEffect(loopIsPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.2), value: loopIsPressed)
                .accessibilityLabel(viewModel.isLooping ? "Disable Loop" : "Enable Loop")
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
        if viewModel.isPlaying {
            return "pause.fill"
        } else {
            return "play.fill"
        }
    }

    private func togglePlayback() {
        do {
            try viewModel.togglePlayback()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
