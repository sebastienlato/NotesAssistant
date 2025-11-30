import AVFAudio
import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
final class RecordingViewModel: ObservableObject {
    struct RecordedAudio: Identifiable, Hashable, Sendable {
        let id = UUID()
        let fileURL: URL
    }

    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var errorMessage: String?
    @Published var completedRecording: RecordedAudio?
    @Published var micLevel: Float = 0

    private let audioRecorder: AudioRecording
    private let micMonitor: MicLevelMonitoring
    private let emaSmoothing: Float = 0.2
    private var timer: Timer?
    private var recordingStartDate: Date?
    private var permissionsChecked = false

    init(audioRecorder: AudioRecording, micMonitor: MicLevelMonitoring) {
        self.audioRecorder = audioRecorder
        self.micMonitor = micMonitor
        Task { await restoreRecorderState() }
    }

    var elapsedTimeString: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func onAppear() {
        if !permissionsChecked {
            permissionsChecked = true
            Task {
                let granted = await requestRecordPermission()
                if !granted {
                    errorMessage = AudioRecorderError.permissionDenied.localizedDescription
                }
            }
        }
        if isRecording, timer == nil, let start = recordingStartDate {
            startTimer(from: start)
        }
    }

    func toggleRecording() {
        if isRecording {
            Task { await stopRecording() }
        } else {
            startRecording()
        }
    }

    func clearCompletedRecording() {
        completedRecording = nil
    }

    func pauseTimerOnDisappear() {
        stopTimer()
        stopMonitoringLevels()
    }

    // MARK: - Private

    private func startRecording() {
        errorMessage = nil
        do {
            try audioRecorder.startRecording()
            let startDate = Date()
            isRecording = true
            startTimer(from: startDate)
            startMonitoringLevels()
            Haptics.impact(.medium, intensity: 0.8)
        } catch {
            errorMessage = error.localizedDescription
            isRecording = false
            stopTimer()
            Haptics.notification(.error)
        }
    }

    private func stopRecording() async {
        guard isRecording else { return }
        isRecording = false
        stopTimer()
        recordingStartDate = nil
        stopMonitoringLevels()

        do {
            let url = try await audioRecorder.stopRecording()
            completedRecording = RecordedAudio(fileURL: url)
            elapsedTime = 0
            Haptics.impact(.rigid, intensity: 1.0)
        } catch {
            errorMessage = error.localizedDescription
            Haptics.notification(.error)
        }
    }

    private func startTimer(from startDate: Date) {
        recordingStartDate = startDate
        elapsedTime = Date().timeIntervalSince(startDate)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.recordingStartDate else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func requestRecordPermission() async -> Bool {
        if #available(iOS 17, *) {
            let application = AVAudioApplication.shared
            switch application.recordPermission {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    session.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        }
    }

    private func restoreRecorderState() async {
        let isActive = await audioRecorder.isRecording
        guard isActive else { return }
        let startDate = await audioRecorder.currentStartDate ?? Date()
        await MainActor.run {
            isRecording = true
            startTimer(from: startDate)
            startMonitoringLevels()
            Haptics.notification(.success)
        }
    }

    private func startMonitoringLevels() {
        stopMonitoringLevels()
        micMonitor.onLevelUpdate = { [weak self] level in
            DispatchQueue.main.async {
                guard let self else { return }
                let smoothed = self.micLevel * (1 - self.emaSmoothing) + level * self.emaSmoothing
                self.micLevel = smoothed
            }
        }
        Task { [weak self] in
            guard let self else { return }
            await micMonitor.startMonitoring { self.audioRecorder.recorderInstance }
        }
    }

    private func stopMonitoringLevels() {
        micMonitor.stopMonitoring()
        micLevel = 0
    }
}
