import SwiftUI

struct LectureDetailView: View {
    @StateObject private var viewModel: LectureDetailViewModel
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false

    init(viewModel: LectureDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                titleField
                Text(viewModel.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                playbackButtons

                transcriptSection
                exportSection

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Lecture Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
    }

    private var titleField: some View {
        TextField("Title", text: Binding(
            get: { viewModel.titleText },
            set: { viewModel.updateTitle($0) }
        ))
        .font(.title2.weight(.semibold))
        .textFieldStyle(.roundedBorder)
    }

    private var playbackButtons: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.togglePlayback) {
                Label(viewModel.isPlaying ? "Stop Audio" : "Play Audio", systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(viewModel.isPlaying ? "Stop audio playback" : "Play audio")
            .accessibilityHint("Plays the recorded lecture audio")

            Button(action: viewModel.transcribe) {
                if viewModel.isTranscribing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Transcribe", systemImage: "waveform")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isTranscribing)
            .accessibilityLabel("Transcribe recording")
            .accessibilityHint("Converts the audio to text")
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript")
                .font(.headline)

            TextEditor(text: Binding(
                get: { viewModel.transcriptText },
                set: { viewModel.updateTranscript($0) }
            ))
            .frame(minHeight: 240)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3))
            )
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(.headline)

            Button {
                if let items = viewModel.transcriptShareItems() {
                    shareItems = items
                    showingShareSheet = true
                }
            } label: {
                Label("Share transcript…", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canShareTranscript)
            .accessibilityHint("Shares the transcript text")

            Button {
                if let items = viewModel.audioShareItems() {
                    shareItems = items
                    showingShareSheet = true
                }
            } label: {
                Label("Share audio…", systemImage: "music.note.list")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canShareAudio)
            .accessibilityHint("Shares the recorded audio file")

            Button {
                Task {
                    if let url = await viewModel.pdfShareURL() {
                        shareItems = [url]
                        showingShareSheet = true
                    }
                }
            } label: {
                if viewModel.isExportingPDF {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Export as PDF", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isExportingPDF)
            .accessibilityHint("Exports the transcript as a PDF file")

            studyHelpersSection
        }
    }

    private var studyHelpersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study helpers")
                .font(.headline)

            Button("Generate summary & key points") {
                viewModel.generateSummary()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isSummarizing || !viewModel.canGenerateSummary)
            .accessibilityHint("Creates a quick study summary from the transcript")

            if viewModel.isSummarizing {
                ProgressView("Summarizing…")
            }

            if let result = viewModel.summaryResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                    Text(result.summary)
                        .font(.body)

                    if !result.keyPoints.isEmpty {
                        Text("Key points")
                            .font(.headline)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(result.keyPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                    Text(point)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }

            if let error = viewModel.summaryErrorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
        }
    }
}

#Preview {
    let sampleNote = LectureNote(
        id: UUID(),
        title: "Lecture – Jan 20, 2025",
        date: Date(),
        audioFilePath: "Recording.m4a",
        transcriptText: "Sample text"
    )
    let transcription = TranscriptionService()
    return NavigationStack {
        LectureDetailView(
            viewModel: LectureDetailViewModel(
                note: sampleNote,
                transcriptionService: transcription,
                summaryService: HeuristicSummaryService(),
                pdfExporter: PDFExporter(),
                persistNote: { _ in }
            )
        )
    }
}
