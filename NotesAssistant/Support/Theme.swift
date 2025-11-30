import SwiftUI
import UIKit

enum AppColors {
    static let primaryBlue = Color(red: 10/255, green: 22/255, blue: 54/255)
    static let accentBlue = Color(red: 34/255, green: 121/255, blue: 255/255)
    static let cardBackground = Color(.secondarySystemBackground).opacity(0.85)
    static let cardBorder = Color.white.opacity(0.08)
}

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
