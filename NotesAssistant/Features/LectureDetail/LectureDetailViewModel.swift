import AVFoundation
import Combine
import Foundation

@MainActor
final class LectureDetailViewModel: NSObject, ObservableObject {
    @Published var titleText: String
    @Published var transcriptText: String
    @Published var isPlaying = false
    @Published var isTranscribing = false
    @Published var isExportingPDF = false
    @Published var isSummarizing = false
    @Published var errorMessage: String?
    @Published var summaryResult: SummaryResult?
    @Published var summaryErrorMessage: String?
    @Published var isShareSheetPresented = false
    @Published var shareURL: URL?

    private(set) var note: LectureNote

    private let transcriptionService: Transcribing
    private let summaryService: any Summarizing
    private let persistNote: @Sendable (LectureNote) async -> Void
    private let pdfExporter: PDFExporting
    private let documentsDirectory: URL
    private var audioPlayer: AVAudioPlayer?
    private var autosaveTask: Task<Void, Never>?

    init(note: LectureNote, transcriptionService: Transcribing, summaryService: any Summarizing, pdfExporter: PDFExporting, persistNote: @escaping @Sendable (LectureNote) async -> Void) {
        self.note = note
        self.transcriptionService = transcriptionService
        self.summaryService = summaryService
        self.persistNote = persistNote
        self.pdfExporter = pdfExporter
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.titleText = note.title
        self.transcriptText = note.transcriptText ?? ""
        super.init()
    }

    deinit {
        autosaveTask?.cancel()
        audioPlayer?.stop()
    }

    var formattedDate: String {
        Self.dateFormatter.string(from: note.date)
    }

    var audioURL: URL {
        documentsDirectory.appendingPathComponent(note.audioFilePath)
    }

    var canShareTranscript: Bool {
        !transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canShareAudio: Bool {
        FileManager.default.fileExists(atPath: audioURL.path)
    }

    var canGenerateSummary: Bool {
        !(note.transcriptText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func updateTitle(_ text: String) {
        titleText = text
        note.title = text
        scheduleAutosave()
    }

    func updateTranscript(_ text: String) {
        transcriptText = text
        note.transcriptText = text.isEmpty ? nil : text
        summaryResult = nil
        scheduleAutosave()
    }

    func shareTranscript() {
        let text = transcriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            errorMessage = "Transcript is empty."
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await self.makeTranscriptFileURL(text: text)
                await self.presentShareSheet(url: url)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not prepare transcript. Please try again."
                }
            }
        }
    }

    func shareAudio() {
        guard canShareAudio else {
            errorMessage = "Audio file is missing."
            return
        }
        let url = audioURL
        Task { [weak self] in
            await self?.presentShareSheet(url: url)
        }
    }

    func sharePDF() {
        let text = transcriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            errorMessage = "Transcript is empty."
            return
        }
        isExportingPDF = true
        Task { [weak self] in
            guard let self else { return }
            let titleLine = titleText.isEmpty ? note.title : titleText
            do {
                let url = try self.pdfExporter.exportPDF(title: titleLine, date: self.note.date, transcript: text)
                await self.presentShareSheet(url: url)
            } catch {
                await MainActor.run { self.errorMessage = "Could not create PDF. Please try again." }
            }
            await MainActor.run { self.isExportingPDF = false }
        }
    }

    func generateSummary() {
        guard canGenerateSummary else {
            summaryErrorMessage = "You need a transcript before generating a summary."
            return
        }

        isSummarizing = true
        summaryErrorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                let transcript = note.transcriptText ?? ""
                let result = try await summaryService.summarize(text: transcript)
                await MainActor.run {
                    self.summaryResult = result
                    self.isSummarizing = false
                }
            } catch {
                await MainActor.run {
                    self.summaryErrorMessage = "Could not generate a summary right now. Please try again."
                    self.isSummarizing = false
                }
            }
        }
    }

    func transcribe() {
        guard !isTranscribing else { return }
        isTranscribing = true
        errorMessage = nil
        let url = audioURL

        Task { [weak self] in
            guard let self else { return }
            do {
                let transcript = try await self.transcriptionService.transcribeAudio(at: url)
                await MainActor.run {
                    self.note.transcriptText = transcript.fullText
                    self.transcriptText = transcript.fullText
                    self.summaryResult = nil
                }
                await self.persistCurrentNote()
            } catch {
                await MainActor.run { self.errorMessage = "Could not transcribe recording. Please try again." }
            }
            await MainActor.run { self.isTranscribing = false }
        }
    }

    func togglePlayback() {
        if isPlaying {
            stopAudio()
        } else {
            startAudio()
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    private func startAudio() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            errorMessage = "Unable to play audio."
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard let self else { return }
            await self.persistCurrentNote()
        }
    }

    private func persistCurrentNote() async {
        await persistNote(note)
    }

    private func makeTranscriptFileURL(text: String) async throws -> URL {
        let titleLine = titleText.isEmpty ? note.title : titleText
        let exportText = "\(titleLine)\n\n\(text)"
        return try await Task.detached(priority: .utility) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Transcript-\(UUID().uuidString).txt")
            try exportText.write(to: url, atomically: true, encoding: .utf8)
            return url
        }.value
    }

    private func presentShareSheet(url: URL) async {
        await MainActor.run { self.shareURL = url }
        DispatchQueue.main.async { [weak self] in
            self?.isShareSheetPresented = true
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension LectureDetailViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        audioPlayer = nil
    }
}
