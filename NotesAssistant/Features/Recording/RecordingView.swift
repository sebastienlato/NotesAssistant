import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel: RecordingViewModel
    private let transcriptionService: Transcribing

    init(audioRecorder: AudioRecording, transcriptionService: Transcribing) {
        _viewModel = StateObject(wrappedValue: RecordingViewModel(audioRecorder: audioRecorder))
        self.transcriptionService = transcriptionService
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Text(viewModel.elapsedTimeString)
                    .font(.system(size: 48, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .padding(.bottom, 16)
                Button(action: viewModel.toggleRecording) {
                    Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isRecording ? Color.red : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Recording")
            .navigationDestination(item: $viewModel.completedRecording) { recording in
                TranscriptionView(
                    viewModel: TranscriptionViewModel(
                        audioURL: recording.fileURL,
                        transcriptionService: transcriptionService
                    )
                )
                .onDisappear {
                    viewModel.clearCompletedRecording()
                }
            }
        }
        .onAppear { viewModel.onAppear() }
    }
}

#Preview {
    RecordingView(
        audioRecorder: AudioRecorderService(),
        transcriptionService: TranscriptionService()
    )
}
