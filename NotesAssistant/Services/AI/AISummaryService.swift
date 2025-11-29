import Foundation

struct SummaryResult: Sendable, Equatable {
    let summary: String
    let keyPoints: [String]
}

protocol Summarizing {
    func summarize(text: String) async throws -> SummaryResult
}

/// Placeholder summarizer intended to be replaced by an Apple Intelligence-backed implementation later.
/// Deterministic heuristic: uses the first few sentences as the summary and picks short sentences as key points.
final class HeuristicSummaryService: Summarizing {
    func summarize(text: String) async throws -> SummaryResult {
        let sentences = splitSentences(from: text)
        let summary = sentences.prefix(3).joined(separator: " ")
        let keyPoints = selectKeyPoints(from: sentences)
        return SummaryResult(summary: summary.isEmpty ? text : summary, keyPoints: keyPoints)
    }

    private func splitSentences(from text: String) -> [String] {
        let delimiters: CharacterSet = [".", "!", "?"]
        return text
            .components(separatedBy: delimiters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func selectKeyPoints(from sentences: [String]) -> [String] {
        guard !sentences.isEmpty else { return [] }
        let shortSentences = sentences.filter { $0.split(separator: " ").count <= 12 }
        if shortSentences.isEmpty {
            return Array(sentences.prefix(3))
        }
        return Array(shortSentences.prefix(5))
    }
}
