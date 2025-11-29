import SwiftUI

private enum LectureRoute: Hashable {
    case recording
    case detail(LectureNote)
}

struct LectureListView: View {
    @StateObject private var viewModel: LectureListViewModel
    private let audioRecorder: AudioRecording
    private let transcriptionService: Transcribing

    @State private var path: [LectureRoute] = []

    init(viewModel: LectureListViewModel, audioRecorder: AudioRecording, transcriptionService: Transcribing) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.audioRecorder = audioRecorder
        self.transcriptionService = transcriptionService
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.notes.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.notes) { note in
                            NavigationLink(value: LectureRoute.detail(note)) {
                                LectureRow(note: note)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Lecture Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { path.append(.recording) }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Recording")
                }
            }
            .overlay(alignment: .bottom) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                }
            }
            .navigationDestination(for: LectureRoute.self) { route in
                switch route {
                case .recording:
                    RecordingView(
                        audioRecorder: audioRecorder,
                        lectureListViewModel: viewModel,
                        onNoteCreated: { note in
                            if path.last == .recording {
                                path.removeLast()
                            }
                            path.append(.detail(note))
                        }
                    )
                case .detail(let note):
                    LectureDetailView(
                        viewModel: LectureDetailViewModel(
                            note: note,
                            transcriptionService: transcriptionService,
                            pdfExporter: PDFExporter(),
                            persistNote: { updated in
                                await viewModel.persist(note: updated)
                            }
                        )
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No lectures yet")
                .font(.headline)
            Text("Tap the + button to start recording your first lecture.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LectureRow: View {
    let note: LectureNote

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
            Text(Self.dateFormatter.string(from: note.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let transcript = note.transcriptText, !transcript.isEmpty {
                Text(transcript)
                    .font(.footnote)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let store = FileLectureStore()
    let vm = LectureListViewModel(lectureStore: store)
    return LectureListView(
        viewModel: vm,
        audioRecorder: AudioRecorderService(),
        transcriptionService: TranscriptionService()
    )
}
