import Combine
import Foundation

@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var transcriptText: String = ""
    @Published var isTranscribing = false
    @Published var errorMessage: String?

    let audioURL: URL

    private let transcriptionService: Transcribing

    init(audioURL: URL, transcriptionService: Transcribing) {
        self.audioURL = audioURL
        self.transcriptionService = transcriptionService
    }

    func transcribe() {
        guard !isTranscribing else { return }
        isTranscribing = true
        errorMessage = nil

        Task {
            do {
                let transcript = try await transcriptionService.transcribeAudio(at: audioURL)
                transcriptText = transcript.fullText
            } catch {
                errorMessage = error.localizedDescription
            }
            isTranscribing = false
        }
    }
}
