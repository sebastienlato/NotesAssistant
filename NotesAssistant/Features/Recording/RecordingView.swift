import SwiftUI

struct RecordingView: View {
    @ObservedObject private var lectureListViewModel: LectureListViewModel
    @StateObject private var viewModel: RecordingViewModel
    private let onNoteCreated: (LectureNote) -> Void

    init(audioRecorder: AudioRecording, lectureListViewModel: LectureListViewModel, onNoteCreated: @escaping (LectureNote) -> Void) {
        self._viewModel = StateObject(wrappedValue: RecordingViewModel(audioRecorder: audioRecorder, micMonitor: MicLevelMonitor()))
        self._lectureListViewModel = ObservedObject(wrappedValue: lectureListViewModel)
        self.onNoteCreated = onNoteCreated
    }

var body: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.9), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                RecordingHeader()
                    .padding(.top, 16)

                WaveformView(level: CGFloat(viewModel.micLevel))
                    .frame(height: 220)
                    .padding(.horizontal, 24)

                Text(viewModel.elapsedTimeString)
                    .font(.system(size: 48, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    ForEach(0..<12, id: \.self) { index in
                        MicLevelBar(level: CGFloat(viewModel.micLevel) * CGFloat.random(in: 0.6...1.2))
                    }
                }
                .frame(height: 40)
                .padding(.horizontal, 36)

                Spacer()

                RecordButton(isRecording: viewModel.isRecording) {
                    viewModel.toggleRecording()
                }
                .accessibilityLabel(viewModel.isRecording ? "Stop recording" : "Start recording")
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Recording")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.pauseTimerOnDisappear() }
        .onChange(of: viewModel.completedRecording) { _, recording in
            guard let recording else { return }
            Task { @MainActor in
                await handleCompletedRecording(recording)
            }
        }
        .overlay(alignment: .top) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
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
