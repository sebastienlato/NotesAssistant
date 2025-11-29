import SwiftUI

@main
struct NotesAssistantApp: App {
    private let audioRecorder = AudioRecorderService()
    private let transcriptionService = TranscriptionService()

    var body: some Scene {
        WindowGroup {
            RecordingView(
                audioRecorder: audioRecorder,
                transcriptionService: transcriptionService
            )
        }
    }
}
