import SwiftUI
import AVFoundation

struct ActivityDashboardView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    
    var body: some View {
        NavigationStack {
            VStack {
                if audioRecorder.isRecording {
                    Text("Recording...")
                        .font(.headline)
                        .padding()
                    
                    Button(action: {
                        audioRecorder.stopRecording()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                } else {
                    Button(action: {
                        audioRecorder.requestPermissionAndRecord()
                    }) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                }
                
                List {
                    ForEach(audioRecorder.recordings, id: \.createdAt) { recording in
                        RecordingRow(recording: recording) {
                            audioRecorder.deleteRecording(url: recording.fileURL)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(CarouselListStyle())
            }
            .navigationTitle("Dream Recorder")
        }
    }
}
