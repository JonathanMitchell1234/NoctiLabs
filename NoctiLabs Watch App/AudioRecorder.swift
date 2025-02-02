//
//  AudioRecorder.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 2/1/25.
//

import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var recordings = [Recording]()
    
    var audioRecorder: AVAudioRecorder?
    
    override init() {
        super.init()
        fetchRecordings()
    }
    
    func requestPermissionAndRecord() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            startRecording()
        case .denied:
            // Handle the case where the user has denied microphone access
            print("Microphone access denied")
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startRecording()
                    } else {
                        // Handle the case where the user has denied microphone access
                        print("Microphone access denied")
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            let url = getFileURL()
            let settings = [
                AVFormatIDKey: Int(kAudioFormatAppleLossless),
                AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                AVEncoderBitRateKey: 320000,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0
            ] as [String : Any]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            
        } catch {
            print("Failed to record: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        fetchRecordings()
    }
    
    func fetchRecordings() {
        recordings.removeAll()
        
        let fileManager = FileManager.default
        guard let directory = getDirectory() else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files {
                recordings.append(Recording(fileURL: file))
            }
            recordings.sort(by: { $0.createdAt > $1.createdAt })
        } catch {
            print("Failed to fetch recordings: \(error.localizedDescription)")
        }
    }
    
    func deleteRecording(url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
            fetchRecordings()
        } catch {
            print("Failed to delete recording: \(error.localizedDescription)")
        }
    }
    
    private func getDirectory() -> URL? {
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return directory
    }
    
    private func getFileURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd-HHmmss"
        let filename = formatter.string(from: Date()) + ".m4a"
        
        if let directory = getDirectory() {
            return directory.appendingPathComponent(filename)
        } else {
            fatalError("Unable to access document directory")
        }
    }
}
