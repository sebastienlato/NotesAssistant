import AVFAudio
import AVFoundation
import Foundation

protocol AudioRecording {
    func startRecording(useNoiseReduction: Bool) async throws
    func stopRecording() async throws -> URL
    var isRecording: Bool { get async }
    var currentStartDate: Date? { get async }
    var recorderInstance: AVAudioRecorder? { get }
}

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case failedToConfigureSession
    case failedToStart
    case notRecording
    case alreadyRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record."
        case .failedToConfigureSession:
            return "Unable to configure the audio session."
        case .failedToStart:
            return "Failed to start recording."
        case .notRecording:
            return "No active recording to stop."
        case .alreadyRecording:
            return "Recording is already in progress."
        }
    }
}

final class AudioRecorderService: NSObject, AudioRecording {
    private let session: AVAudioSession
    private var recorder: AVAudioRecorder?
    private var currentFileURL: URL?
    private var interruptionObserver: Any?
    private var recordingStartDate: Date?

    override init() {
        self.session = AVAudioSession.sharedInstance()
        super.init()
        observeInterruptions()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var isRecording: Bool { get async { recorder?.isRecording ?? false } }

    var currentStartDate: Date? { get async { recordingStartDate } }

    var recorderInstance: AVAudioRecorder? { recorder }

    func startRecording(useNoiseReduction: Bool) async throws {
        guard !isRecordingSync else {
            throw AudioRecorderError.alreadyRecording
        }

        guard hasRecordPermission() else {
            throw AudioRecorderError.permissionDenied
        }

        do {
            try configureSession(useNoiseReduction: useNoiseReduction)
        } catch {
            throw AudioRecorderError.failedToConfigureSession
        }

        let fileURL = makeRecordingURL()
        let sampleRate = session.sampleRate > 0 ? session.sampleRate : 44_100
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                throw AudioRecorderError.failedToStart
            }
            self.recorder = recorder
            self.currentFileURL = fileURL
            self.recordingStartDate = Date()
        } catch {
            throw AudioRecorderError.failedToStart
        }
    }

    func stopRecording() async throws -> URL {
        guard let recorder else {
            throw AudioRecorderError.notRecording
        }

        recorder.stop()
        self.recorder = nil
        recordingStartDate = nil

        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Not fatal, but loggable in a real app.
        }

        guard let url = currentFileURL else {
            throw AudioRecorderError.failedToStart
        }

        currentFileURL = nil
        return url
    }

    // MARK: - Helpers

    private func configureSession(useNoiseReduction: Bool) throws {
        try setNoiseReduction(useNoiseReduction)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func setNoiseReduction(_ enabled: Bool) throws {
        do {
            try session.setCategory(
                .playAndRecord,
                mode: enabled ? .voiceChat : .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
        } catch {
            print("Error setting noise reduction: \(error)")
            throw error
        }
    }

    private func makeRecordingURL() -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "Recording-\(timestamp).m4a"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(filename)
    }

    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }

            if type == .began {
                self?.handleInterruptionBegan()
            }
        }
    }

    private func handleInterruptionBegan() {
        recorder?.stop()
        recorder = nil
        recordingStartDate = nil
    }

    private func hasRecordPermission() -> Bool {
        if #available(iOS 17, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return session.recordPermission == .granted
        }
    }

    private var isRecordingSync: Bool {
        recorder?.isRecording ?? false
    }
}

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        self.recorder?.stop()
        currentFileURL = nil
        recordingStartDate = nil
    }
}
