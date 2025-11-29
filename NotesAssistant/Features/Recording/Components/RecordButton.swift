import SwiftUI
import UIKit

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.9) : Color.accentColor)
                    .frame(width: 88, height: 88)
                    .shadow(color: (isRecording ? Color.red : Color.accentColor).opacity(0.6), radius: 14, x: 0, y: 8)
                    .overlay(
                        Circle()
                            .stroke((isRecording ? Color.red : Color.accentColor).opacity(0.4), lineWidth: 6)
                            .scaleEffect(pulse ? 1.2 : 1)
                            .opacity(pulse ? 0.2 : 0.6)
                    )
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
    }
}
