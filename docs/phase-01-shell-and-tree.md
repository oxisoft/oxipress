# Phase 1 — Shell + file tree

## Goal

User opens a Hugo project via folder picker, the three-panel layout appears with draggable splitters, the left panel shows the project's `content/` tree (read-only), and panel sizes / collapsed states persist per project across restarts.

## Scope (in)

- **Open project flow**
  - Native folder picker (`file_picker` package or platform equivalent).
  - Hugo site validator: presence of `hugo.toml | hugo.yaml | hugo.json` (or legacy `config.*`) at root **and** a `content/` directory; rejects with clear error otherwise.
  - Recent projects list (last 10), persisted to `~/.config/oxipress/recent.json` (OS-equivalent path resolved via `Paths`).
- **Welcome screen** (replaces Phase 0 placeholder)
  - Recent projects list with last-opened timestamp.
  - "Open project" button.
  - "Documentation" link (no-op stub for now).
- **Three-panel layout**
  - `multi_split_view` (or wrapper). Default split 20% / 50% / 30%.
  - Each panel has a header with title, panel-actions slot, and collapse button.
  - Collapsed and resized state persisted **per project** (keyed by project path).
- **Top toolbar shell** with stub slots: project name, branch placeholder, Hugo status placeholder, Save button (no-op for now), Settings button (opens empty stub).
- **Bottom status bar shell**: cursor position placeholder, current file placeholder, last save placeholder.
- **Left panel — file tree (read-only)**
  - Tree rooted at `content/` by default; toggle to "project root" view (read-only this phase; CRUD restrictions land in Phase 4).
  - Folder expand/collapse with state persisted per project.
  - Selection state (visual highlight only — no editor wiring yet).
  - File system watcher (`watcher` package): auto-refresh on external changes.
- **Middle / right panels**: empty placeholder text ("Open a markdown file" / "Preview unavailable until Hugo is running").
- **Close project**: clears state, returns to welcome.
- **Test fixture**: commit `test-fixtures/sample-site/` (~10 pages, 2 sections, minimal theme) for manual + integration testing.

## Out of scope

- Editor functionality (Phase 2).
- File CRUD (Phase 4).
- Hugo serve (Phase 5).
- Preview panel content (Phase 5).
- Git status (Phase 7).
- Settings UI body (Phase 10).

## New components / interfaces

- `ProjectRepository`: validate, open, close, list recents.
- `Project` model (path, config kind, opened-at).
- `FileSystem` interface + `RealFileSystem` + `InMemoryFileSystem`.
- `FileWatcher` interface + `WatcherFileWatcher` + fake.
- `FileTreeController` (Riverpod Notifier).
- `PanelLayout` widget; persisted via `Storage`.
- `ProjectStateStore` — per-project persistence (panel sizes, expanded folders, and later open tabs).

## Tests

- **Unit**: Hugo site validator (positive / negative cases); recents list (add, dedupe, cap at 10, removal of missing paths); panel-state serialization round-trip; tree node sort order; `Paths` per-OS recents file location.
- **Widget**: welcome screen with recents; three-panel layout splitter drag + persist; collapse toggle; file tree expansion against `InMemoryFileSystem`; selection highlight.
- **Integration**: open fixture site → tree appears with expected nodes → restart app → recents list contains the project → reopen → expanded folders restored.

## User acceptance checklist

- [ ] Welcome screen lists recent projects (empty initially).
- [ ] "Open project" picker rejects a non-Hugo folder with a clear message.
- [ ] Opening the fixture site shows the three panels.
- [ ] Splitters drag smoothly; sizes persist after relaunch.
- [ ] Each panel collapses / expands via header toggle; state persists.
- [ ] Tree shows `content/` rooted; folders expand / collapse; state persists.
- [ ] Toggle to project-root view switches root visibly.
- [ ] External edit (touch a file from terminal) appears in the tree without manual refresh.
- [ ] Closing the project returns to welcome cleanly.

## Risks and spikes

- macOS file watcher reliability under high write rates (per spec §12). Validation script: create 1000 files in a watched dir and verify all are observed.
- `multi_split_view` behavior with collapsed panels — ensure persisted sizes restore correctly across collapse/expand cycles.

## Depends on

- Phase 0.
