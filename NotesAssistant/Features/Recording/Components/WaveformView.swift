import SwiftUI

struct WaveformView: View {
    var level: CGFloat

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let amplitude = max(4, level * (size.height / 2))
            let path = makeWavePath(width: size.width, midY: midY, amplitude: amplitude)
            context.stroke(path, with: .color(.accentColor.opacity(0.85)), lineWidth: 2.5)
            context.fill(path, with: .color(.accentColor.opacity(0.2)))
        }
        .animation(.easeInOut(duration: 0.15), value: level)
    }

    private func makeWavePath(width: CGFloat, midY: CGFloat, amplitude: CGFloat) -> Path {
        var path = Path()
        let steps = Int(width / 6)
        path.move(to: CGPoint(x: 0, y: midY))
        for step in 0...steps {
            let x = CGFloat(step) * 6
            let progress = CGFloat(step) / CGFloat(steps)
            let envelope = (1 - pow((progress - 0.5) * 2, 4))
            let yOffset = sin(progress * .pi * 4) * amplitude * envelope
            path.addLine(to: CGPoint(x: x, y: midY - yOffset))
        }
        for step in stride(from: steps, through: 0, by: -1) {
            let x = CGFloat(step) * 6
            let progress = CGFloat(step) / CGFloat(steps)
            let envelope = (1 - pow((progress - 0.5) * 2, 4))
            let yOffset = sin(progress * .pi * 4) * amplitude * envelope
            path.addLine(to: CGPoint(x: x, y: midY + yOffset))
        }
        path.closeSubpath()
        return path
    }
}
