# NotesAssistant – Architecture

NotesAssistant is a SwiftUI iOS app for recording lectures and converting them into text-based notes using Apple’s Speech framework. This document describes the high-level architecture and main components.

---

## 1. High-Level Overview

**Core flow:**

1. User starts a new recording in class.
2. App records audio to a local file.
3. After class, the user opens that recording and triggers transcription.
4. App converts the audio file into text and stores it alongside the lecture.
5. User can review, edit, and export the transcript.

The app uses a **layered approach**:

- **UI Layer (SwiftUI Views)**
- **State / View Models (ObservableObject)**
- **Domain Models (LectureNote, Transcript)**
- **Services (Audio, Speech, Persistence, Playback)**

---

## 2. Layers & Responsibilities

### 2.1 UI Layer (Features)

Located under `Features/`.

---

### **Recording**

Files:

- `RecordingView`
- `RecordingViewModel`

Responsibilities:

- Show record/stop button and elapsed time.
- Reflect current recording state (`isRecording`).
- Use `AudioRecorderService` to start/stop recording.
- On success, create a new `LectureNote` via the persistence layer.

---

### **Notes List**

Files:

- `LectureListView`
- `LectureListViewModel`

Responsibilities:

- Load and display a list of lecture notes.
- Create a new lecture (navigate to `RecordingView`).
- On selection → navigate to `LectureDetailView`.

---

### **Lecture Detail**

Files:

- `LectureDetailView`
- `LectureDetailViewModel`

Responsibilities:

- Show lecture metadata (title, date).
- Play back audio.
- Transcribe or re-transcribe.
- Edit title and transcript text.
- Export/share transcript or audio.
- Display future AI-enhanced content (summaries, flashcards).

---

## 3. Models

Located under `Models/`.

---

### 3.1 LectureNote

Represents a single lecture (audio + transcript):

```swift
struct LectureNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var audioFilePath: String
    var transcriptText: String?
}
```

---

### 3.2 Transcript

Simple wrapper for transcription results:

```swift
struct Transcript {
    let fullText: String
}
```

---

## 4. Services

Located under `Services/`.

Each service has:

- A protocol
- A concrete implementation
- Easy-to-mock API for unit tests

---

### 4.1 Audio Recorder Service

**Protocol:**

```swift
protocol AudioRecording {
    func startRecording() throws
    func stopRecording() async throws -> URL
    var isRecording: Bool { get }
}
```

---

### 4.2 Transcription Service

**Protocol:**

```swift
protocol Transcribing {
    func transcribeAudio(at url: URL) async throws -> Transcript
}
```

---

### 4.3 Persistence Service

**Protocol:**

```swift
protocol LectureStore {
    func loadLectures() throws -> [LectureNote]
    func saveLectures(_ notes: [LectureNote]) throws
}
```

---

### 4.4 Playback Service (Optional)

Simple wrapper around `AVAudioPlayer`.

---

## 5. App Entry Point

```swift
@main
struct NotesAssistantApp: App {
    private let audioRecorder = AudioRecorderService()
    private let transcriptionService = TranscriptionService()
    private let lectureStore = FileLectureStore()

    var body: some Scene {
        WindowGroup {
            LectureListView(
                viewModel: LectureListViewModel(
                    lectureStore: lectureStore,
                    audioRecorder: audioRecorder,
                    transcriptionService: transcriptionService
                )
            )
        }
    }
}
```

---

## 6. Permissions

- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

---

## 7. Future Expansion

AI Summary & Study Helper services using future Apple Intelligence APIs.

---

## 8. Testing Strategy

- Unit tests for each service
- ViewModel tests
- Optional UI tests
