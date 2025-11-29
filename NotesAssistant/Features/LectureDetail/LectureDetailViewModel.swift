import AVFoundation
import Combine
import Foundation

@MainActor
final class LectureDetailViewModel: NSObject, ObservableObject {
    @Published var titleText: String
    @Published var transcriptText: String
    @Published var isPlaying = false
    @Published var isTranscribing = false
    @Published var errorMessage: String?

    private(set) var note: LectureNote

    private let transcriptionService: Transcribing
    private let persistNote: @Sendable (LectureNote) async -> Void
    private let documentsDirectory: URL
    private var audioPlayer: AVAudioPlayer?
    private var autosaveTask: Task<Void, Never>?

    init(note: LectureNote, transcriptionService: Transcribing, persistNote: @escaping @Sendable (LectureNote) async -> Void) {
        self.note = note
        self.transcriptionService = transcriptionService
        self.persistNote = persistNote
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

    func updateTitle(_ text: String) {
        titleText = text
        note.title = text
        scheduleAutosave()
    }

    func updateTranscript(_ text: String) {
        transcriptText = text
        note.transcriptText = text.isEmpty ? nil : text
        scheduleAutosave()
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
                }
                await self.persistCurrentNote()
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription }
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
