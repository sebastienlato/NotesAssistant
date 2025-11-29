import XCTest
@testable import NotesAssistant

final class HeuristicSummaryServiceTests: XCTestCase {
    func testSummarizeProducesSummaryAndKeyPoints() async throws {
        let service = HeuristicSummaryService()
        let text = "SwiftUI makes it easy to build great apps. It is declarative and uses state to drive UI. Developers can preview their work quickly."

        let result = try await service.summarize(text: text)

        XCTAssertFalse(result.summary.isEmpty, "Summary should not be empty")
        XCTAssertFalse(result.keyPoints.isEmpty, "Key points should not be empty")
    }
}
