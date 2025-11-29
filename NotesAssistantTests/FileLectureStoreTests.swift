import XCTest
@testable import NotesAssistant

final class FileLectureStoreTests: XCTestCase {
    func testSaveAndLoadLectures() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let store = FileLectureStore(filename: "lectures-test.json", baseURL: tempDir)
        let notes = [
            LectureNote(id: UUID(), title: "Test Lecture", date: Date(), audioFilePath: "audio1.m4a", transcriptText: "Transcript 1"),
            LectureNote(id: UUID(), title: "Another", date: Date().addingTimeInterval(-3600), audioFilePath: "audio2.m4a", transcriptText: nil)
        ]

        try store.saveLectures(notes)
        let loaded = try store.loadLectures()

        XCTAssertEqual(notes.count, loaded.count)
        XCTAssertEqual(Set(notes), Set(loaded))
    }
}
