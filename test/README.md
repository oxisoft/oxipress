# Tests

Test layout follows the layered approach described in `docs/phases-overview.md`.

## Directories

- `test/unit/<feature>/...` — pure-Dart tests for domain models, parsers, path utilities, `Result`, etc. No Flutter binding required, no IO.
- `test/widget/<feature>/...` — widget tests with Riverpod overrides; adapters faked.
- `test/golden/...` — golden tests (pixel-comparison) for theme rendering and critical layouts. Empty in Phase 0; populated from Phase 1 onward.
- `test/helpers/` — shared test utilities (e.g. `pumpApp`, fake builders).
- `integration_test/` — full-app flows. First integration test arrives in Phase 1.

## Conventions

- One test file per source file (`<src_path>_test.dart`).
- Group related expectations under `group(...)`.
- Use the in-memory fakes shipped alongside each interface (e.g. `InMemoryStorage`, `FakeProcessRunner`) instead of mocks where a fake exists.
- Reach for `mocktail` only when no fake is available and behavior verification is needed.
- Widget tests must override the providers they exercise via `ProviderScope.overrides` rather than relying on real plugin implementations.

## Running

```
flutter analyze
flutter test
```

CI runs both on Linux, macOS, and Windows (see `.github/workflows/ci.yml`).
