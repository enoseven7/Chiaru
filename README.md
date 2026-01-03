# Chiaru

Chiaru is a focused study workspace that combines notes, flashcards, and quizzes in one place. It’s built with Flutter and runs offline-first.

## Platforms
- **Windows**: Supported and tested.
- **macOS / Linux**: Not made yet, but expect for them to come soon.

## Features
- Hybrid note editor (rich text + canvas for handwriting).
- Anki-inspired flashcards with spaced-repetition scheduling.
- Quiz creation and review.
- Cloud AI usage for feynman technique and flashcard / quiz generation.
- Offline-friendly local storage with export options.

## Building (Windows)
1) Install Flutter (3.10+), the Windows desktop toolchain, and run `flutter doctor` until clean.
2) From the project root:
   ```bash
   flutter pub get
   flutter build windows
   ```
3) The build artifacts will be under `build/windows/runner/Release` (or `build/windows/x64/Runner` depending on your Flutter version).

## Running
```bash
flutter run -d windows
```

Or you can simply run the .exe file you download.

## Notes / To-Do List
- Local LLM support for users to run AI locally and offline without API keys.
- MacOS and Linux supported versions

