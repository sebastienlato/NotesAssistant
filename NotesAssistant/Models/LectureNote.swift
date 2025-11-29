import Foundation

struct LectureNote: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var date: Date
    var audioFilePath: String
    var transcriptText: String?
}
