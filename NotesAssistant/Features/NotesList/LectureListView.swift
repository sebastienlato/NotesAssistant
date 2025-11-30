import SwiftUI

private enum LectureRoute: Hashable {
    case recording
    case detail(LectureNote)
}

struct LectureListView: View {
    @StateObject private var viewModel: LectureListViewModel
    private let audioRecorder: AudioRecording
    private let transcriptionService: Transcribing
    private let summaryService: any Summarizing

    @State private var path: [LectureRoute] = []

    init(viewModel: LectureListViewModel, audioRecorder: AudioRecording, transcriptionService: Transcribing, summaryService: any Summarizing) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.audioRecorder = audioRecorder
        self.transcriptionService = transcriptionService
        self.summaryService = summaryService
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(colors: [AppColors.primaryBlue.opacity(0.9), Color.black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        tagline
                            .padding(.top, 4)

                        filterCard

                        if viewModel.notes.isEmpty {
                            emptyState
                        } else if viewModel.filteredNotes.isEmpty {
                            noResultsState
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredNotes) { note in
                                    NavigationLink(value: LectureRoute.detail(note)) {
                                        LectureCard(note: note)
                                            .accessibilityLabel("Lecture titled \(note.title), recorded on \(LectureCard.dateFormatter.string(from: note.date))")
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                                .onDelete { offsets in
                                    Task { await viewModel.deleteNotes(at: offsets) }
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: viewModel.filteredNotes)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
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
                            summaryService: summaryService,
                            pdfExporter: PDFExporter(),
                            persistNote: { updated in
                                await viewModel.persist(note: updated)
                            }
                        )
                    )
                }
            }
        }
        .navigationTitle("Lecture Notes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.impact(.medium)
                    path.append(.recording)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New Recording")
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search titles")
    }

    private var filterCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Filter")
                    .font(.subheadline.weight(.semibold))
                Text("Only notes with transcript")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $viewModel.showOnlyWithTranscript)
                .labelsHidden()
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(16)
        .padding(.horizontal)
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

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No results")
                .font(.headline)
            Text("Try a different title or clear filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tagline: some View {
        Text("Tap + to record your next class")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LectureCard: View {
    let note: LectureNote

    fileprivate static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.accentBlue.opacity(0.2))
                    .frame(width: 42, height: 42)
                Text(String(note.title.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundColor(AppColors.accentBlue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(Self.dateFormatter.string(from: note.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let transcript = note.transcriptText, !transcript.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(AppColors.accentBlue)
                        Text(transcript)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(AppColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    let store = FileLectureStore()
    let vm = LectureListViewModel(lectureStore: store)
    return LectureListView(
        viewModel: vm,
        audioRecorder: AudioRecorderService(),
        transcriptionService: TranscriptionService(),
        summaryService: HeuristicSummaryService()
    )
}
