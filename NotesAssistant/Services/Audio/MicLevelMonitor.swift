import AVFoundation
import Foundation

protocol MicLevelMonitoring: AnyObject {
    func startMonitoring(_ recorderProvider: @escaping () -> AVAudioRecorder?) async
    func stopMonitoring()
    var onLevelUpdate: @Sendable (Float) -> Void { get set }
}

final class MicLevelMonitor: MicLevelMonitoring {
    var onLevelUpdate: @Sendable (Float) -> Void = { _ in }

    private var timer: Timer?

    func startMonitoring(_ recorderProvider: @escaping () -> AVAudioRecorder?) async {
        await MainActor.run { stopMonitoring() }
        await MainActor.run {
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let recorder = recorderProvider() else { return }
                recorder.updateMeters()
                let level = recorder.averagePower(forChannel: 0)
                let normalized = Self.normalize(power: level)
                self?.onLevelUpdate(normalized)
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private static func normalize(power: Float) -> Float {
        // Map from [-160, 0] dBFS to [0, 1]
        let minDb: Float = -60
        let clamped = max(minDb, power)
        return (clamped - minDb) / abs(minDb)
    }
}
