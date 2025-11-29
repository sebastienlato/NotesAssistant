# Repository Guidelines

## Project Structure & Module Organization
All SwiftUI sources live under `NotesAssistant/`, with `NotesAssistantApp.swift` bootstrapping the app and `ContentView.swift` acting as the current placeholder scene. Assets (SF Symbols, color sets) sit in `NotesAssistant/Assets.xcassets`. Use the architecture described in `architecture.md` when expanding: group UI under `Features/<FeatureName>/`, state inside matching `ViewModel` files, shared entities under `Models/`, and service abstractions under `Services/`. Keep any new tests in the default `NotesAssistantTests/` bundle so Xcode can discover them automatically.

## Build, Test, and Development Commands
Run these from the repo root:
- `xed NotesAssistant.xcodeproj` — opens the workspace in Xcode.
- `xcodebuild -scheme NotesAssistant -destination 'platform=iOS Simulator,name=iPhone 16' build` — headless CI build.
- `xcodebuild test -scheme NotesAssistant -destination 'platform=iOS Simulator,name=iPhone 16'` — executes unit tests.
- `swiftformat NotesAssistant` — optional formatting pass if you have `swiftformat` installed locally.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines: 4-space indentation, braces on the same line, and trailing-closure syntax where it improves readability. Views should end with `View`, view models with `ViewModel`, protocols as nouns (`AudioRecording`) and services with the `Service` suffix. Prefer `PascalCase` for types, `camelCase` for properties/functions, and keep previews wrapped in `#if DEBUG`. Co-locate mocks next to their protocol definitions and document any non-obvious business rules with concise `///` comments.

## Testing Guidelines
Use `XCTestCase` suites in `NotesAssistantTests/`, naming files `<TypeUnderTest>Tests.swift`. Target high coverage on `ViewModel` logic and the `Services` layer by injecting protocol-based dependencies so tests can swap in fakes. UI snapshot or integration tests can sit in an optional `NotesAssistantUITests/` bundle—driven via `xcodebuild test` by adding `-scheme NotesAssistantUITests`. Record regressions with async tests that await transcription or recording flows.

## Commit & Pull Request Guidelines
Recent history uses short, imperative messages (e.g., `Add lecture detail view`), so keep commits scoped and descriptive. Each pull request should summarize the change, list testing performed (`xcodebuild test` run, simulator version), and link any issue or task reference. Include simulator screenshots for UI work and call out permission plist updates (e.g., microphone usage strings). Ensure CI scripts can run the listed commands without manual steps before requesting review.
