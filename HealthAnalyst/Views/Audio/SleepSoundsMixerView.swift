import SwiftUI
import AVFoundation

struct SleepSoundsMixerView: View {
    @StateObject private var viewModel = SleepSoundsMixerViewModel()

    var body: some View {
        VStack {
            if viewModel.isExpanded {
                expandedMixerView
            } else {
                miniMixerView
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var miniMixerView: some View {
        HStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 40)
                .cornerRadius(6)
                .foregroundColor(.blue)

            Text("Sleep Sounds Mixer")
                .font(.headline)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring()) {
                        viewModel.isExpanded = true
                    }
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemGray6))
        )
        .padding(.horizontal, 14)
        .onTapGesture {
            withAnimation(.spring()) {
                viewModel.isExpanded = true
            }
        }
    }

    private var expandedMixerView: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        viewModel.isExpanded = false
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding()
                }
            }

            Text("Sleep Sounds Mixer")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 18, weight: .medium))
                .fontWeight(.bold)
                .padding(.top, -20)

            ForEach(0..<viewModel.soundNames.count, id: \.self) { index in
                HStack {
                    Toggle(isOn: Binding(
                        get: { viewModel.audioPlayers[index]?.isPlaying ?? false },
                        set: { isOn in
                            if isOn {
                                viewModel.playSound(at: index)
                            } else {
                                viewModel.stopSound(at: index)
                            }
                        }
                    )) {
                        Label(viewModel.soundNames[index], systemImage: viewModel.soundIcons[index])
                            .font(.headline)
                    }

                    Slider(value: Binding(
                        get: { Double(viewModel.volumes[index]) },
                        set: { newValue in
                            viewModel.volumes[index] = Float(newValue)
                            viewModel.audioPlayers[index]?.volume = viewModel.volumes[index]
                        }
                    ), in: 0...1)
                }
                .padding(.horizontal)
            }

            Button(action: viewModel.stopAllSounds) {
                Text("Stop All Sounds")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(uiColor: .systemGray5))
                    )
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.bottom)
        .padding(.top, 1)
    }
}
