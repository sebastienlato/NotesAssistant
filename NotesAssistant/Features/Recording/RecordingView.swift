import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var lectureListViewModel: LectureListViewModel
    @StateObject private var viewModel: RecordingViewModel
    private let onNoteCreated: (LectureNote) -> Void
    @State private var noiseReduction = false

    init(audioRecorder: AudioRecording, lectureListViewModel: LectureListViewModel, onNoteCreated: @escaping (LectureNote) -> Void) {
        self._viewModel = StateObject(wrappedValue: RecordingViewModel(audioRecorder: audioRecorder, micMonitor: MicLevelMonitor()))
        self._lectureListViewModel = ObservedObject(wrappedValue: lectureListViewModel)
        self.onNoteCreated = onNoteCreated
    }

var body: some View {
        ZStack {
            LinearGradient(colors: [.black, AppColors.primaryBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                header
                    .padding(.top, 12)

                WaveformView(level: CGFloat(max(viewModel.micLevel, 0.05)))
                    .frame(height: 200)
                    .padding(.horizontal, 24)

                Text(viewModel.elapsedTimeString)
                    .font(.system(size: 52, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                controlRow
                    .padding(.horizontal, 24)

                HStack(spacing: 6) {
                    ForEach(0..<12, id: \.self) { _ in
                        MicLevelBar(level: CGFloat(max(viewModel.micLevel, 0.05)))
                    }
                }
                .frame(height: 48)
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
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

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.white)
                        )
                }
                Spacer()
                VStack(spacing: 4) {
                    Text("Recording")
                        .font(.headline)
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(viewModel.isRecording ? "Recording" : "Ready")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                Spacer()
                // spacer to balance layout
                Circle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private var controlRow: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "wind")
                    .foregroundStyle(.white.opacity(0.8))
                Text("Noise reduction")
                    .foregroundStyle(.white)
                Image(systemName: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Toggle("", isOn: $noiseReduction)
                .labelsHidden()
        }
        .padding()
        .background(AppColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(14)
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
