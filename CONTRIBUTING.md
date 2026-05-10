# Contributing to OxiPress

Thanks for your interest. This file is a placeholder; full contribution guidelines land in Phase 11.

## Quick start

1. Install Flutter 3.41.x stable.
2. On Linux, install desktop dependencies:
   ```
   sudo apt-get install -y ninja-build libgtk-3-dev clang cmake pkg-config
   ```
3. Resolve packages and run checks:
   ```
   flutter pub get
   flutter gen-l10n
   flutter analyze
   flutter test
   ```

## Phased delivery

Implementation follows the plan in `docs/phases-overview.md`. Each phase ends in a user-testable build with tests; PRs should target the current phase and not jump ahead.

## Releases

Releases are tag-driven and produced entirely by CI.

1. Bump `version:` in `pubspec.yaml` (e.g. `1.0.0+1`) and `AppInfo.version` in `lib/app/app_info.dart`. Commit and push to `main`.
2. Tag the same commit with the matching version prefixed by `v` and push the tag:
   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. The `Release` workflow verifies the tag matches `pubspec.yaml`, builds Linux / macOS / Windows release binaries on GitHub-hosted runners, and publishes a GitHub release with the artifacts attached.

If the tag and pubspec versions disagree, the workflow fails before building. Pre-release tags (containing `-`, e.g. `v1.0.0-beta.1`) are published as GitHub pre-releases.

## Code style

- `analysis_options.yaml` enforces strict casts/raw-types/inference and the curated lint set.
- New code touching the OS goes through an interface defined in `lib/core/` or a feature folder, with a real implementation **and** a fake for tests.
- Domain models are immutable. Use `Result<T, E>` at fallible boundaries.
- Tests live next to the source: `test/unit/<feature>/...`, `test/widget/<feature>/...`. See `test/README.md` for conventions.
