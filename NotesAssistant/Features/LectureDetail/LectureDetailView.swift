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
                pdfExporter: PDFExporter(),
                persistNote: { _ in }
            )
        )
    }
}
