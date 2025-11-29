import SwiftUI

struct RecordingHeader: View {
    @State private var animatePulse = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
                .shadow(color: .red.opacity(0.7), radius: 8, x: 0, y: 0)
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                        .scaleEffect(animatePulse ? 1.6 : 1)
                        .opacity(animatePulse ? 0 : 0.8)
                )
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: animatePulse)

            VStack(alignment: .leading, spacing: 2) {
                Text("Recording")
                    .font(.headline.weight(.semibold))
                Text("Mic is live")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .onAppear { animatePulse = true }
    }
}
