import SwiftUI

struct RecordingView: View {
    @ObservedObject private var lectureListViewModel: LectureListViewModel
    @StateObject private var viewModel: RecordingViewModel
    private let onNoteCreated: (LectureNote) -> Void

    init(audioRecorder: AudioRecording, lectureListViewModel: LectureListViewModel, onNoteCreated: @escaping (LectureNote) -> Void) {
        self._viewModel = StateObject(wrappedValue: RecordingViewModel(audioRecorder: audioRecorder))
        self._lectureListViewModel = ObservedObject(wrappedValue: lectureListViewModel)
        self.onNoteCreated = onNoteCreated
    }

    var body: some View {
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
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.pauseTimerOnDisappear() }
        .onChange(of: viewModel.completedRecording) { _, recording in
            guard let recording else { return }
            Task { @MainActor in
                await handleCompletedRecording(recording)
            }
        }
    }

    @MainActor
    private func handleCompletedRecording(_ recording: RecordingViewModel.RecordedAudio) async {
        do {
            let note = try await lectureListViewModel.addNote(for: recording.fileURL)
            viewModel.clearCompletedRecording()
            onNoteCreated(note)
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.clearCompletedRecording()
        }
    }
}

#Preview {
    let store = FileLectureStore()
    let listVM = LectureListViewModel(lectureStore: store)
    RecordingView(
        audioRecorder: AudioRecorderService(),
        lectureListViewModel: listVM,
        onNoteCreated: { _ in }
    )
}
