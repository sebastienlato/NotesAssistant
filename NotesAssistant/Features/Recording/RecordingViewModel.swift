import AVFAudio
import AVFoundation
import Combine
import Foundation

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

    private let audioRecorder: AudioRecording
    private var timer: Timer?
    private var recordingStartDate: Date?
    private var permissionsChecked = false

    init(audioRecorder: AudioRecording) {
        self.audioRecorder = audioRecorder
    }

    var elapsedTimeString: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func onAppear() {
        guard !permissionsChecked else { return }
        permissionsChecked = true
        Task {
            let granted = await requestRecordPermission()
            if !granted {
                errorMessage = AudioRecorderError.permissionDenied.localizedDescription
            }
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

    // MARK: - Private

    private func startRecording() {
        errorMessage = nil
        do {
            try audioRecorder.startRecording()
            recordingStartDate = Date()
            isRecording = true
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
            isRecording = false
            stopTimer()
        }
    }

    private func stopRecording() async {
        guard isRecording else { return }
        isRecording = false
        stopTimer()
        recordingStartDate = nil

        do {
            let url = try await audioRecorder.stopRecording()
            completedRecording = RecordedAudio(fileURL: url)
            elapsedTime = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startTimer() {
        elapsedTime = 0
        recordingStartDate = Date()
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
}
