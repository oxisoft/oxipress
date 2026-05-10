# Phase 11 — First-run setup, shortcuts, i18n, release

## Goal

App detects Hugo and git on PATH at first run with clear install instructions if missing. All keyboard shortcuts from spec §5 work, including Quick Open and Command Palette. UI is internationalized (English ships; Polish and Russian land in this phase). Acceptance criteria from spec §11 are signed off; v1 is shippable.

## Scope (in)

- **First-run / setup screen**
  - Detects Hugo and git on PATH (or configured override paths from settings).
  - If missing: clear screen with OS-specific install instructions (Homebrew on macOS, apt on Debian/Ubuntu, winget on Windows), link to Hugo install docs, "Recheck" button.
  - "I know what I'm doing" override flag → main UI with persistent warning.
- **Keyboard shortcuts** (full set per spec §5):
  - Ctrl/Cmd+S, F, H, P, Shift+P, B, J, /, \`.
- **Quick Open (Ctrl/Cmd+P)**: fuzzy filter over content files, recent files first.
- **Command Palette (Ctrl/Cmd+Shift+P)**: catalog of every action (open project, save, toggle drawer, switch theme, restart Hugo, etc.).
- **i18n**
  - English baseline (already wired in Phase 0).
  - Polish + Russian translations.
  - Lint or convention preventing hardcoded user-facing strings.
- **Accessibility pass**: screen reader labels on icon-only buttons, full keyboard nav, semantics on tree / tabs / panels.
- **Performance verification** against spec §7 targets (cold start, tree render, file switch, idle memory).
- **Stability test**: 30-min run on a 1000-file Hugo site with no crashes.
- **Release readiness**:
  - README, CONTRIBUTING populated.
  - LICENSE in place (already from Phase 0).
  - `flutter analyze` zero warnings.
  - Acceptance criteria sign-off (spec §11).

## Out of scope

- Auto-update mechanism (deferred).
- Code signing / notarization automation (manual for v1; document the steps).
- Crash reporting (no telemetry per non-goals).

## New components / interfaces

- `EnvironmentDetector` (Hugo + git presence + version).
- `SetupScreen`.
- `ShortcutRegistry` (single source of truth for keybindings).
- `QuickOpenController`.
- `CommandPaletteController` + command registry.
- `Localizations` (additional ARBs).

## Tests

- **Unit**: PATH detection per OS; version parsing; fuzzy ranking; command registry lookup.
- **Widget**: setup screen states (Hugo missing / git missing / both / both present); quick-open keyboard nav; command palette dispatch.
- **Integration**: full happy path on fixture site — install (mocked) → open → edit → save → preview → commit → quit.
- **Performance**: scripted measurement on a generated 1000-file site.

## User acceptance checklist

- [ ] On a fresh machine without Hugo: setup screen appears with correct OS instructions.
- [ ] After installing Hugo: "Recheck" advances to main UI.
- [ ] Override flag bypasses with persistent warning.
- [ ] Every shortcut in spec §5 works.
- [ ] Quick Open finds files by fuzzy match.
- [ ] Command Palette covers all advertised actions.
- [ ] App available in English, Polish, Russian.
- [ ] All §11 acceptance criteria pass.

## Risks and spikes

- Hugo and git version compatibility: pin minimums (Hugo 0.115 extended, git 2.30) and document.
- Translation completeness: ship Polish / Russian as best-effort with English fallback for missing keys.

## Depends on

- All previous phases.
