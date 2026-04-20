# Stitch Counter (iOS)

iOS app for knitting and crochet projects: single and double counters, a project library, photos per project, a handful of color themes (light/dark), and zip backup/restore that matches the Android app. Nothing syncs to the cloud unless you export the zip yourself.

Swift/SwiftUI port of [stitchCounterV2](https://github.com/annaharri89/stitchCounterV2) (Android). Older app: [Stitch Counter](https://github.com/annaharri89/stitchCounter).

## What’s in here

SwiftUI + SwiftData for projects. Backups are zips with `backup.json` in the same shape as Android (`LibraryBackupManager`; tests keep the JSON keys aligned). Six themes, alternate app icons via `ThemeService`. XCTest lives under `StitchCounterTests/`.

No GitHub Actions in this repo yet—build and test in Xcode.

## Links

- Android (open testing): [Play](https://play.google.com/apps/testing/dev.harrisonsoftware.stitchCounter)
- [LinkedIn](https://www.linkedin.com/in/anna-harrison-83a38628/) · [harrisonsoftware.dev](https://harrisonsoftware.dev) · [Contact](https://harrisonsoftware.dev/contact)

## Screenshots

No images in this repo right now. The [Android README](https://github.com/annaharri89/stitchCounterV2/blob/main/README.md) has screenshots if you want a visual.

## Tech choices (short)

- SwiftUI entry in `StitchCounterApp`; navigation/sheets via `AppCoordinator` / `ContentView`.
- Data stays on device; no cloud.
- Export/import zip with metadata + images; fine for moving between phones or swapping with the Android build.
- Stats screen is still a “coming soon” stub (same as Android today).

## Stack

| | |
| --- | --- |
| Swift, SwiftUI | min iOS 17 (`IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project) |
| SwiftData | [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) for zips |
| Strings | `Localizable.xcstrings` |

## Features

- Single and double counter modes (stitches / rows)
- Project library: create, open, bulk delete
- Six themes, light/dark; theme can change the alternate icon
- Works on phones, portrait and landscape
- Up to six photos per project (files under Documents—see `ProjectImageSelectorView` / `ProjectService`)
- Zip export/import compatible with Android backups
- No analytics; privacy links live in `AppConstants` / settings

## Run it

Open `StitchCounter.xcodeproj`, pick the StitchCounter scheme, run on a simulator or device. Needs Xcode with the iOS 17+ SDK. Tests: ⌘U or `xcodebuild test`.

## Folders

```
StitchCounter/
├── Coordinators/
├── Models/
├── Services/
├── Theme/
├── ViewModels/
├── Views/
│   ├── Components/
│   └── Screens/
├── Resources/
├── Constants.swift
└── StitchCounterApp.swift
```

Run `StitchCounterTests` before you merge anything big. No git hooks in either repo—up to you.

## Shipping a build

Use your Apple Developer team, bump bundle ID if you’re not just on your own device, then Product → Archive and go through App Store Connect / TestFlight as usual.

