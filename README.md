# Roads Map (Heavy Vehicles Road Network WA)

Flutter application for viewing and interacting with Western Australia heavy vehicle road network data using MapLibre.

## Overview

Roads Map provides a map-first experience for heavy vehicle route planning and network exploration. The app combines:

- MapLibre map rendering and style switching.
- Road network and POI layer filtering.
- Place search and location lookup.
- Feature tap details (for roads, incidents, services, and related map entities).
- Persisted app settings and map selections using Hive.

## Tech Stack

- Flutter (SDK >= 3.4.1 < 4.0.0)
- Riverpod and Hooks Riverpod for state management
- Hive CE for local persistence
- MapLibre GL for map display and interaction
- Dio for network requests
- Freezed and Json Serializable for typed models

## Project Structure

Primary directories:

- `lib/widgets/`: UI screens and composable widgets (map, navigation panel, feature display)
- `lib/providers/`: app and map state, layer coordination, network/POI selections
- `lib/services/`: external services (traffic, places, online layers)
- `lib/features/navigation/`: source parsing and directed road graph models
- `lib/models/`: data models and generated adapters/serializers
- `lib/utils/`: constants, map style utilities, icon and layer helpers
- `assets/`: JSON configs, icons, fonts, and geo assets

The Main Roads edge builder accepts an explicitly selected source part and
inclusive vertex range; it does not discover junctions or build a graph.
Each edge retains the original feature attributes and its own ordered geometry.
Reversing an edge reverses its geometry, not the source attributes or their
feature-wide SLK and distance ranges. Network metadata is not interpreted:
Tandem Drive Network 1's exclusion-road semantics are not generalized to
other networks.

The production Main Roads layer-78 loader records the source WKID, requested
output WKID, and any datum transformation in its load result. Exact coordinate
identity is only meaningful within the same recorded CRS and transformation
contract; coordinates from different contracts must not be joined by equality.

## Requirements

Install the following before running locally:

- Flutter SDK (matching project constraints)
- Dart SDK (bundled with Flutter)
- Android Studio or Xcode tooling (depending on target platform)
- A connected device or emulator/simulator

## Getting Started

1. Install dependencies:

```bash
flutter pub get
```

2. Generate Riverpod/Freezed/JSON/Hive code artifacts:

```bash
dart run build_runner build --delete-conflicting-outputs
```

3. Run the app:

```bash
flutter run
```

## Development Commands

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Regenerate code while developing:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Local PR checks

Enable the version-controlled hooks in each fresh clone:

```powershell
git config core.hooksPath .githooks
git config --get core.hooksPath
```

The second command should print `.githooks`. Before a commit, the hooks check
Dart formatting and run `flutter analyze`. Before a push, they also run
`flutter test` and check the committed diff for whitespace errors against
`origin/main`, or local `main` if the remote-tracking branch is unavailable.
No fetch is required.

Run a local PR-style review from the repository root with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tool/local_review.ps1
```

The review runs the full checks and shows branch commits and a diff summary.
Hooks can be bypassed with Git's `--no-verify` in an emergency, but should not
be bypassed routinely.

## Configuration Notes

- App initialization registers Hive adapters and opens required boxes before UI startup.
- The app is portrait-only (configured in `main.dart`).
- Google Places and map API keys are currently referenced from `lib/utils/constants.dart`.

## Security Recommendation

Move API keys out of source control before production use. Recommended approaches:

- pass keys via `--dart-define`
- load keys from secure platform configuration
- rotate keys and restrict by app signature/bundle identifier

## Build

Android release build:

```bash
flutter build apk --release
```

iOS release build:

```bash
flutter build ios --release
```

## Notes

- Generated files (`*.g.dart`) are expected and required for parts of the app to function.
- If map layers or menu assets appear out of sync, rerun code generation and restart the app.
