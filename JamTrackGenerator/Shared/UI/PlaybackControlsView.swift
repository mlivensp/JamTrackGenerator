import SwiftData
import SwiftUI

enum ButtonSize {
    case small
    case large

    var playFont: Font {
        switch self {
        case .small: return .title3
        case .large: return .title
        }
    }

    var stopFont: Font {
        switch self {
        case .small: return .body
        case .large: return .title2
        }
    }

    var loopFont: Font {
        switch self {
        case .small: return .callout
        case .large: return .title3
        }
    }

    var playFrame: CGFloat {
        switch self {
        case .small: return 20
        case .large: return 30
        }
    }

    var stopFrame: CGFloat {
        switch self {
        case .small: return 20
        case .large: return 30
        }
    }

    var loopFrame: CGFloat {
        switch self {
        case .small: return 20
        case .large: return 30
        }
    }

    var loopPadding: CGFloat {
        switch self {
        case .small: return 6
        case .large: return 8
        }
    }
}

struct PlaybackControlsView: View {
    @State private var viewModel: ViewModel
    private let size: ButtonSize

    @State private var playIsPressed = false
    @State private var stopIsPressed = false
    @State private var loopIsPressed = false

    @State private var showingError = false
    @State private var errorMessage = ""

    init(size: ButtonSize, createURL: @escaping () -> URL?) {
        self._viewModel = .init(wrappedValue: ViewModel(createURL: createURL))
        self.size = size
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                // Play/Pause button
                Button(action: togglePlayback) {
                    Image(systemName: playButtonIcon)
                        .font(size.playFont)
                        .frame(width: size.playFrame, height: size.playFrame)
                        .foregroundStyle(.primary)
                        .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .scaleEffect(playIsPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.2), value: playIsPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in playIsPressed = true }
                        .onEnded { _ in playIsPressed = false }
                )

                // Stop button
                Button(action: { viewModel.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(size.stopFont)
                        .frame(width: size.stopFrame, height: size.stopFrame)
                        .foregroundStyle(.primary)
                        .accessibilityLabel("Stop")
                        .clipShape(Circle())
                }
                .disabled(viewModel.isStopped)
                .buttonStyle(.plain)
                .scaleEffect(stopIsPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.2), value: stopIsPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in stopIsPressed = true }
                        .onEnded { _ in stopIsPressed = false }
                )

                // Loop toggle
                Button(action: { viewModel.toggleLooping() }) {
                    Image(systemName: viewModel.isLooping ? "repeat.1" : "repeat")
                        .font(size.loopFont)
                        .foregroundStyle(viewModel.isLooping ? Color.accentColor : .primary)
                        .frame(width: size.loopFrame, height: size.loopFrame)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .scaleEffect(loopIsPressed ? 0.95 : 1.0)
                .animation(.easeOut(duration: 0.2), value: loopIsPressed)
                .accessibilityLabel(viewModel.isLooping ? "Disable Loop" : "Enable Loop")
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in loopIsPressed = true }
                        .onEnded { _ in loopIsPressed = false }
                )
            }
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("Playback Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    private var playButtonIcon: String {
        viewModel.isPlaying ? "pause.fill" : "play.fill"
    }

    private func togglePlayback() {
        Task {
            do {
                try await viewModel.togglePlayback()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: JamTrack.self, configurations: config)

    let jamTrack = JamTrack(name: "Test", style: nil, key: nil, feel: nil, bpm: 120, includeCountIn: true, jamTrackSections: [], parts: [], sectionPartPatterns: [])
    
    PlaybackControlsView(size: .large) {
        URL(string: "")!
    }
        .modelContainer(container)
    
    PlaybackControlsView(size: .small) {
        URL(string: "")!
    }
        .modelContainer(container)
}
