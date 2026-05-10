# Phase 2 — Markdown viewer + tabs

## Goal

Click a `.md` file in the tree → it opens in the middle panel as a read-only view: front matter parsed and shown as a typed display, body shown as raw markdown with syntax highlighting. Multiple files open as tabs. Reopen previously-open tabs on project reload. Click on a non-markdown file → opens in the OS default app.

## Scope (in)

- **Editor tab bar** above the middle panel.
  - Multiple tabs, switchable by click.
  - Close via x, middle-click, Ctrl/Cmd+W.
  - Active tab persisted per project.
  - Reopen previously-open tabs on project load.
- **File open**
  - Click `.md` → opens or activates an editor tab.
  - Click non-`.md` → `Process.run` with OS default opener (`open` on macOS, `xdg-open` on Linux, `start ""` on Windows).
- **Front matter parser**
  - YAML and TOML support; format auto-detected and recorded.
  - `+++` (TOML) and `---` (YAML) delimiters.
  - JSON also accepted.
  - Returns a domain model (`Frontmatter` with format + ordered key/value map).
- **Editor view (read-only this phase)**
  - Front matter section: typed read-only display for known fields (title, date, draft, tags, categories, description, slug); unknown fields shown as KV rows.
  - Body section: raw markdown with syntax highlighting via `flutter_code_editor` or `code_text_field`.
  - "Rich" / "Raw" toggle is shown but disabled — Rich mode is Phase 9.
- **Status bar** updates: current file path, cursor position (line/column).

## Out of scope

- Editing / saving (Phase 3).
- Find / Replace (Phase 3).
- Rich-text mode (Phase 9).
- Image drop (Phase 9).
- Auto-save (Phase 3).

## New components / interfaces

- `FrontmatterParser` (YAML / TOML / JSON) + `FrontmatterSerializer` (used in Phase 3).
- `MarkdownDocument` model (frontmatter + body + raw source + format).
- `EditorController` (Riverpod Notifier) — read-only API surface this phase.
- `OpenFiles` provider — tab list, active tab, persistence hooks.
- `OsOpener` interface + per-OS `RealOsOpener` + fake.

## Tests

- **Unit**: front matter parsing for YAML/TOML/JSON; round-trip key order preservation (parse + re-serialize byte-equivalent on a fixture set); known-field typing; malformed front matter handled with a clear error; OS opener per-platform command resolution; tab list behaviors (add, activate, close, persist, restore).
- **Widget**: tab bar interactions; opening multiple files; non-md click triggers `OsOpener` (faked); read-only front matter display; body syntax highlighting renders.
- **Integration**: open fixture site → click a post → verify content matches file → close → reopen project → tab restored.

## User acceptance checklist

- [ ] Click a markdown file → opens in editor tab.
- [ ] Open multiple files → multiple tabs.
- [ ] Switch tabs, close tabs (x button + middle-click + Ctrl/Cmd+W).
- [ ] Active tab persists across restart.
- [ ] Click an image or partial → opens in OS default app.
- [ ] Front matter renders as typed fields; unknown fields render as KV rows.
- [ ] Body renders with syntax highlighting.
- [ ] Status bar shows file path and cursor position.

## Risks and spikes

- Code editor library choice: validate `flutter_code_editor` vs `code_text_field` for performance on a 5,000+ line markdown file.
- Front matter format detection edge cases (trailing newlines, BOM, mixed line endings).

## Depends on

- Phase 1.
