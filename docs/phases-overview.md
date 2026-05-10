# OxiPress — Implementation phase plan

Derived from `oxipress-requirements.md`. Each phase is independently user-testable on Linux, macOS, and Windows. Each phase ships with tests and is shippable as an internal build.

## Goals of the phasing

- Every phase delivers a feature the user can exercise end-to-end on all three desktop OSs.
- Every phase introduces only as much architecture as it needs.
- Architecture is pluggable behind interfaces so subsequent phases extend without rewrites.
- Every phase ships unit + widget tests for new code; integration tests are added once end-to-end flows become reachable (Phase 1 onward).

## Architectural principles (apply to all phases)

1. **Feature-first folder structure** per `oxipress-requirements.md` §9. Each feature owns its own `data/`, `domain/`, `ui/` subfolders.
2. **Layered inside each feature**:
   - `data/` — file IO, process IO, parsers, repositories.
   - `domain/` — pure Dart models, use-cases. No Flutter. No IO.
   - `ui/` — widgets + Riverpod controllers.
3. **Cross-feature communication via Riverpod providers only.** Features do not import each other's widgets or notifiers.
4. **Pluggable adapters behind interfaces for everything that touches the OS**: process runner, file system, file watcher, git repository, Hugo server, webview, PTY backend, storage. Each interface ships a real implementation **and** an in-memory fake for tests.
5. **Domain models are immutable** (Freezed). Codecs via `json_serializable` where persisted.
6. **`Result<T, E>`** at fallible boundaries. Exceptions only for programmer errors.
7. **No global singletons.** Everything via Riverpod providers, overridable in tests.
8. **Path safety**: use the `path` package. Never string-concatenate paths.
9. **No business logic in widgets.** Widgets read controller state only; controllers (Notifiers) own logic.
10. **Each feature exposes a small public surface** (one or two providers + the types they expose). The rest is private to the feature.
11. **Cross-platform first.** Dependencies must support Linux/macOS/Windows or be abstracted behind a per-platform interface. A 1-day spike is required before adopting any risky cross-platform dependency.

## Testing approach

Tests are authored alongside production code in every phase, not deferred:

- **Unit** (`test/unit/<feature>/...`): pure Dart for domain, parsers, URL computation, path utils, `Result`. Fastest tier; should dominate the pyramid.
- **Widget** (`test/widget/<feature>/...`): per-feature widget tests with Riverpod overrides; adapters faked.
- **Golden** (`test/golden/...`): theme rendering, splitter layouts, list rows.
- **Integration** (`integration_test/...`): full-app flows against the fixture Hugo site at `test-fixtures/sample-site/` (introduced in Phase 1).

CI (introduced in Phase 0) runs `flutter analyze`, unit, widget, and golden tests on Linux/macOS/Windows. Integration tests run on the same matrix once Phase 5 lands.

## Cross-platform strategy

- Stick to dependencies with first-class Linux/macOS/Windows support.
- Run a 1-day spike for any risky cross-platform dependency before adopting it. Phases that require a spike are flagged in the phase file.
- Filesystem watcher reliability on macOS validated in Phase 1.
- Webview library decision spiked in Phase 5.
- PTY/terminal library decision spiked in Phase 8.
- Rich-text round-trip fidelity spiked in Phase 9.

## Phase index

| #  | Phase                                         | User-testable outcome                                                                                                                                                |
|----|-----------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 0  | Foundation                                    | App launches on all 3 OSs, shows welcome placeholder, persists window size/position, quits cleanly. CI green.                                                       |
| 1  | Shell + file tree                             | Open Hugo project, three-panel layout with splitters, file tree under `content/`, panel state persisted per project.                                                |
| 2  | Markdown viewer + tabs                        | Click `.md` files → read-only display of front matter + body in tabs. Non-markdown files open in OS default app.                                                    |
| 3  | Editor writable + save                        | Edit raw markdown + front matter form; save with Ctrl/Cmd+S and on blur; find/replace within file.                                                                  |
| 4  | File-tree CRUD                                | New / rename / duplicate / delete / reveal via context menus, with confirmation on destructive operations.                                                           |
| 5  | Hugo serve + preview                          | Hugo serve auto-starts; right panel shows live site; clicking a file navigates preview; LiveReload on save.                                                         |
| 6  | Drawer + build log                            | Toggleable bottom drawer; Build tab streams Hugo logs; clickable errors.                                                                                            |
| 7  | Git integration                               | Status badge, stage/commit/push/pull/fetch via panel, tree git indicators, output streamed to Git tab.                                                              |
| 8  | Embedded terminal                             | Terminal tab opens user shell in project root; multiple terminals; ANSI colors; clean exit.                                                                          |
| 9  | Rich-text editor + image drop                 | Toggle raw↔rich; lossless round-trip for CommonMark; drag-drop image into editor.                                                                                  |
| 10 | Theming + Settings UI                         | Live theme switching; user themes from `~/.config/oxipress/themes/`; Settings panel covers all spec items.                                                           |
| 11 | First-run setup, shortcuts, i18n, release     | Hugo/git detection screen; full keyboard shortcut set; quick-open + command palette; English/Polish/Russian; acceptance sign-off.                                    |

## How to use this plan

Each `phase-XX-*.md` file is the work order for that phase. Every phase file contains:

- **Goal** — user-testable end state.
- **Scope (in)** — what is built.
- **Out of scope** — what is explicitly deferred.
- **New components / interfaces** — the abstractions introduced.
- **Tests** — unit / widget / golden / integration to add.
- **User acceptance checklist** — what the user manually verifies.
- **Risks and spikes** — anything to validate early.
- **Depends on** — prior phases required.

Phases must be merged in numeric order (dependencies are linear). Inside each phase, work items can be parallelized between contributors.
