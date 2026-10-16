# Sophia-AAC

An iPad-only picture communication app for autistic children, rebuilt natively with SwiftUI. Parents create child profiles, choose photos, and organize the words that matter. Children tap a picture to speak through Apple's built-in speech synthesis.

![Sophia iPad preview](Docs/iPad-preview.png)

## Included

- Large picture cards, categories, favorites, and a sentence strip with Speak, Undo, Clear, and Stop voice.
- Separate parent mode for profiles, photos, categories, card editing, and ordering.
- Optional starter boards with 27 words across five categories.
- Offline SwiftData persistence, plus a separate iCloud build configuration for private CloudKit sync through the parent's Apple Account.
- JSON backup export/import; restoring creates a new profile.
- English and Arabic voice choices and adjustable speaking speed. Card content is edited manually, not automatically translated.

No Rails backend, Sophia account, VoiceRSS key, third-party packages, ads, or analytics are required by the native app.

## Open the project

Open **Sophia-AAC.xcodeproj**, choose **Sophia-AAC**, select an iPad simulator, and Run. Requires iPadOS 17+. `--demo` loads a temporary sample board for previews/tests.

The regular scheme is local-only. **Sophia-AAC iCloud** enables CloudKit after the Apple team and container are configured. Cross-device sync is not considered verified until tested on signed devices.

See [setup and testing](Docs/SETUP.md) and the [release checklist](Docs/RELEASE.md).

## Repository layout

- `Sources/` — native SwiftUI app, models, speech, editors, and backups.
- `Assets.xcassets/` — native app icon.
- `Configuration/` — local/iCloud build configurations, entitlements, and privacy manifest.
- `Tests/`, `UITests/` — data and iPad interaction tests.
- `Scripts/` — project generation and release guard.
- `legacy/rails/` — temporary copy of the original web app for reference only.

**Remove `legacy/` before going live.** Release builds fail while that directory exists. The legacy code is never a source/resource of the iPad target; removing it from a release does not erase Git history.
