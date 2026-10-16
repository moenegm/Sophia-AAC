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
- Physical iPad installation attempted; the paired device connection dropped. Reconnect over USB and unlock the iPad before retrying. No successful device installation or live iCloud startup is claimed.

## Still requires a hands-on iPad check

- Real iCloud sync across two signed-in iPads, including photos, edits, deletions, offline changes, and account switching/restrictions.
- Actual audio output, downloaded/offline voices, interruptions, and volume behavior.
- The parent's chosen iPad, accessibility settings, portrait/Split View, custom photos, and Files-based backup export/import.
- CloudKit production schema, distribution signing, App Store metadata/privacy answers, and release checklist.

The Apple account and signing setup work on this Mac; no additional account sign-in was needed. No production release has been made. Personal signing identifiers are kept in the ignored `Configuration/Signing.local.xcconfig` file.
