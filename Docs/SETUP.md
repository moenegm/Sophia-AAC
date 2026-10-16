# Running Sophia on an iPad

Requires Xcode 15+ with an iOS SDK, and an iPad running iPadOS 17 or later. This is an iPad-only target (device family 2); neither iPhone nor Mac Catalyst is enabled.

## Preview without signing in

1. Open `Sophia-AAC.xcodeproj`.
2. Choose the **Sophia-AAC** scheme and an iPad simulator.
3. Press Run. Create a profile and optionally include starter words.
4. To preview sample content without writing it to disk, add `--demo` in Product → Scheme → Edit Scheme → Run → Arguments. Remove it before normal use. Demo data is in memory and resets at launch; it never syncs.

The default scheme saves locally. It needs no developer account or external speech key.

## Developer account and iCloud

1. Open Xcode → Settings → Apple Accounts. If the account is missing, choose Add Apple Account, sign in yourself, and complete any verification. Never paste passwords into source files or chat.
2. Select the account and confirm your paid developer team is listed with access to Certificates, Identifiers & Profiles.
3. Copy `Configuration/Signing.example.xcconfig` to `Configuration/Signing.local.xcconfig` if a local file has not already been created. Set `DEVELOPMENT_TEAM`, an available `PRODUCT_BUNDLE_IDENTIFIER`, and the matching `CLOUDKIT_CONTAINER_IDENTIFIER`. The local file is ignored by Git. It contains identifiers, not credentials.
4. Choose the **Sophia-AAC iCloud** scheme. Its CloudDebug/CloudRelease configurations include the iCloud entitlements; the regular scheme deliberately doesn't.
5. In the SophiaAAC target → Signing & Capabilities, check automatic signing and your team. Under iCloud, enable CloudKit and select/create the container named in the local configuration. Background Modes already includes Remote notifications. If a capability isn't displayed, use + Capability to add iCloud, then select the same container.
6. Connect and unlock your iPad, trust this Mac if prompted, and enable Developer Mode in iPad Settings → Privacy & Security if needed. Select the iPad as the run destination and press Run.
7. On the iPad, sign into iCloud and allow iCloud Drive/app access. Open Parent space → Storage & backup to check account availability. This status doesn't prove all records have synced.
8. Test creating and editing a profile, custom photo, category, word, and favorite on one iPad, then verify them on a second iPad signed into the same Apple Account. Verify deletions too. Sync is eventual; local communication must continue offline.

Both schemes use the same named SwiftData store; enabling sync must not reset the local board. Do not change the app's bundle identifier after personal data is created without first exporting a backup.

Real iCloud sync requires a provisioned container and signed devices. Simulator/local data tests cannot establish that cross-device sync works. Account switching and iCloud restrictions must be checked on real devices before release.

## Parent editing and backups

Open **Parent space**, solve the parent check, then choose a profile's options to select, edit, export, or delete it. Open **Edit …’s words** to manage categories and words. Swipe or long-press for edit/delete actions. Use Edit to reorder categories or cards. Words may use a label, custom spoken phrase, photo or library picture/emoji, and favorite flag.

The card editor suggests pictures as you enter the label. Tap a suggestion to choose it, or choose **Browse picture library** to search all 3,557 bundled pictures by name or tag. Clear the search to browse all pictures. There is an explicit no-results state with an option to show all pictures. Selecting a library picture replaces the draft photo; Cancel leaves the saved card unchanged. Changing a label alone never changes the chosen picture or custom spoken phrase. You can still choose a personal photo or use the custom emoji option.

Library images are bundled once. Cards keep only a shared symbol or library identifier, so no image data is duplicated into cards, CloudKit records, or backups for library selections. The larger collection adds an optional `libraryID` to cards. Existing cards keep their original symbols/photos, and backups without that field still restore. New exports include it when needed; images are never duplicated in the backup for bundled-library selections.

Export makes a separate JSON backup including photos. Restore adds a new profile and never overwrites an existing board. iCloud sync propagates deletions; it isn't an independent backup. Keep exported files private.

## Tests

Choose an available iPad simulator ID from `xcrun simctl list devices available`, then run:

```sh
xcodebuild -project Sophia-AAC.xcodeproj -scheme Sophia-AAC \
  -destination 'platform=iOS Simulator,id=YOUR_IPAD_SIMULATOR_ID' \
  -derivedDataPath /tmp/SophiaDerived CODE_SIGNING_ALLOWED=NO test
```

Unit tests cover starter board ownership, speech fallback, persistence after reopening the store, backup round trips/validation, deletion isolation, picture-search ranking/tags, catalog asset availability, and library identifier backup compatibility. UI tests cover card selection, sentence controls, category filtering, parent entry, creating a word, suggested picture selection, full-library search, and keeping card text unchanged.

`Scripts/generate-project.py` regenerates the committed project with Python's standard library. It includes Swift files from Sources, Tests, and UITests, the asset catalog, and privacy manifest. Configuration/Signing.local.xcconfig must never become a project reference or get committed. Regenerating replaces manual project edits; put repeatable changes into the generator.

## Choosing a voice

Open Parent space → Voice → Choose a voice. Tap a name to select it, or the play button to preview it. The chosen identifier is saved locally and used for all cards and sentences. Voices are grouped by the selected language and labeled Standard, Enhanced, or Premium. Changing languages resets the choice to that language’s system default. An unavailable voice falls back to the system voice so communication still works.

Download additional voices in Settings → Accessibility → Read & Speak (Spoken Content on some iPadOS versions) → Voices, then return to Sophia or tap Refresh voices. Only voices made available to apps by Apple can be selected. Availability varies by device and language. Voice downloads and the saved selection are device-specific; they are not copied between iPads by CloudKit.

## Rebuilding the expanded symbols

`Scripts/import-symbols.py SOURCE_CHECKOUT REPOSITORY_ROOT` renders the Mulberry collection using `rsvg-convert` and adds the project’s chicken-wings SVG. The imported revision is `9cbab9f400c5de44e2bc58839cca07294aadb086` from https://github.com/mulberrysymbols/mulberry-symbols. Preserve the license, attribution, upstream symbol IDs, and custom SVG when rebuilding.

The parent check uses its own number buttons so the system’s floating number keyboard cannot cover the question. The voice picker lists installed voices Apple exposes to apps for the selected language, excluding Eloquence and Novelty. New downloads from other groups can appear after Refresh voices. Remove unwanted downloads in iPad Settings; Sophia cannot delete system voices. Siri voices are not exposed through Apple’s AVSpeechSynthesizer API.
