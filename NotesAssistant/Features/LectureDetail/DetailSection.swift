import Foundation

enum DetailSection: String, CaseIterable, Identifiable {
    case transcript
    case study
    case export

    var id: String { rawValue }
    var title: String {
        switch self {
        case .transcript: return "Transcript"
        case .study: return "Study"
        case .export: return "Export"
        }
    }
}
