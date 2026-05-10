# Phase 6 — Drawer + build log

## Goal

A toggleable drawer at the bottom of the window with three tabs: Build, Git (placeholder), Terminal (placeholder). The Build tab streams Hugo's stdout/stderr live, with auto-scroll, level filter, clear button, and clickable errors that scroll to the first error.

## Scope (in)

- **Drawer chrome**
  - Bottom-anchored, height-resizable, persisted height.
  - Toggle via Ctrl/Cmd+J.
  - Status-bar control mirrors toggle.
  - Tabs: Build, Git, Terminal (latter two render placeholder copy this phase).
- **Build tab**
  - Subscribes to `HugoServer` stdout/stderr streams (introduced in Phase 5).
  - Auto-scroll while at the bottom; pauses if user scrolls up; "Jump to bottom" affordance.
  - Level filter (info / warn / error).
  - Clear button.
  - Errors highlighted; click → scroll to first error; toolbar Hugo error badge link opens drawer scrolled to first error.

## Out of scope

- Git tab content (Phase 7).
- Terminal tab content (Phase 8).

## New components / interfaces

- `Drawer` widget + `DrawerController`.
- `BuildLogController` (Riverpod Notifier) — buffers up to N lines, prunes oldest.
- `LogLine` model (level, timestamp, text, source).
- `BuildLogView` widget.

## Tests

- **Unit**: log line classification (info/warn/error); buffer pruning at N lines; first-error index tracking.
- **Widget**: drawer toggle; height persistence; build log auto-scroll behavior; level filter; clear; click-to-scroll-to-error.
- **Integration**: open fixture site → drawer toggles → build log shows Hugo output → introduce a syntax error in a fixture page → error appears with badge → click badge → drawer opens scrolled to error.

## User acceptance checklist

- [ ] Ctrl/Cmd+J toggles drawer.
- [ ] Drawer height persists across restart.
- [ ] Build log streams Hugo output live.
- [ ] Auto-scroll pauses when scrolled up; resumes on jump-to-bottom.
- [ ] Level filter works.
- [ ] Clear button empties the log.
- [ ] Toolbar error badge → opens drawer scrolled to first error.

## Risks and spikes

- Performance under high log volume (Hugo `--debug` output can be large). Cap buffer to N lines (default 10k) and verify rendering with `ListView.builder`.

## Depends on

- Phase 5.
