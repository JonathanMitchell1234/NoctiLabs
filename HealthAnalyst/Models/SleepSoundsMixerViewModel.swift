//
//  SleepSoundsMixerViewModel.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/19/25.
//

import SwiftUI
import AVFoundation

class SleepSoundsMixerViewModel: ObservableObject {
    // Sound options
    let soundNames = ["Rain", "Ocean Waves", "Forest", "Wind Chimes", "Fireplace", "White Noise"]
    let soundFileNames = ["RainAndThunderSleepSounds", "GentleBrook", "forest", "wind_chimes", "firesounds", "white_noise"]
    let soundIcons = ["cloud.rain", "wave.3.right", "leaf", "wind", "flame", "waveform"]

    // Published properties
    @Published var volumes: [Float]
    @Published var isExpanded = false

    // Audio players
    var audioPlayers: [AVAudioPlayer?]

    init() {
        // Initialize volumes and audio players
        self.volumes = Array(repeating: 0.5, count: soundNames.count)
        self.audioPlayers = Array(repeating: nil, count: soundNames.count)

        // Load sounds
        loadSounds()

        // Observe audio session interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit {
        // Remove observer on deinitialization
        NotificationCenter.default.removeObserver(self)
    }

    func loadSounds() {
        do {
            // Configure audio session for background playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }

        for index in 0..<soundFileNames.count {
            if let url = Bundle.main.url(forResource: soundFileNames[index], withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.numberOfLoops = -1
                    player.volume = volumes[index]
                    audioPlayers[index] = player
                } catch {
                    print("Error loading \(soundFileNames[index]): \(error)")
                }
            } else {
                print("Sound file \(soundFileNames[index]).mp3 not found.")
            }
        }
    }

    func playSound(at index: Int) {
        audioPlayers[index]?.volume = volumes[index]
        audioPlayers[index]?.play()
    }

    func stopSound(at index: Int) {
        audioPlayers[index]?.stop()
    }

    func stopAllSounds() {
        for player in audioPlayers.compactMap({ $0 }) {
            player.stop()
        }
    }

    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            // Audio interruption began, pause playback
            for player in audioPlayers.compactMap({ $0 }) {
                if player.isPlaying {
                    player.pause()
                }
            }
        } else if type == .ended {
            // Audio interruption ended, resume playback if appropriate
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        // Resume playback
                        for player in audioPlayers.compactMap({ $0 }) {
                            player.play()
                        }
                    }
                }
            } catch {
                print("Failed to reactivate audio session: \(error)")
            }
        }
    }
}
