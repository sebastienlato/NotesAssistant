import Foundation

protocol LectureStore: Sendable {
    func loadLectures() throws -> [LectureNote]
    func saveLectures(_ notes: [LectureNote]) throws
}

final class FileLectureStore: LectureStore, @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(filename: String = "lectures.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadLectures() throws -> [LectureNote] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([LectureNote].self, from: data)
    }

    func saveLectures(_ notes: [LectureNote]) throws {
        let data = try encoder.encode(notes)
        try data.write(to: fileURL, options: .atomic)
    }
}
