import Foundation
import Speech

protocol Transcribing {
    func transcribeAudio(at url: URL) async throws -> Transcript
}

enum TranscriptionError: LocalizedError {
    case authorizationDenied
    case recognizerUnavailable
    case emptyTranscription

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Speech recognition permission is required."
        case .recognizerUnavailable:
            return "Speech recognizer is currently unavailable."
        case .emptyTranscription:
            return "No transcription result was produced."
        }
    }
}

final class TranscriptionService: Transcribing {
    private let speechRecognizer: SFSpeechRecognizer?

    init(locale: Locale = Locale.current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale.identifier))
    }

    func transcribeAudio(at url: URL) async throws -> Transcript {
        guard try await ensureAuthorization() else {
            throw TranscriptionError.authorizationDenied
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = false

        return try await withCheckedThrowingContinuation { continuation in
            var recognitionTask: SFSpeechRecognitionTask?
            var hasCompleted = false

            recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                if hasCompleted {
                    return
                }

                if let error {
                    hasCompleted = true
                    recognitionTask?.cancel()
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else { return }

                if result.isFinal {
                    hasCompleted = true
                    recognitionTask?.cancel()
                    let text = result.bestTranscription.formattedString
                    if text.isEmpty {
                        continuation.resume(throwing: TranscriptionError.emptyTranscription)
                    } else {
                        continuation.resume(returning: Transcript(fullText: text))
                    }
                }
            }
        }
    }

    private func ensureAuthorization() async throws -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default:
            return false
        }
    }
}
