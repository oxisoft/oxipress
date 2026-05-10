# Phase 7 — Git integration

## Goal

Toolbar shows accurate branch, ahead/behind, and dirty count. User can stage / commit / push / pull / fetch from a git panel. File tree shows per-file git status indicators. All git output streams to the Git tab in the drawer. Conflicts surface with a clear message.

## Scope (in)

- **Git binary detection** at startup; version >= 2.30 check; result stored in app state.
- **`GitRepository` interface**, system implementation via `Process.run`.
- **Toolbar status badge**: branch, ahead/behind, dirty file count.
  - Refresh on save (debounced) + every 30s + manual.
  - Click → opens git panel.
- **Git panel** (modal or side drawer per UX choice):
  - File list with checkboxes, sectioned: Staged / Unstaged / Untracked.
  - Click a file → unified diff view, syntax highlighted.
  - Commit message field + commit button (commits only checked files).
  - Push button (disabled if no upstream; "Set upstream" prompt offers `git push -u origin <branch>`).
  - Pull, Fetch buttons.
- **Output streaming**: every git command's output goes to the Git drawer tab, retaining the last N commands.
- **Error handling**: snackbar with summary; full output in drawer.
- **Conflict detection**: surface a clear message — "Merge conflict — resolve in your terminal or external tool." Conflict resolution UI is out of scope for v1.
- **Tree indicators** (per spec §4.4):
  - Modified (uncommitted) → yellow indicator.
  - Untracked → green indicator.
  - Deleted (in git, missing on disk) → red strikethrough.

## Out of scope

- Conflict resolution UI.
- Branch creation / checkout UI (use terminal in Phase 8).
- libgit2 backend (v2 — interface is already pluggable).
- GPG signing UI (relies on user's git config).

## New components / interfaces

- `GitRepository` interface + `SystemGitRepository` + `FakeGitRepository`.
- `GitStatus` model (branch, upstream, ahead, behind, files[]).
- `GitFileStatus` enum (staged, modified, untracked, deleted, conflicted).
- `GitDiff` model.
- `GitController` (Riverpod Notifier).
- `GitLogController` (drawer tab).

## Tests

- **Unit**: git output parsers (status, diff, push/pull errors) — fixture-driven; `GitFileStatus` derivation; ahead/behind parsing; refresh debounce.
- **Widget**: git panel sections + checkboxes; commit flow with `FakeGitRepository`; push without upstream → prompt; conflict message rendering; tree indicator rendering by status.
- **Integration**: against a sandboxed git fixture (init repo, make changes) — stage / commit / push to a local bare repo; pull from a second clone; tree indicators correct.

## User acceptance checklist

- [ ] Toolbar shows branch + ahead/behind + dirty count, accurate vs `git status` on disk.
- [ ] Click badge → git panel opens.
- [ ] Stage / unstage via checkboxes.
- [ ] Commit with message → file disappears from dirty.
- [ ] Push to remote works; "Set upstream" prompt appears when needed.
- [ ] Pull / fetch work.
- [ ] Tree shows modified / untracked / deleted indicators correctly.
- [ ] Git output appears in Git drawer tab.
- [ ] Conflict on pull → clear message; no garbage UI state.

## Risks and spikes

- Git auth on Windows — verify HTTPS credentials via Credential Manager and SSH via `OpenSSH` work transparently when delegating to system git.
- Git repo at unusual locations (project not at repo root) — detect and gracefully degrade.

## Depends on

- Phase 6.
