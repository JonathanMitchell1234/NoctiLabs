//
//  AudioPlayerView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/15/25.
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    @StateObject private var viewModel = AudioPlayerViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // Track Name
            Text(viewModel.trackName)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            // Track Image
            if let imageName = viewModel.trackImageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(Text("No Image").foregroundColor(.gray))
            }
            
            // Current Time and Duration
            HStack {
                Text(viewModel.currentTimeString)
                    .font(.caption)
                Spacer()
                Text(viewModel.durationString)
                    .font(.caption)
            }
            
            // Slider for Scrubbing
            Slider(value: $viewModel.progress, in: 0...1, onEditingChanged: { isEditing in
                if !isEditing {
                    viewModel.seekToPosition()
                }
            })
            
            // Play/Pause Button
            Button(action: {
                viewModel.togglePlayback()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .onAppear {
            viewModel.setupAudio()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .frame(maxWidth: .infinity)
    }
}

class AudioPlayerViewModel: ObservableObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    @Published var isPlaying = false
    @Published var currentTimeString = "0:00"
    @Published var durationString = "0:00"
    @Published var progress: Double = 0.0
    @Published var trackName: String = "Unknown Track"
    @Published var trackImageName: String? // Holds the name of the image file
    
    func setupAudio() {
        // Configure the track metadata
        trackName = "Rain and Thunder"
        trackImageName = "rain_and_thunder_image" // Ensure this image is in your Assets folder
        
        // Load the audio file
        guard let url = Bundle.main.url(forResource: "RainAndThunderSleepSounds", withExtension: "mp3") else {
            print("Audio file not found")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            
            if let duration = player?.duration {
                durationString = formatTime(duration)
            }
            
            startTimer()
        } catch {
            print("Error initializing player: \(error.localizedDescription)")
        }
    }
    
    func togglePlayback() {
        guard let player = player else { return }
        
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        isPlaying = player.isPlaying
    }
    
    func seekToPosition() {
        guard let player = player else { return }
        player.currentTime = player.duration * progress
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let player = self.player else { return }
            
            self.progress = player.currentTime / player.duration
            self.currentTimeString = self.formatTime(player.currentTime)
        }
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

