# Phase 10 — Theming + Settings UI

## Goal

App ships built-in Dark and Light themes loaded from JSON assets. User can drop custom JSON themes into `~/.config/oxipress/themes/` and switch live without restart. Settings panel exposes every spec setting; settings persist to `~/.config/oxipress/settings.json`.

## Scope (in)

- **Theme JSON schema** per spec §4.10.
- **Built-in themes** as bundled assets (`assets/themes/dark.json`, `assets/themes/light.json`).
- **User themes**: scanned from `~/.config/oxipress/themes/` (OS-equivalent).
- **Live switching**: no app restart; rebuilds `ThemeData` from JSON.
- **Watcher** on user themes dir → live updates while authoring a theme.
- **Validation** against the schema; broken themes show an error in settings; fall back to default.
- **Theme application** to all surfaces:
  - Window / panel chrome.
  - Editor (background, line number, current line, syntax tokens).
  - Status bar.
  - Git status colors.
  - Terminal ANSI palette.
- **Settings panel** UI covering:
  - Active theme picker with preview swatches; "Open themes folder" reveals the dir.
  - Editor font and size override.
  - Auto-save on blur toggle.
  - Default front matter format (YAML / TOML).
  - Hugo binary path override.
  - Git binary path override.
  - Default image upload destination.
  - Show drafts in preview toggle (controls Hugo's `--buildDrafts` flag).
  - Default shell (auto-detect or user-specified).
- **Settings persistence**: `~/.config/oxipress/settings.json`.
- **`docs/theming.md`** — schema reference for theme authors.

## Out of scope

- Theme editor GUI (users author JSON directly).
- Per-project setting overrides (deferred).
- Themed splash / loading screens (use `base` brightness only).

## New components / interfaces

- `Theme` model (Freezed) with codec.
- `ThemeLoader` (assets + user dir).
- `ThemeValidator`.
- `ThemeRuntime` (replaces Phase 0 minimal version).
- `Settings` model + `SettingsRepository`.
- `SettingsView` widget.

## Tests

- **Unit**: schema validation (positive / negative); JSON → `ThemeData` mapping; partial themes inherit `base`; comma-list font fallback parsing; settings persistence round-trip.
- **Widget**: theme picker; live switching across all themed surfaces; broken theme error UI; settings form fields persist on change; "Open themes folder" calls `RevealInFileManager`.
- **Golden**: editor + tree + status bar in Dark and Light, plus one custom user theme.
- **Integration**: drop a custom theme JSON while app is running → appears in picker → select → applies live; corrupt the file → error appears, falls back to default.

## User acceptance checklist

- [ ] Built-in Dark and Light render correctly across all surfaces (incl. terminal palette).
- [ ] Drop a custom theme JSON → appears in picker.
- [ ] Edit a user theme JSON → app updates live.
- [ ] Broken theme shows an error and falls back.
- [ ] Each setting in the panel persists across restart.
- [ ] Settings affect the right behaviors (e.g. "Show drafts" toggles `--buildDrafts` on Hugo restart; auto-save toggle changes editor behavior; image destination affects Phase 9 drop).

## Risks and spikes

- Mapping arbitrary JSON colors → Flutter `ThemeData` requires care to keep consistency with widgets that use Material defaults. Decide on a single theming layer (a `ColorScheme` derived from JSON) and refactor early if Material widgets bypass it.

## Depends on

- Phases 5 (drafts toggle), 7 (git colors), 8 (terminal palette).
