import SwiftUI
import AVFoundation
import AVKit
import MediaPlayer

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let fileName: String
    let fileExtension: String
    let imageName: String?
}

struct AudioPlayerView: View {
    @StateObject private var viewModel = AudioPlayerViewModel()
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if isExpanded {
                expandedPlayer
            } else {
                miniPlayer
            }
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            viewModel.setupAudio()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private var miniPlayer: some View {
        HStack(spacing: 16) {
            if let imageName = viewModel.currentTrack?.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentTrack?.title ?? "No Track Selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(viewModel.currentTrack?.artist ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.togglePlayback()
                    withAnimation(.spring()) {
                        isExpanded = true
                    }
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    viewModel.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(
                RoundedRectangle(cornerRadius: 12) // Adjust the corner radius as needed
                    .fill(Color(uiColor: .systemGray6)) // Ensure the background color matches the original
            )
        .padding(.horizontal, 14)
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded = true
            }
        }
    }
    
    private var expandedPlayer: some View {
        ScrollView {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded = false
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .padding()
                    }
                }
                
                if let imageName = viewModel.currentTrack?.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 250)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 350, height: 350)
                        .cornerRadius(10)
                        .overlay(Text("No Image").foregroundColor(.gray))
                        .shadow(radius: 10)
                }

                Spacer()
                    .frame(height: 20)

                VStack(spacing: 4) {
                    Text(viewModel.currentTrack?.title ?? "No Track Selected")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(viewModel.currentTrack?.artist ?? "")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
                    .frame(height: 20)

                VStack(spacing: 5) {
                    Slider(value: $viewModel.progress, in: 0...1, onEditingChanged: { editing in
                        if !editing {
                            viewModel.seekToPosition()
                        }
                    })
                    .accentColor(.primary)

                    HStack {
                        Text(viewModel.currentTimeString)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(viewModel.durationString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                Spacer()
                    .frame(height: 20)

                ZStack {
                    HStack(spacing: 50) {
                        Button(action: {
                            viewModel.previousTrack()
                        }) {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.primary)
                        }

                        Button(action: {
                            viewModel.togglePlayback()
                        }) {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 45))
                                .foregroundColor(.primary)
                        }

                        Button(action: {
                            viewModel.nextTrack()
                        }) {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.primary)
                        }
                    }

                    HStack {
                        Spacer()
                        RoutePickerView()
                            .frame(width: 40, height: 40)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Playlist")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(viewModel.playlist) { track in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(track.title)
                                    .font(.subheadline)
                                Text(track.artist)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if track.id == viewModel.currentTrack?.id {
                                Image(systemName: "music.note")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(track.id == viewModel.currentTrack?.id ? Color.gray.opacity(0.2) : Color.clear)
                        )
                        .onTapGesture {
                            viewModel.playTrack(track)
                        }
                    }
                }
                .padding()
            }
            .padding()
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(20)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 1)
        }
    }
}

struct RoutePickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.prioritizesVideoDevices = false
        return routePickerView
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
    }
}

class AudioPlayerViewModel: ObservableObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var nowPlayingInfo: [String: Any] = [:]
    
    @Published var isPlaying = false
    @Published var currentTimeString = "0:00"
    @Published var durationString = "0:00"
    @Published var progress: Double = 0.0
    @Published var currentTrack: Track?
    @Published var playlist: [Track] = []
    
    init() {
        setupPlaylist()
        setupRemoteTransportControls()
    }
    
    private func setupPlaylist() {
        playlist = [
            Track(title: "Rain and Thunder", artist: "Nature Sounds", fileName: "RainAndThunderSleepSounds", fileExtension: "mp3", imageName: "rain_and_thunder_image"),
            Track(title: "Gentle Brook", artist: "Nature Sounds", fileName: "GentleBrook", fileExtension: "mp3", imageName: "Stream"),
            Track(title: "Forest Birds", artist: "Nature Sounds", fileName: "ForestBirds", fileExtension: "mp3", imageName: "forest_birds_image")
        ]
        currentTrack = playlist.first
    }
    
    func setupAudio() {
        guard let track = currentTrack else { return }
        loadTrack(track)
    }
    
    private func loadTrack(_ track: Track) {
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
            print("Audio file not found")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            
            if let duration = player?.duration {
                durationString = formatTime(duration)
            }
            
            setupNowPlayingInfo()
            startTimer()
        } catch {
            print("Error initializing player: \(error.localizedDescription)")
        }
    }
    
    func playTrack(_ track: Track) {
        player?.stop()
        currentTrack = track
        loadTrack(track)
        player?.play()
        isPlaying = true
        updateNowPlayingInfoPlaybackState()
    }
    
    func nextTrack() {
        guard let currentTrack = currentTrack,
              let currentIndex = playlist.firstIndex(where: { $0.id == currentTrack.id }),
              currentIndex + 1 < playlist.count else { return }
        
        let nextTrack = playlist[currentIndex + 1]
        playTrack(nextTrack)
    }
    
    func previousTrack() {
        guard let currentTrack = currentTrack,
              let currentIndex = playlist.firstIndex(where: { $0.id == currentTrack.id }),
              currentIndex > 0 else { return }
        
        let previousTrack = playlist[currentIndex - 1]
        playTrack(previousTrack)
    }
    
    func togglePlayback() {
        guard let player = player else { return }
        
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        isPlaying = player.isPlaying
        updateNowPlayingInfoPlaybackState()
    }
    
    func seekToPosition() {
        guard let player = player else { return }
        player.currentTime = player.duration * progress
        updateNowPlayingInfoCurrentTime()
    }
    
    func fastForward() {
        guard let player = player else { return }
        let newTime = min(player.duration, player.currentTime + 15)
        player.currentTime = newTime
        updateProgress()
        updateNowPlayingInfoCurrentTime()
    }
    
    func rewind() {
        guard let player = player else { return }
        let newTime = max(0, player.currentTime - 15)
        player.currentTime = newTime
        updateProgress()
        updateNowPlayingInfoCurrentTime()
    }
    
    private func updateProgress() {
        guard let player = player else { return }
        progress = player.currentTime / player.duration
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            
            self.progress = player.currentTime / player.duration
            self.currentTimeString = self.formatTime(player.currentTime)
            
            if player.currentTime >= player.duration {
                self.audioDidFinishPlaying()
            }
        }
    }
    
    private func audioDidFinishPlaying() {
        isPlaying = false
        progress = 0
        currentTimeString = "0:00"
        player?.currentTime = 0
        timer?.invalidate()
        startTimer()
        nextTrack()
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(self)
        commandCenter.pauseCommand.removeTarget(self)
        commandCenter.nextTrackCommand.removeTarget(self)
        commandCenter.previousTrackCommand.removeTarget(self)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isPlaying {
                self.togglePlayback()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.isPlaying {
                self.togglePlayback()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.previousTrack()
            return .success
        }
    }
    
    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String : Any]()
        
        if let currentTrack = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = currentTrack.artist

            if let imageName = currentTrack.imageName, let image = UIImage(named: imageName) {
                nowPlayingInfo[MPMediaItemPropertyArtwork] =
                    MPMediaItemArtwork(boundsSize: image.size) { size in
                        return image
                    }
            }
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player?.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingInfoPlaybackState() {
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingInfoCurrentTime() {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

#Preview {
    AudioPlayerView()
}
