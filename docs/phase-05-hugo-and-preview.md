# Phase 5 — Hugo serve + preview panel

## Goal

When the project opens, Hugo serve auto-starts on an ephemeral port. The right panel embeds a webview pointing at the live site. Clicking a content file in the tree navigates the preview to the corresponding URL. Saving a file triggers Hugo's LiveReload and the preview refreshes.

## Scope (in)

- **Webview spike (decision gate, must precede implementation)**: try `desktop_webview_window` first; fall back to a per-platform combo if it fails on any OS. Spike must produce a working PoC on Linux/macOS/Windows before Phase 5 begins.
- **HugoServer interface + system implementation**
  - Spawns `hugo serve --bind 127.0.0.1 --port <ephemeral> --buildDrafts --buildFuture --noHTTPCache --disableFastRender` (drafts toggle wired to settings in Phase 10; defaults to true here).
  - Ephemeral port via `ServerSocket.bind(0)` then close; pass to Hugo.
  - Streams stdout/stderr separately (consumers attached in Phase 6 for the build log).
  - State machine: stopped / starting / running / error.
  - Auto-restart on `hugo.toml | yaml | json` change.
  - Manual restart action.
  - Killed cleanly on project close, app quit (SIGINT/SIGTERM Unix; window close on all platforms). Validated by inspecting OS process tables on each platform.
- **Toolbar**
  - Hugo status indicator (stopped / starting / running / error) with start/stop control.
  - Error count badge when Hugo build errors are present; click → opens Build drawer (drawer chrome already exists; build log content lands in Phase 6).
- **Preview panel**
  - Embedded webview pointing at `127.0.0.1:<port>`.
  - Address bar: read-only by default; click → editable for manual nav.
  - Back / Forward / Reload / Open-in-browser controls in panel header.
  - Manual reload as fallback for LiveReload misses.
- **URL computation** (`PreviewUrlComputer`)
  - Reads Hugo permalinks config from site config.
  - Default mapping: `content/posts/foo.md` → `/posts/foo/`.
  - Honors `slug` and `url` front matter overrides.
  - Honors page bundles: `content/posts/foo/index.md` → `/posts/foo/`.
  - For `_index.md`, navigates to section URL.
  - Selecting a file in the tree → navigate webview to URL.

## Out of scope

- Build log UI in the drawer (Phase 6 — but the streaming infrastructure is built here).
- Site-config GUI editing (deferred).
- Multi-language permalinks (basic single-lang only this phase; revisit if fixture site needs it).

## New components / interfaces

- `HugoServer` interface + `SystemHugoServer` + `FakeHugoServer`.
- `EphemeralPort` helper.
- `PreviewUrlComputer` (pure domain).
- `WebviewController` interface + per-platform impls (decision from spike).
- `HugoConfigReader` (parses site config).
- `HugoErrorParser` — extracts error count + first-error location.

## Tests

- **Unit**: URL computation across all spec patterns (regular post, page bundle, `_index.md`, `slug` override, `url` override, custom permalinks); Hugo error parser against captured fixtures; ephemeral port allocation; auto-restart trigger on config change.
- **Widget**: status indicator transitions through state machine (with `FakeHugoServer`); preview panel header controls; URL navigation on tree selection.
- **Integration**: open fixture site → Hugo serve runs → preview shows site → click post → preview navigates → edit + save → preview reloads via LiveReload → quit app → no orphan Hugo processes (verified via OS process listing in test).

## User acceptance checklist

- [ ] Open fixture site → Hugo starts within a few seconds, status indicator shows running.
- [ ] Right panel shows the live site.
- [ ] Click a post in tree → preview navigates to the correct URL.
- [ ] Edit + save → preview reloads.
- [ ] Address bar is editable on click; manual nav works.
- [ ] Back / Forward / Reload / Open-in-browser work.
- [ ] Edit `hugo.toml` → Hugo auto-restarts.
- [ ] Manual Restart Hugo works.
- [ ] Quit app → no orphan Hugo on macOS / Linux / Windows.
- [ ] Hugo build errors set the toolbar badge.

## Risks and spikes

- **Webview cross-platform**: highest-risk dependency in the project. The spike must produce a working PoC on all three OSs before this phase starts.
- macOS sandboxing impact on webview if app is later notarized.
- Hugo error output format varies by version — pin minimum Hugo 0.115 extended.

## Depends on

- Phase 4.
