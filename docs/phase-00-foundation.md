# Phase 0 — Foundation

## Goal

An empty Flutter desktop app launches on Linux, macOS, and Windows, shows a welcome placeholder, persists window size and position across restarts, and quits cleanly. CI runs analyze + tests on all three OSs.

## Scope (in)

- Flutter project initialized; Linux, macOS, and Windows desktop targets enabled.
- `pubspec.yaml` populated with the foundational dependencies only:
  `flutter_riverpod`, `riverpod_annotation`, `freezed_annotation`, `json_annotation`, `path`, `path_provider`, `shared_preferences`, `logging`, `intl`, `flutter_localizations`. Dev: `build_runner`, `freezed`, `json_serializable`, `riverpod_generator`, `mocktail`.
- Folder layout per `oxipress-requirements.md` §9 created (empty placeholder files allowed where features land later).
- `analysis_options.yaml` with strict lints; warnings treated as errors in CI.
- `core/result.dart` — generic `Result<T, E>`.
- `core/logger.dart` — wraps `package:logging`; structured fields.
- `core/paths.dart` — config dir resolution per OS, common path helpers.
- `core/process_runner.dart` — interface only (no Hugo/git wiring yet) plus a system implementation and an in-memory fake.
- `core/storage.dart` — KV abstraction (`SharedPreferences` impl + `InMemoryStorage` fake).
- `app/window_management.dart` — size/position load/save.
- `app/theme_runtime.dart` — minimal hardcoded dark/light. JSON loading lands in Phase 10.
- `main.dart` boots a `ProviderScope`.
- Welcome screen widget (placeholder text, app name, version).
- l10n bootstrap: `flutter_localizations` wired; one English ARB file; lint or convention preventing hardcoded user strings.
- `test/` harness: shared test helpers, naming conventions documented in `test/README.md`.
- CI: GitHub Actions matrix (Linux / macOS / Windows) running `flutter analyze` + `flutter test`.
- `LICENSE` (MIT), `README.md` placeholder, `CONTRIBUTING.md` placeholder.

## Out of scope

- Project loading.
- File tree, editor, preview, Hugo, git, terminal.
- Theme JSON loading.
- Settings panel UI body.
- i18n languages beyond English.

## New components / interfaces

- `Result<T, E>`.
- `ProcessRunner` interface; `SystemProcessRunner`; `FakeProcessRunner`.
- `Storage` interface; `SharedPreferencesStorage`; `InMemoryStorage`.
- `Paths` helper.
- `Logger` wrapper.
- `WindowManager` (size/position persistence).
- `ThemeRuntime` (minimal).

## Tests

- **Unit**: `Result` combinators; `Paths` per-OS config dir mapping (with mocked platform); `Storage` round-trip via `InMemoryStorage`; `ProcessRunner` fake invocation tracking.
- **Widget**: Welcome screen renders; golden tests for both dark and light themes; `App` wires `ProviderScope` correctly.
- **Integration**: not yet — first integration test arrives in Phase 1.

## User acceptance checklist

- [ ] App launches on macOS 12+, Ubuntu 22.04+, and Windows 10+.
- [ ] Window opens with a welcome placeholder.
- [ ] Resize / move window, quit, relaunch — window restores to last size/position.
- [ ] Quitting via window close on each OS leaves no orphan processes (validated via task manager / `ps`).
- [ ] `flutter analyze` reports zero issues.
- [ ] Unit + widget tests pass on CI for all three OSs.

## Risks and spikes

- Flutter desktop window management on Linux varies by display server (X11 vs Wayland). Validate on Ubuntu 22.04 (X11) and Ubuntu 24.04 (Wayland).
- macOS code signing / notarization is not required for local dev; deferred to Phase 11.

## Depends on

- Nothing.
