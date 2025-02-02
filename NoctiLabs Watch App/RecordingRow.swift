//
//  RecordingRow.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 2/1/25.
//

import SwiftUI
import AVFoundation

struct RecordingRow: View {
    let recording: Recording
    let onDelete: () -> Void
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        HStack {
            Text(recording.createdAtFormatted)
                .font(.footnote)
            
            Spacer()
            
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            prepareAudioPlayer()
        }
    }
    
    func togglePlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        } else {
            do {
                // Set audio session category for playback
                try audioSession.setCategory(.playback, mode: .default)
                try audioSession.setActive(true)
                
                audioPlayer?.play()
                isPlaying = true
                audioPlayer?.delegate = audioPlayerDelegate
            } catch {
                print("Audio session activation failed: \(error.localizedDescription)")
            }
        }
    }

    
    func prepareAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.prepareToPlay()  // Add this line
        } catch {
            print("Failed to initialize audio player: \(error.localizedDescription)")
        }
    }

    
    var audioPlayerDelegate: AVAudioPlayerDelegate {
        AudioPlayerDelegate {
            self.isPlaying = false
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Audio session deactivation error: \(error.localizedDescription)")
            }
        }
    }

}

extension Recording {
    var createdAtFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: createdAt)
    }
}
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let didFinishPlaying: () -> Void
    
    init(didFinishPlaying: @escaping () -> Void) {
        self.didFinishPlaying = didFinishPlaying
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        didFinishPlaying()
    }
}
