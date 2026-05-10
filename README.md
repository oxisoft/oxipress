# OxiPress

[![Analyze](https://github.com/oxisoft/oxipress/actions/workflows/analyze.yml/badge.svg?branch=main)](https://github.com/oxisoft/oxipress/actions/workflows/analyze.yml)
[![Test](https://github.com/oxisoft/oxipress/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/oxisoft/oxipress/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/oxisoft/oxipress/graph/badge.svg?branch=main)](https://codecov.io/gh/oxisoft/oxipress)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%20%7C%20Windows-informational)](https://flutter.dev/desktop)

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
