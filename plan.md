# NotesAssistant – Project Plan

A SwiftUI iOS app that records lectures and turns them into searchable notes by transcribing audio to text. Later phases will layer on AI-powered summaries and study helpers.

---

## Goals

- ✅ Record long-form audio in class (lectures, talks) reliably.
- ✅ Transcribe recordings into text **after** class using the Speech framework.
- ✅ Store & manage lecture notes (title, date, transcript, audio file).
- ✅ Export notes (share sheet, .txt / .pdf) for backup and studying.
- 🔜 Add “smart” features (summaries, key points, flashcards) using Apple’s AI tooling when available.

---

## Tech Stack

- **Platform:** iOS (SwiftUI, iOS 17+)
- **Language:** Swift + Swift Concurrency (async/await)
- **UI:** SwiftUI + MVVM-ish structure
- **Audio:** AVAudioSession + AVAudioRecorder (or AVAudioEngine later)
- **Speech to Text:** Speech framework (`SFSpeechRecognizer`)
- **Storage (v1):** Simple file-based / JSON storage
- **Storage (v2+):** Core Data or SQLite-backed store (TBD)
- **Testing:** Unit tests for services; basic UI smoke tests later

---

## Phase 1 – Core Recording & Transcription

**Goal:** By the end of Phase 1, we can record a lecture, stop, and run transcription to get text on screen.

### 1. Project Setup

- Create `NotesAssistant` SwiftUI project (iOS 17+).
- Add root files:
  - `plan.md`
  - `codex_prompt.md`
  - `architecture.md`
- Add basic app metadata:
  - App name: **NotesAssistant**
  - Bundle identifier placeholder
  - Minimum iOS version: 17.0

### 2. Permissions & Entitlements

- Request **microphone** permission.
- Request **speech recognition** permission.
- Add required keys to `Info.plist`:
  - `NSSpeechRecognitionUsageDescription`
  - `NSMicrophoneUsageDescription`

### 3. Audio Recording Service

- Create `AudioRecorderService`:
  - Configure `AVAudioSession` for recording.
  - Start/stop recording to `.m4a` in the app’s documents directory.
  - Return a `URL` to the recorded file.
- Handle errors (permissions denied, session failures).

### 4. Transcription Service

- Create `TranscriptionService` wrapping `SFSpeechRecognizer`:
  - Request speech recognition authorization.
  - Accept a recorded audio `URL`.
  - Use `SFSpeechURLRecognitionRequest` for transcription.
  - Produce:
    ```swift
    struct Transcript {
        let fullText: String
    }
    ```
- Support configurable language / locale (start with the system locale).

### 5. Basic UI Flow

- `RecordingView`:

  - Big Record / Stop button.
  - Timer for elapsed recording time.
  - On stop → navigate to a simple `TranscriptionView`.

- `TranscriptionView`:
  - Button: **“Transcribe Recording”**
  - Shows progress (“Transcribing…”)
  - Displays `fullText` once ready in a scrollable text view.

---

## Phase 2 – Lecture Notes Management

**Goal:** Manage multiple lectures with stored transcripts and audio.

### 1. LectureNote Model

- Define `LectureNote`:

  - `id: UUID`
  - `title: String`
  - `date: Date`
  - **`audioFilePath: String`** (matches architecture.md)
  - `transcriptText: String?`

- Add simple persistence layer (JSON or lightweight storage):
  - Load / save notes array from disk.
  - Handle minor migrations safely.

### 2. Notes List UI

- `LectureListView`:
  - Displays list of lecture notes sorted by date.
  - “+” button → start a new recording.
  - Tap a note → `LectureDetailView`.

### 3. Lecture Detail Screen

- `LectureDetailView`:
  - Shows metadata.
  - Buttons:
    - Play audio (basic playback).
    - Transcribe / re-transcribe.
  - Shows transcript text in a scrollable area.
  - Allow editing title and transcript text.

---

## Phase 3 – Export & Sharing

**Goal:** Make notes portable and backup-friendly.

### 1. Sharing

- From `LectureDetailView`, add:
  - **Share Transcript** (`.txt` via share sheet).
  - Optional: **Share Audio** (raw recording).

### 2. PDF Export (Optional)

- Generate simple PDF containing:
  - Title
  - Date
  - Transcript text

---

## Phase 4 – “Smart” Features (AI-Enhanced)

**Goal:** Enhance study experience using AI once APIs are available and stable.

### 1. Summaries

- From transcript generate:
  - Short summary (2–3 paragraphs).
  - Bullet-point key takeaways.

### 2. Study Helpers

- Generate:
  - Q&A flashcards.
  - Definitions of key concepts.

### 3. UI Additions

- Add `SummarySection` and `StudyHelpersSection` to `LectureDetailView`.
- Allow user to regenerate if transcript changes.

> AI features depend on future Apple APIs, so this phase is intentionally high-level.

---

## Phase 5 – Polish & Hardening

- Refine UI (typography, spacing, color system).
- Add accessibility improvements.
- Add tests:
  - AudioRecorderService (mocked)
  - TranscriptionService (mocked)
  - Persistence layer
- Battery/performance improvements during long recordings.
- App icon, launch screen, metadata.

---

## Working with Codex

- **Follow this plan as the single source of truth.**
- Implement phase-by-phase, with small atomic commits.
- Prefer:
  - SwiftUI + MVVM-ish
  - Small services with clear responsibilities
- Avoid:
  - Huge all-in-one PRs
  - Mixing UI and service logic

This plan will be updated as the app grows.
