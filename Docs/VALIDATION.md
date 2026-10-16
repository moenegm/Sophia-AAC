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

## Expanded library and voice picker — 16 October 2026

- Expanded to 3,557 offline pictures: the original 120, 3,436 Mulberry symbols, and a dedicated chicken-wings illustration. Mulberry attribution and CC BY-SA 4.0 license ship with the app; the parent area includes credits.
- All 14 unit tests passed, including every bundled picture loading, unique identifiers, phrase searches, old-backup compatibility, new picture identifiers surviving backup/restore, and voice selection/fallback.
- Warmed search benchmark on the simulator: approximately 3.3 milliseconds per query across 100 searches over the full collection. This is a simulator measurement, not a real-iPad latency or memory benchmark.
- Expanded PNG files add approximately 47 MB. The UI uses a lazy grid, precomputed search terms, and a 64-image/24 MiB cache; each card stores a reference rather than copying a library picture.
- Added installed Apple voice selection, quality labels, individual previews, download instructions, and fallback when a selected voice is unavailable. Selection persists locally on each iPad.
- Signed CloudDebug device build passed. The updated app installed over the existing app and launched successfully on the paired iPad Pro 13-inch (M4).
- Real audible voice quality, downloading Enhanced/Premium voices, and cross-device CloudKit sync still require hands-on checks. Simulator voice services emitted fallback warnings; automated voice tests do not establish audio quality.
- Both UI tests passed: board communication controls, parent gate, saved voice selection, explicit picture suggestions, full-library chicken-wings search/selection, unchanged card text, and saving the card. Total: 16 passing tests.

## Parent keypad and curated voices — 16 October 2026

- Replaced the parent answer text field with an in-app keypad so the floating iPad number keyboard cannot cover the arithmetic question. Includes clear and delete controls.
- Limited selectable voices to installed Samantha and Eddy variants matching the chosen language. Removed the general system-default choice; automatic fallback prefers Samantha, then Eddy, then a language-matched system voice when neither is available. Previously selected other voices no longer override this preference.
- Kept voice download instructions and added an explanation that Siri voices are unavailable to this speech API. Reference: https://developer.apple.com/videos/play/wwdc2020/10022/ .
- All 14 unit tests and both existing UI flows passed after these changes. Signed CloudDebug build passed; the update installed and launched on the paired iPad.
- Additional portrait UI regression passed: the question remains hittable, no system keyboard appears, and keypad entry, delete, and clear work. Total: 17 passing tests across the full suite and targeted portrait run.

## Voice group filter correction — 16 October 2026

- Replaced the Samantha/Eddy name restriction with an exclusion of Eloquence provider identifiers and Apple’s `isNoveltyVoice` trait. Other app-available voices matching the selected language remain selectable, including future downloads.
- Preserved download instructions, previews, selection persistence, and refresh. Existing selections from excluded groups fall back to an allowed voice.
- Three focused voice tests passed: excluded groups, complete allowed-language enumeration and identifier resolution, and unavailable-selection fallback. Signed CloudDebug device build passed and installed successfully on the paired iPad.

## Optional sentence builder — 16 October 2026

- Added a per-profile Show sentence builder switch with two explanatory sentences beneath it in Parent space. It starts enabled to preserve existing behavior.
- Off hides the strip and prevents word collection while immediate card speech remains unchanged. Changing the setting clears the unfinished sentence. The preference is stored with the profile and included as an optional backup field; old backups restore enabled.
- Existing full suite passed (15 unit tests and three UI tests). Two added regressions passed separately: per-child backup/isolation/legacy restoration, and toggling off through the switch then tapping a word without showing the strip. The UI test targets the switch control because the row’s center tap did not change its value.
- Signed CloudDebug device build passed; update installed over the existing app and launched on the paired iPad. Real cross-device propagation of the new setting remains a hands-on CloudKit check.
