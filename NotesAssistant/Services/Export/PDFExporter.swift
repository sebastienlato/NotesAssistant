import Foundation
import UIKit

protocol PDFExporting {
    func exportPDF(title: String, date: Date, transcript: String) throws -> URL
}

struct PDFExporter: PDFExporting {
    func exportPDF(title: String, date: Date, transcript: String) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter at 72 dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let pdfData = renderer.pdfData { context in
            context.beginPage()
            let margin: CGFloat = 36
            var cursor = CGPoint(x: margin, y: margin)

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .title2)
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .body)
            ]
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .subheadline),
                .foregroundColor: UIColor.secondaryLabel
            ]

            cursor = draw(text: title, at: cursor, width: pageRect.width - margin * 2, attributes: titleAttrs)
            cursor.y += 8
            cursor = draw(text: formatter.string(from: date), at: cursor, width: pageRect.width - margin * 2, attributes: subtitleAttrs)
            cursor.y += 16

            let transcriptText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = draw(text: transcriptText, at: cursor, width: pageRect.width - margin * 2, attributes: bodyAttrs)
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Lecture-Export-\(UUID().uuidString).pdf")
        try pdfData.write(to: tempURL)
        return tempURL
    }

    private func draw(text: String, at origin: CGPoint, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGPoint {
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let bounding = attributed.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        attributed.draw(in: CGRect(origin: origin, size: bounding.size))
        return CGPoint(x: origin.x, y: origin.y + ceil(bounding.height))
    }
}
