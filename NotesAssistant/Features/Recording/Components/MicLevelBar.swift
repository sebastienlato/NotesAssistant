import SwiftUI

struct MicLevelBar: View {
    var level: CGFloat
    var body: some View {
        GeometryReader { proxy in
            let height = max(4, level * proxy.size.height)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor.opacity(0.8))
                .frame(height: height)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .animation(.easeInOut(duration: 0.15), value: level)
        }
    }
}
