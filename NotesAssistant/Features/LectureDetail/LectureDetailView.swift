import SwiftUI

struct LectureDetailView: View {
    @StateObject private var viewModel: LectureDetailViewModel
    @State private var selectedSection: DetailSection = .transcript

    init(viewModel: LectureDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                titleField
                Text(viewModel.formattedDate)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker("Section", selection: $selectedSection) {
                    ForEach(DetailSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)

                sectionContent

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
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            if let url = viewModel.shareURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    private var titleField: some View {
        TextField("Title", text: Binding(
            get: { viewModel.titleText },
            set: { viewModel.updateTitle($0) }
        ))
        .font(.title3.weight(.semibold))
        .padding(10)
        .background(AppColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(10)
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
        VStack(alignment: .leading, spacing: 12) {
            playbackButtons

            VStack(alignment: .leading, spacing: 8) {
                Text("Transcript")
                    .font(.headline)
                TextEditor(text: Binding(
                    get: { viewModel.transcriptText },
                    set: { viewModel.updateTranscript($0) }
                ))
                .frame(minHeight: 240)
                .padding(8)
                .background(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
                .cornerRadius(10)
                if viewModel.summaryResult != nil {
                    Text("Summary available in Study tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(.headline)

            Button {
                viewModel.shareTranscript()
            } label: {
                Label("Share transcript…", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canShareTranscript)
            .accessibilityHint("Shares the transcript text")

            Button {
                viewModel.shareAudio()
            } label: {
                Label("Share audio…", systemImage: "music.note.list")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canShareAudio)
            .accessibilityHint("Shares the recorded audio file")

            Button {
                viewModel.sharePDF()
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
        }
        .padding()
        .background(AppColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var studyHelpersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study helpers")
                .font(.headline)

            Button {
                Task {
                    await MainActor.run {
                        viewModel.generateSummary()
                    }
                }
            } label: {
                HStack {
                    Text("Generate summary & key points")
                        .font(.headline)
                        .foregroundStyle(AppColors.accentBlue)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
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
        .padding()
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .transcript:
            transcriptSection
        case .study:
            studyHelpersCard
        case .export:
            exportSection
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
