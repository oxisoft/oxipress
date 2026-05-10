# Phase 8 — Embedded terminal

## Goal

Terminal tab in the drawer spawns the user's default shell in the project root. Multiple terminal tabs supported. Full PTY emulation, ANSI colors, mouse, copy/paste. Killed cleanly on project close and app quit.

## Scope (in)

- **PTY spike (decision gate, must precede implementation)**: validate `xterm.dart` + `flutter_pty` (or alternative) on Linux/macOS/Windows.
- **Terminal tab**
  - Spawns `$SHELL` on Unix, PowerShell on Windows 10+ (cmd fallback).
  - Working directory: project root.
  - Multiple terminals via + button; close via x.
  - ANSI 256-color, true-color, mouse support, resize handling.
  - Sessions persist across drawer collapse / expand.
  - Killed on project close + app exit (verified — no orphans).
  - Standard shortcuts: terminal-native Ctrl+C interrupt, Ctrl+D close. Clipboard via Ctrl+Shift+C / Ctrl+Shift+V to avoid Ctrl+C/V collision with shell signals.
  - Ctrl/Cmd+\` shortcut focuses terminal tab (opens drawer if closed).

## Out of scope

- Saved terminal layouts / sessions across app restarts.
- ssh integration helpers.
- Terminal theming via app theme JSON (terminal section already exists in theme schema; wire-up is in Phase 10).

## New components / interfaces

- `PtyBackend` interface + `RealPtyBackend` (xterm.dart + flutter_pty) + fake.
- `TerminalSession` model.
- `TerminalController` (Riverpod Notifier).
- `TerminalView` widget.

## Tests

- **Unit**: shell resolution per OS; cwd resolution; session lifecycle.
- **Widget**: open/close terminal tabs; tab persistence within a session; copy/paste shortcut routing.
- **Integration** (best-effort, may be platform-gated): spawn terminal in fixture project → run `pwd` / `cd` → kill on app exit → no orphan PTYs.

## User acceptance checklist

- [ ] Terminal tab opens with shell in project root on macOS / Linux / Windows.
- [ ] Multiple terminals via + button.
- [ ] ANSI colors render correctly.
- [ ] Mouse selection + scrollback work.
- [ ] Ctrl+C interrupts a running command without closing the terminal.
- [ ] Ctrl+Shift+C / Ctrl+Shift+V copy / paste.
- [ ] Quit app → no orphan terminal processes.

## Risks and spikes

- Windows PTY support (ConPTY) reliability — major risk.
- xterm.dart line-buffer performance under heavy output (e.g. `cat` on a large file).

## Depends on

- Phase 6.
