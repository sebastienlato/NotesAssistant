import Combine
import Foundation

@MainActor
final class LectureListViewModel: ObservableObject {
    @Published private(set) var notes: [LectureNote] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    nonisolated private let lectureStore: any LectureStore
    private let documentsDirectory: URL
    private let dateFormatter: DateFormatter

    init(lectureStore: any LectureStore) {
        self.lectureStore = lectureStore
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dateFormatter = LectureListViewModel.makeDateFormatter()

        Task { await loadNotes() }
    }

    func loadNotes() async {
        isLoading = true
        do {
            let loaded = try await fetchStoredNotes()
            notes = loaded.sorted(by: { $0.date > $1.date })
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
            notes = []
        }
        isLoading = false
    }

    func addNote(for audioURL: URL, transcriptText: String? = nil) async throws -> LectureNote {
        let now = Date()
        let note = LectureNote(
            id: UUID(),
            title: "Lecture – \(dateFormatter.string(from: now))",
            date: now,
            audioFilePath: relativePath(for: audioURL),
            transcriptText: transcriptText
        )

        notes.insert(note, at: 0)
        try await persistNotes()
        return note
    }

    func applyUpdated(note: LectureNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        } else {
            notes.insert(note, at: 0)
        }
        notes.sort(by: { $0.date > $1.date })
    }

    func persist(note: LectureNote) async {
        applyUpdated(note: note)
        do {
            try await persistNotes()
        } catch {
            errorMessage = "Failed to save notes: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func fetchStoredNotes() async throws -> [LectureNote] {
        let store = lectureStore
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let notes = try store.loadLectures()
                    continuation.resume(returning: notes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func persistNotes() async throws {
        let snapshot = notes
        let store = lectureStore
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    try store.saveLectures(snapshot)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        errorMessage = nil
    }

    private func relativePath(for url: URL) -> String {
        let documentsPath = documentsDirectory.path
        let path = url.path
        let prefix = documentsPath.hasSuffix("/") ? documentsPath : documentsPath + "/"
        if path.hasPrefix(prefix) {
            let trimmed = path.dropFirst(prefix.count)
            return trimmed.isEmpty ? url.lastPathComponent : String(trimmed)
        }
        return url.lastPathComponent
    }

    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
