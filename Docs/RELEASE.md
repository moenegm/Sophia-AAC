# Release checklist

Complete device verification and App Store setup before distribution.

- [ ] Review the board with the parent/caregiver using the intended iPad. Starter words and emojis are examples, not a clinical communication plan. Replace them with familiar content as needed.
- [ ] Verify VoiceOver labels, large text, portrait and landscape, Split View, photo cropping, touch targets, and muted/low-volume/audio-interruption behavior on a real iPad.
- [ ] Test profile/category/card create, edit, reorder, delete, favorites, photos, backup export/import, and persistence after relaunch.
- [ ] Test private iCloud sync on two iPads using the same Apple Account, including edits/deletions, offline changes, account restrictions, and signing out. Confirm local data remains accessible according to the intended account-switching behavior.
- [ ] Validate speech for configured languages, including offline use after required voices are downloaded.
- [ ] Remove the entire `legacy/` directory before the first TestFlight, App Store, or other public release. It is a temporary Rails reference only. Release and CloudRelease builds deliberately fail while it exists. Removing it from the working tree does not erase Git history.
- [ ] Verify no Rails files, historical credentials, test data, or signing configuration are in the app bundle. The Xcode target includes only Sources, Assets.xcassets, and PrivacyInfo.xcprivacy.
- [ ] Confirm final app icon, screenshots, support URL, privacy policy, privacy answers (including private iCloud storage), age rating, and any applicable Kids Category requirements accurately reflect the final app. No ads, tracking SDKs, analytics, or third-party speech service are included.
- [ ] Register final bundle/container identifiers under the correct team and verify CloudKit schema in development. Promote the schema to production in CloudKit Console before TestFlight/App Store distribution.
- [ ] Remove `--demo` from release launch/testing assumptions. Archive with the **Sophia-AAC iCloud** scheme and inspect signing/entitlements, including the production push environment selected during distribution signing.
- [ ] Validate and upload through Xcode Organizer; test the distributed build before making it public.
- [ ] After a public app URL exists, add the Sophia-AAC card to the portfolio Projects page using the existing style.

Apple references:
- https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
- https://developer.apple.com/help/account/manage-identifiers/enable-app-capabilities/
- https://developer.apple.com/app-store/review/guidelines/
