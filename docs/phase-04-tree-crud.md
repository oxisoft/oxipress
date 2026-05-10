# Phase 4 — File-tree CRUD

## Goal

User creates, renames, duplicates, and deletes files and folders via the tree's context menus, with confirmation on destructive operations. Open tabs follow rename and close on delete.

## Scope (in)

- **Right-click on folder**: New File, New Folder, Rename, Delete, Reveal in OS file manager.
- **Right-click on file**: Open, Rename, Delete, Duplicate, Reveal in OS file manager.
- **New File dialog**:
  - Filename input.
  - Optional template toggle: prefills body with the front matter stub from spec §4.4 (humanized title, ISO 8601 `now`, `draft: true`).
  - Format follows the user's default front matter format (Phase 10 setting; YAML default until that lands).
- **Rename**: inline edit; updates open tabs; refuses to overwrite an existing file.
- **Delete**: confirmation dialog; closes any open tab on the deleted file.
- **Duplicate**: same dir; auto-suffixed name (`-copy`, then `-copy-2`, etc.).
- **Reveal in OS file manager**: per-OS command (`open -R` macOS, `xdg-open` parent dir Linux, `explorer /select,` Windows).
- **CRUD restriction in project-root view**: writes only allowed inside `content/`, `static/`, `assets/`, `data/`, `layouts/`. Other dirs render as read-only with grayed context-menu items.

## Out of scope

- Drag-drop reorder in tree (deferred to v2).
- Multi-select in tree (deferred to v2).
- Trash / undo for delete (deferred — confirmation is the safety net).

## New components / interfaces

- `FileTreeMutations` use-cases: createFile, createFolder, rename, delete, duplicate.
- Per-OS `RevealInFileManager`.
- `FilenameTemplate` (humanize, ISO date now).
- Path-allowed predicate for project-root mode.

## Tests

- **Unit**: filename humanization; duplicate auto-suffix collision logic; allowed-path predicate; rename overwrite refusal; reveal-in-OS command selection per platform.
- **Widget**: context menu rendering on folder vs file; new-file dialog template toggle; rename inline edit; delete confirmation; tab follows rename / closes on delete.
- **Integration**: create new post in fixture site → visible in tree → opens in editor → rename → tab updates → delete → tab closes.

## User acceptance checklist

- [ ] New File from folder context menu creates file with template.
- [ ] New Folder works.
- [ ] Rename updates tree and any open tab.
- [ ] Delete prompts confirmation; closes open tab.
- [ ] Duplicate creates `<name>-copy.md`; second time `<name>-copy-2.md`.
- [ ] Reveal opens OS file manager at the correct location on macOS / Linux / Windows.
- [ ] Project-root view: cannot create files outside allowed directories.

## Risks and spikes

- Windows file-manager `explorer /select,` argument quoting — verify with paths containing spaces and unicode.
- Cross-platform filename validation (reserved names on Windows, case sensitivity on macOS).

## Depends on

- Phase 3.
