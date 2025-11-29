# Codex Prompt – NotesAssistant

You are helping build **NotesAssistant**, a SwiftUI iOS app that records lectures and converts them into searchable notes by transcribing audio into text. The project lives in Xcode and will be edited using Cursor + Codex CLI.

## Core Principles

1. **Follow the plan**

   - Use `plan.md` as the roadmap.
   - Work in **small, coherent phases** (Phase 1: recording + transcription, then notes management, then export, etc.).
   - Do not jump ahead to later phases unless explicitly asked.

2. **Respect existing structure**

   - Read `architecture.md` before touching code.
   - Prefer extending existing types over inventing new parallel ones.
   - Maintain **file names, folder names, and structure exactly as defined**.
   - Never create duplicate versions of files (e.g., `AudioRecorderService copy 2.swift`).

3. **SwiftUI + MVVM-ish**

   - Use SwiftUI for all UI.
   - Views: lightweight, declarative.
   - Logic: in view models or services.
   - Use Swift Concurrency (`async/await`) where appropriate (e.g., transcription calls, I/O).

4. **Small, focused commits**

   - Group changes by feature or concern.
   - Avoid mixing unrelated refactors with new features.
   - Use the user's preferred commit format:
     - **One short title**
     - **One or more `-m` detail lines**
       Example:
     ```
     feat: add audio recorder service
     - set up AVAudioSession configuration
     - implement start/stop API with file output
     - add basic error handling
     ```

5. **Clarity over cleverness**
   - Prefer readable, maintainable code over fancy tricks.
   - Add short, meaningful comments where behavior is non-obvious.
   - Use descriptive names for services, view models, models, and helpers.
   - Do not generate placeholder code (e.g., stubs or fake implementations) unless explicitly requested.

---

## Project Guidelines

### Target

- **Platform:** iOS
- **Minimum iOS:** 17+
- **Language:** Swift 5.x with async/await
- **UI:** SwiftUI app lifecycle

### Features (High-Level)

- Record lecture audio.
- Transcribe audio to text using Apple’s Speech framework (`SFSpeechRecognizer`).
- Store and manage multiple lecture notes.
- Export transcripts (share text / PDF).
- Later: AI-powered summaries / study helpers.

---

## Folder & File Structure (High-Level)

Follow the structure outlined in `architecture.md`. At a minimum:

- `NotesAssistantApp.swift` – SwiftUI entry point.
- `Features/`
  - `Recording/`
  - `NotesList/`
  - `LectureDetail/`
- `Services/`
  - `AudioRecorderService.swift`
  - `TranscriptionService.swift`
  - `PersistenceService.swift` (or similar)
- `Models/`
  - `LectureNote.swift`
  - `Transcript.swift`
- `Support/`
  - `InfoPlist-Notes.md`
  - Helpers / extensions.

**Rules for Codex**

- Always place new files in the correct folder.
- Never rename or move folders unless explicitly requested.
- Do not create placeholder folders that are empty.

---

## Implementation Rules

1. **Permissions**

   - Use the appropriate Info.plist keys for microphone and speech recognition.
   - Handle denied permissions gracefully with user-friendly messages.

2. **Audio Recording**

   - Use `AVAudioSession` and `AVAudioRecorder` (or `AVAudioEngine` later).
   - Record to a `.m4a` file in the app’s documents directory.
   - Expose a clear API:
     ```swift
     protocol AudioRecording {
         func startRecording() throws
         func stopRecording() async throws -> URL
         var isRecording: Bool { get }
     }
     ```
   - Handle interruptions and errors without crashing.

3. **Transcription**

   - Use `SFSpeechRecognizer` + `SFSpeechURLRecognitionRequest`.
   - Represent results as:
     ```swift
     struct Transcript {
         let fullText: String
     }
     ```
   - Allow configurable locale (default: system language).

4. **State Management**

   - Use `@StateObject` and `@ObservedObject` correctly.
   - Move long-running tasks (recording, transcription) into services or view models.
   - Annotate view models with `@MainActor` to ensure UI safety.

5. **Persistence**

   - Start with a simple JSON-based storage.
   - Encapsulate persistence behind a `LectureStore` protocol.
   - Ensure the JSON is stored predictably and safely in documents directory.

6. **Error Handling & UX**

   - Surface errors to the UI in a clear way (alerts, inline text).
   - Never use `fatalError` in production code.
   - Ensure recordings/transcriptions fail gracefully.

---

## Code Style

- Follow Swift API Design Guidelines.
- Favor `struct` over `class` when appropriate.
- Split code into extensions or helpers to avoid > 350–400 line files.
- Use `MARK:` sections to keep code organized.
- Keep spacing and indentation consistent.

---

## How to Respond to User Requests (Codex Behavior)

When Sebastien requests a change:

- Read the request entirely.
- Verify alignment with `plan.md` and `architecture.md`.
- Make **minimum, focused changes** to satisfy the request.
- Generate a clean diff.
- Provide a multi-line commit message following the format defined above.
- Do not produce unnecessary commentary — keep output focused.

If there is ambiguity:

- Make a reasonable choice that fits the existing architecture.
- Explain it briefly in the diff summary if needed.

---

## Non-Goals

- No premature optimization.
- No external dependencies unless explicitly requested.
- No “refactor everything” operations unless explicitly requested.
- No placeholder / meaningless code.

Build a clean, focused, extensible **NotesAssistant** app.
