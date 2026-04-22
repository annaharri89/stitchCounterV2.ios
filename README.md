# Stitch Counter (iOS)

[![CI](https://github.com/annaharri89/stitchCounterV2.ios/actions/workflows/ci.yml/badge.svg)](https://github.com/annaharri89/stitchCounterV2.ios/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)

iOS app for knitting and crochet projects: single and double counters, a project library, photos per project, a handful of color themes (light/dark), and zip backup/restore that matches the Android app. Nothing syncs to the cloud unless you export the zip yourself.

Swift/SwiftUI port of [stitchCounterV2](https://github.com/annaharri89/stitchCounterV2) (Android). Older app: [Stitch Counter](https://github.com/annaharri89/stitchCounter).

## What’s in here

SwiftUI + SwiftData for projects. Backups are zips with `backup.json` in the same shape as Android (`LibraryBackupManager`; tests keep the JSON keys aligned). Six themes, alternate app icons via `ThemeService`. XCTest lives under `StitchCounterTests/`. Build and test in Xcode.

## Links

- [Android (open testing)](https://play.google.com/apps/testing/dev.harrisonsoftware.stitchCounter)
- [Android README (screenshots)](https://github.com/annaharri89/stitchCounterV2/blob/main/README.md)
- [LinkedIn](https://www.linkedin.com/in/anna-harrison-83a38628/) 
- [Developer Portfolio](https://harrisonsoftware.dev) 
- [Contact](https://harrisonsoftware.dev/contact)

## Stack

| | |
| --- | --- |
| Swift, SwiftUI | min iOS 17 (`IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project) |
| SwiftData | [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) for zips |
| Strings | `Localizable.xcstrings` |


## Tech choices

- SwiftUI entry in `StitchCounterApp`; navigation/sheets via `AppCoordinator` / `ContentView`.
- Data stays on device; no cloud.
- Export/import zip with metadata + images; fine for moving between phones or swapping with the Android build.

## Features

- Single and double counter modes (stitches / rows)
- Project library: create, open, bulk delete
- Six themes, light/dark; theme can change the alternate icon
- Works on phones, portrait and landscape
- Up to six photos per project (files under Documents—see `ProjectImageSelectorView` / `ProjectService`)
- Zip export/import compatible with Android backups
- No analytics; privacy links live in `AppConstants` / settings

## Run it

Open `StitchCounter.xcodeproj`, pick the StitchCounter scheme, run on a simulator or device. Tests: ⌘U or `xcodebuild test`.

## Development

| | |
| --- | --- |
| Xcode | **15.0+** (iOS 17 SDK). The project sets `IPHONEOS_DEPLOYMENT_TARGET` to 17.0 and Swift language mode **5.0** (`SWIFT_VERSION` in `StitchCounter.xcodeproj`). Last opened with **Xcode 26.4.1** (build 17E202) on the maintainer machine—newer Xcode is fine. |
| SwiftLint / SwiftFormat | Not configured in-repo; follow the style of nearby code. |
| CI | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs `xcodebuild test` on pull requests and pushes to `main` on GitHub’s **`macos-15`** image (default **Xcode 16.4**, build **16F6** on the current runner image), targeting any available iOS simulator on the runner. |

## Contributing

Use [GitHub Issues](https://github.com/annaharri89/stitchCounterV2.ios/issues) for bug reports and small feature ideas. For larger changes, open an issue first so direction matches the rest of the app.

Pull requests should keep the diff focused, run the `StitchCounter` scheme tests locally (⌘U or `xcodebuild test`), and match existing naming and SwiftUI structure.

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

Run `StitchCounterTests` before you merge anything big.

## License

Apache License 2.0. See [LICENSE](./LICENSE).

## Roadmap
- custom app icons
- expansion on accessibility features
- stats
