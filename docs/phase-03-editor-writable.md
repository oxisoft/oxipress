# Phase 3 — Editor writable + save

## Goal

User edits raw markdown body and front matter form, saves with Ctrl/Cmd+S or on blur, and sees the file change on disk. Modified state visible in the tree and tab. Find/Replace within the current file works.

## Scope (in)

- **Raw markdown body**: editable.
- **Front matter form**:
  - Known fields: typed inputs (text for title/description/slug, datetime picker for date, switch for draft, chip-list for tags/categories).
  - Unknown fields: editable KV rows; add / remove rows.
  - Original format preserved on save (YAML stays YAML, TOML stays TOML, JSON stays JSON).
  - Key order preserved.
- **Save**
  - Ctrl/Cmd+S manual.
  - Auto-save on blur (configurable; default on; setting wired into Phase 10 UI).
  - Toolbar Save button.
  - Atomic writes (write to temp + rename) to avoid Hugo serve picking up partial files.
- **Modified indicators**
  - Asterisk in tab title and tree node when buffer differs from disk.
  - Cleared on save.
- **External-change detection**
  - Watcher fires for currently-open file → if buffer is unchanged: silently reload. If buffer is dirty: prompt (keep mine / load disk / diff later).
- **Find / Replace within current file** (Ctrl/Cmd+F, Ctrl/Cmd+H).
  - Case sensitivity, whole word, regex toggles.
  - Match count, prev/next, replace, replace all.

## Out of scope

- Rich-text mode (Phase 9).
- Multi-file find / replace (deferred to v2).
- Drag-drop image (Phase 9).
- Build / preview integration (Phase 5).

## New components / interfaces

- `EditorBuffer` (per-tab dirty state, undo/redo).
- `FrontmatterSerializer` (round-trip YAML/TOML/JSON preserving format and order).
- `AtomicFileWriter` on `FileSystem`.
- `FindReplaceController`.
- `AutoSavePolicy` (Riverpod-injected; respects user setting).

## Tests

- **Unit**: serializer round-trips for YAML/TOML/JSON (a fixture set including arrays, nested maps, dates, multi-line strings, comments — comment policy documented and tested); `EditorBuffer` undo/redo; modified-state derivation; atomic write under simulated crash; find/replace regex correctness.
- **Widget**: typing into raw editor flips modified state; save clears asterisk; auto-save on blur; front matter form edits round-trip through serializer; find/replace UI flows; conflict prompt when external change arrives mid-edit.
- **Integration**: open file → edit → save → re-open → content correct; edit + auto-save on blur; external edit handled.

## User acceptance checklist

- [ ] Type in body → asterisk appears in tab and tree.
- [ ] Ctrl/Cmd+S → asterisk clears; file changes on disk.
- [ ] Auto-save on blur works.
- [ ] Edit known front matter field via typed input → saves correctly.
- [ ] Add unknown KV row → saves and parses next open.
- [ ] YAML stays YAML; TOML stays TOML.
- [ ] Find / Find-and-replace work; regex toggle works.
- [ ] External-change prompt appears when expected.

## Risks and spikes

- Round-trip fidelity for YAML / TOML — especially comments. Decide a policy (drop or preserve) and pin it via fixtures.
- Race between auto-save on blur and manual save (debounce design).

## Depends on

- Phase 2.
