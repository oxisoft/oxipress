# OxiPress

Cross-platform desktop editor for Hugo sites: three-panel authoring (file tree, content editor, live preview), embedded terminal, basic git workflow, and a JSON-driven theming system.

**Status:** Pre-alpha. Phase 0 (foundation) lands the empty app shell. See `docs/phases-overview.md` for the full delivery plan.

- **Repository:** `github.com/oxisoft/oxipress`
- **License:** MIT (see `LICENSE`)
- **Targets:** Linux (Ubuntu 22.04+), macOS (12+), Windows (10+)
- **Stack:** Flutter (stable), Dart 3.x, Riverpod

## Build prerequisites

- Flutter SDK 3.41.x (stable channel)
- Linux only: `ninja-build libgtk-3-dev clang cmake pkg-config`

## Local development

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

## Documentation

- `docs/oxipress-requirements.md` — full v1 requirements
- `docs/phases-overview.md` — phased implementation plan
- `docs/phase-XX-*.md` — one work order per phase

## Contributing

See `CONTRIBUTING.md`.
