# Development validation

Validated on 16 October 2026 using Xcode 26.3, Swift 6.2.4, and an iPad Pro 13-inch (M5) simulator running iOS/iPadOS 26.3. The deployment target is iPadOS 17; this simulator run does not establish compatibility on every supported iPadOS release.

- Local simulator build: passed.
- Signed CloudDebug build for an iOS device: passed using the locally configured Apple Developer team.
- Signed entitlements: private CloudKit container identifier, CloudKit service, team identifier, and development push environment confirmed.
- Six data tests: passed (profile ownership, speech fallback, persistent store reopening, backup round trip, invalid backup rejection, deletion isolation).
- Two UI tests: passed (word taps/sentence controls/category filtering, parent gate and word creation).
- Visual check: bundled starter pictures render independently of simulator emoji font availability. Preview uses fictional sample data.
- Release guard: confirmed that Release configuration rejects the presence of `legacy/`.
- Git whitespace checks: passed.
- Signed CloudDebug app installed successfully on the paired iPad Pro 13-inch (M4) after the connection recovered.
- After the iPad was connected over USB and unlocked, the signed app launched successfully. A 25-second startup console capture showed no storage or CloudKit initialization errors. Sophia was then launched normally and left open. This confirms launch, not successful cross-device sync or audible speech.

## Still requires a hands-on iPad check

- Real iCloud sync across two signed-in iPads, including photos, edits, deletions, offline changes, and account switching/restrictions.
- Actual audio output, downloaded/offline voices, interruptions, and volume behavior.
- The parent's chosen iPad, accessibility settings, portrait/Split View, custom photos, and Files-based backup export/import.
- CloudKit production schema, distribution signing, App Store metadata/privacy answers, and release checklist.

The Apple account and signing setup work on this Mac; no additional account sign-in was needed. No production release has been made. Personal signing identifiers are kept in the ignored `Configuration/Signing.local.xcconfig` file.

## Picture library update — 16 October 2026

- Added 120 offline library pictures, automatic label suggestions, tag/name search, explicit selection, empty-search browsing, and no-results feedback. Personal photos remain supported.
- All 12 tests passed: the original six data checks, four library/search/asset/backup checks, and two UI flows including selecting a suggestion and searching the full library without changing card text.
- Signed iCloud device build passed and the update installed successfully over the existing iPad app.
- No SwiftData schema or backup-format change. Library selections store the existing shared symbol identifier and no photo data; photo selections keep their existing behavior.
- Asset folder size is approximately 5 MB, including the app icon. No image-generation service or online picture search is used.
- Voice selection is unchanged: Apple speech synthesis selects by language. A named Enhanced/Premium voice picker is not included in this change.
