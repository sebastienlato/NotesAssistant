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
    private let startHaptic: UIImpactFeedbackGenerator
    private let stopHaptic: UIImpactFeedbackGenerator
    private let successHaptic: UINotificationFeedbackGenerator
    private let errorHaptic: UINotificationFeedbackGenerator
    private var timer: Timer?
    private var recordingStartDate: Date?
    private var permissionsChecked = false

    init(audioRecorder: AudioRecording, micMonitor: MicLevelMonitoring) {
        self.audioRecorder = audioRecorder
        self.micMonitor = micMonitor
        self.startHaptic = UIImpactFeedbackGenerator(style: .medium)
        self.stopHaptic = UIImpactFeedbackGenerator(style: .rigid)
        self.successHaptic = UINotificationFeedbackGenerator()
        self.errorHaptic = UINotificationFeedbackGenerator()
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
            startHaptic.impactOccurred(intensity: 0.7)
        } catch {
            errorMessage = error.localizedDescription
            isRecording = false
            stopTimer()
            errorHaptic.notificationOccurred(.error)
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
            stopHaptic.impactOccurred(intensity: 1.0)
        } catch {
            errorMessage = error.localizedDescription
            errorHaptic.notificationOccurred(.error)
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
            successHaptic.notificationOccurred(.success)
        }
    }

    private func startMonitoringLevels() {
        stopMonitoringLevels()
        micMonitor.onLevelUpdate = { [weak self] level in
            DispatchQueue.main.async {
                self?.micLevel = level
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
