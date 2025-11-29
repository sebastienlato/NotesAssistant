import SwiftUI

@main
struct NotesAssistantApp: App {
    private let audioRecorder = AudioRecorderService()
    private let transcriptionService = TranscriptionService()
    private let lectureStore = FileLectureStore()
    private let summaryService = HeuristicSummaryService()

    var body: some Scene {
        WindowGroup {
            LectureListView(
                viewModel: LectureListViewModel(lectureStore: lectureStore),
                audioRecorder: audioRecorder,
                transcriptionService: transcriptionService,
                summaryService: summaryService
            )
        }
    }
}
