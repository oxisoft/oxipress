# OxiPress — Requirements (v1 / MVP)

## 1. Project overview

**OxiPress** is a cross-platform desktop application for editing Hugo-based websites with an integrated live preview, themeable UI, basic Git workflow, and an embedded terminal for power users. It provides a three-panel authoring experience (file tree, content editor with raw markdown + WYSIWYG modes, live website preview) plus a tabbed bottom drawer (build logs, git output, terminal).

**Repository:** `github.com/oxisoft/oxipress`
**License:** MIT
**Primary domain:** `oxipress.org`

---

## 2. Tech stack

- **Framework:** Flutter, stable channel, latest minor version.
- **Language:** Dart 3.x.
- **Targets:** Linux (Ubuntu 22.04+ / Debian 12+), macOS (12+), Windows (10+).
- **State management:** Riverpod (`flutter_riverpod` + `riverpod_annotation`).
- **Architecture:** Feature-first folder structure (see §9), data / domain / ui layering per feature.
- **External runtime dependencies (must be on user's PATH):**
  - `hugo` (extended edition preferred — required for SCSS/SASS sites)
  - `git` (>= 2.30) — see §4.8 for libgit2 discussion
- **No backend service.** Fully local. No telemetry. No account system. No phone-home of any kind.

---

## 3. Non-goals (explicitly never)

- Telemetry / analytics / phone-home of any kind.
- Mandatory account system.
- Lock-in to any commercial backend service.
- Closed-source distribution of OxiPress core.
- Mobile or web builds of the app itself (companion mobile app may come later as a separate project — see future ideas).

For features deferred to v2+, see `oxipress-future-ideas.md`.

---

## 4. Core features

### 4.1 Project management

- "Open project" action: native folder picker. App validates the folder is a Hugo site (presence of `hugo.toml` / `hugo.yaml` / `hugo.json` or legacy `config.*` at root, and a `content/` directory).
- Recent projects list (last 10), persisted to user config dir (`~/.config/oxipress/recent.json` on Linux, equivalent on macOS/Windows via `path_provider`).
- Welcome screen when no project is open: recent projects, "Open Project" button, "Documentation" link.
- "Close project" cleanly stops Hugo serve, kills any open terminal sessions, resets UI state.

### 4.2 Application shell

- Single window. Window size and position persisted per OS.
- Top toolbar:
  - Project name and current branch
  - Hugo serve status indicator (stopped / starting / running / error) with start/stop control
  - Git status badge: branch, ahead/behind, dirty file count
  - Save button (Ctrl/Cmd+S also works)
  - Settings button
- Bottom status bar: cursor position in editor, current file path, last save time, theme indicator.

### 4.3 Three-panel layout (main area)

- Three panels separated by draggable splitters. Use `multi_split_view` or equivalent.
- Default split: 20% / 50% / 30% (tree / editor / preview).
- Each panel collapsible via header toggle. Sizes and collapsed state persisted per project.
- Each panel has a header with title, panel-specific actions, and collapse button.

### 4.4 Left panel — file tree

- Tree view rooted at `content/` by default. Toggle to switch to project root view (CRUD only allowed inside `content/`, `static/`, `assets/`, `data/`, `layouts/`).
- Folders collapsible/expandable, expanded state persisted per project.
- Click on markdown file → opens in editor.
- Click on non-markdown file (image, partial, etc.) → opens in OS default app via `Process.run`.
- Right-click context menu on folders: New File, New Folder, Rename, Delete, Reveal in OS file manager.
- Right-click context menu on files: Open, Rename, Delete, Duplicate, Reveal in OS file manager.
- "New File" dialog asks for filename, optionally pre-fills with template:
  ```yaml
  ---
  title: "{{ humanized filename }}"
  date: {{ ISO 8601 now }}
  draft: true
  ---
  ```
- Visual indicators per node:
  - Modified (unsaved in editor) → asterisk
  - Modified (uncommitted in git) → yellow indicator
  - Untracked in git → green indicator
  - Deleted (in git but missing on disk) → red strikethrough
- File system watcher: auto-refresh tree on external changes (use `watcher` package).

### 4.5 Middle panel — editor

The hardest part of the app. Get this right.

**Three logical sections per file:**

1. **Front matter form (top):** Parsed front matter (YAML/TOML) shown as editable form. Standard fields (title, date, draft, tags, categories, description, slug) get typed inputs (text, datetime picker, switch, chip-list). Unknown fields render as key/value rows. Format (YAML vs TOML) detected from source and preserved on save.
2. **Body editor (middle):** Markdown body with two switchable modes (toggle in panel header):
   - **Raw mode:** Plain-text markdown editor with syntax highlighting. Use `flutter_code_editor` or `code_text_field` with markdown grammar.
   - **Rich mode:** WYSIWYG view that renders markdown as styled rich text with editing affordances (bold/italic/links/headings/lists/blockquotes/code). Use `super_editor` (Superlist's pure-Flutter editor) which has first-class markdown serialization. Round-trip between modes must be lossless for standard CommonMark + Hugo's most common shortcodes.
3. **Shortcode handling:** Hugo shortcodes like `{{< youtube id >}}` render in rich mode as placeholder blocks (e.g. card showing "📹 YouTube: id"), draggable/deletable but not text-editable. In raw mode they appear as text.

**Editor behavior:**

- Auto-save on blur (configurable, default on).
- Manual save: Ctrl/Cmd+S.
- Save triggers nothing extra — Hugo serve detects file change and rebuilds. Preview reload via Hugo's LiveReload (see §4.6).
- Tab management: multiple open files as tabs above editor area. Reopen previously-open tabs on project load. Middle-click or Ctrl/Cmd+W to close a tab.
- Drag-and-drop image into editor: copies image into `static/images/` (configurable), inserts markdown reference at cursor.
- Find/Replace within current file (Ctrl/Cmd+F, Ctrl/Cmd+H).

### 4.6 Right panel — live preview

- Embedded webview pointing at `http://127.0.0.1:<hugo-port>`.
- Webview library: pick most reliable cross-platform option at implementation time. Candidates: `desktop_webview_window`, `flutter_inappwebview` (desktop builds), or per-platform combo with `webview_windows` (Windows) + `webview_flutter` (macOS via WKWebView) + `webview_cef` (Linux).
- When content file selected in tree, navigate webview to corresponding URL. URL computation:
  - Read Hugo's permalink configuration from site config.
  - Default: `content/posts/foo.md` → `/posts/foo/`.
  - Honor `slug` and `url` front matter overrides.
  - Honor section bundle structure (`content/posts/foo/index.md` → `/posts/foo/`).
  - For `_index.md`, navigate to section URL.
- Hugo's built-in LiveReload handles auto-refresh on save. No custom reload logic needed.
- Manual reload button in panel header as fallback.
- Address bar (read-only by default, editable on click) showing current URL, allowing manual navigation.
- Back/Forward buttons.
- "Open in browser" button: opens current preview URL in user's default browser.

### 4.7 Hugo process management

- On project open, spawn `hugo serve --bind 127.0.0.1 --port <ephemeral> --buildDrafts --buildFuture --noHTTPCache --disableFastRender` as child process.
- Allocate ephemeral port via OS (`ServerSocket.bind(0)` then close, or hardcode default and increment on conflict).
- Capture stdout/stderr separately, stream into the **Build** tab of the bottom drawer (§4.9).
- Parse Hugo build output for errors; show error count badge on toolbar Hugo indicator. Click → opens drawer scrolled to first error.
- Cleanly terminate on project close, app quit (SIGINT/SIGTERM on Unix, window close on all platforms), or user clicks stop.
- Auto-restart Hugo when `hugo.toml` / `hugo.yaml` / `hugo.json` config changes.
- "Restart Hugo" toolbar action.

### 4.8 Git integration

**Implementation decision (open — see §12):** v1 uses **system `git` via `Process.run`** for all operations. Rationale: auth (HTTPS credentials via OS keychain, SSH agent, GPG signing) is a solved problem when delegating to system git, and re-implementing it via libgit2 callbacks adds significant scope without product-visible benefit. Git is also already a likely-installed dependency for most Hugo users (themes/modules require it). Module is structured behind an abstract `GitRepository` interface so a libgit2 backend can be added in v2 without rewrites.

**Functional requirements:**

- Status badge in toolbar: branch name, ahead/behind counts, dirty file count. Refresh on file save and every 30s.
- Click status badge → opens git panel (modal or side drawer):
  - File list with checkboxes (staged / unstaged / untracked sections).
  - Click a file → diff view (unified diff, syntax-highlighted).
  - Commit message field + commit button (commits only checked files).
  - Push button (disabled if no upstream; show "Set upstream" prompt).
  - Pull button.
  - Fetch button.
- All git operations stream output to **Git** tab of bottom drawer.
- On error, show snackbar with summary; full output in drawer.
- Conflict detection: surface conflict state with clear message: "Merge conflict — resolve in your terminal or external tool." Conflict resolution UI is deferred (see future ideas).
- Power users can drop into the **Terminal** tab (§4.9) for any git operation not covered by the UI.

### 4.9 Bottom drawer (logs + terminal)

Tabbed panel that opens from below the main three-panel area. Toggle visibility via Ctrl/Cmd+J or status bar. Persisted height when open.

**Tabs:**

1. **Build** — Hugo serve stdout/stderr stream. Auto-scrolls. Filterable by level. "Clear" button.
2. **Git** — Output of git commands run via the in-app git panel. Last N commands' output retained.
3. **Terminal** — Embedded interactive shell.

**Terminal tab specifics:**

- Spawns user's default shell (`$SHELL` on Unix; PowerShell on Windows 10+, cmd as fallback) in the project root.
- Full PTY emulation. Recommended: `xterm.dart` (UI) + `flutter_pty` (PTY backend). Verify cross-platform support during spike (§12).
- Multiple terminal tabs (+ button to open new shell, x to close).
- Resize handling, ANSI color support, mouse support, copy/paste.
- New terminals start in project root by default.
- Sessions persist across drawer collapse/expand.
- Terminals killed on project close and app exit.
- Standard shortcuts: Ctrl+C interrupt, Ctrl+D close, Ctrl+Shift+C / Ctrl+Shift+V for clipboard (don't conflict with shell's Ctrl+C/V).
- Use case: power users who prefer git CLI over the in-app panel, or want any tooling alongside authoring (Hugo CLI, asset pipelines, deploy scripts, ssh, scp, etc.).

### 4.10 Theming

Themeable from day one. Built-in themes plus user-extensible via JSON.

**Built-in themes (shipped with app):**
- Dark
- Light

**User-extensible:** Drop JSON theme files into `~/.config/oxipress/themes/` (or OS equivalent). App scans built-in + user theme dirs at startup and on settings panel open. Live theme switching, no restart.

**File watcher** on user theme dir: edits apply immediately. Useful for theme authors iterating.

**Validation:** Themes validated against schema on load. Broken themes show error in settings panel and fall back to default.

**Theme picker** in settings: lists all available themes with preview swatches. "Open themes folder" button reveals user themes dir in OS file manager.

**Theme JSON schema:**

```json
{
  "name": "dark",
  "displayName": "Dark",
  "base": "dark",
  "fonts": {
    "ui":      { "family": "system-ui", "size": 13, "weight": "400" },
    "editor":  { "family": "JetBrains Mono, monospace", "size": 14, "weight": "400" },
    "heading": { "family": "system-ui", "size": 16, "weight": "600" }
  },
  "colors": {
    "window": { "background": "#1e1e1e" },
    "panel":  { "background": "#252526", "border": "#3e3e42", "headerBackground": "#2d2d30" },
    "text":   { "primary": "#d4d4d4", "secondary": "#a0a0a0", "disabled": "#6c6c6c", "inverse": "#1e1e1e" },
    "accent": { "primary": "#0e639c", "hover": "#1177bb" },
    "selection": { "background": "#264f78", "text": "#ffffff" },
    "status": { "success": "#4ec9b0", "warning": "#dcdcaa", "error": "#f48771", "info": "#9cdcfe" },
    "editor": {
      "background": "#1e1e1e",
      "lineNumber": "#858585",
      "currentLine": "#2a2a2a",
      "syntax": {
        "keyword":   "#569cd6",
        "string":    "#ce9178",
        "comment":   "#6a9955",
        "number":    "#b5cea8",
        "function":  "#dcdcaa",
        "type":      "#4ec9b0",
        "tag":       "#569cd6",
        "attribute": "#9cdcfe"
      }
    },
    "git": {
      "added":     "#4ec9b0",
      "modified":  "#dcdcaa",
      "deleted":   "#f48771",
      "untracked": "#a0a0a0"
    },
    "terminal": {
      "background": "#1e1e1e",
      "foreground": "#d4d4d4",
      "cursor":     "#d4d4d4",
      "ansi": {
        "black":   "#000000", "red":     "#cd3131", "green":  "#0dbc79", "yellow":  "#e5e510",
        "blue":    "#2472c8", "magenta": "#bc3fbc", "cyan":   "#11a8cd", "white":   "#e5e5e5",
        "brightBlack":   "#666666", "brightRed":     "#f14c4c", "brightGreen":  "#23d18b",
        "brightYellow":  "#f5f543", "brightBlue":    "#3b8eea", "brightMagenta": "#d670d6",
        "brightCyan":    "#29b8db", "brightWhite":   "#ffffff"
      }
    }
  }
}
```

**Notes:**
- Color values support hex, `rgb()`, `rgba()`.
- Font fallback chains via comma-separated lists.
- `base` field (`"dark"` or `"light"`) selects which Flutter `ThemeData` brightness to derive defaults from when fields are omitted (so partial themes work — user can override just colors and inherit fonts).
- Document the schema in `docs/theming.md` so users can author themes confidently.

### 4.11 Settings

Persisted to `~/.config/oxipress/settings.json` (or OS equivalent).

- Active theme (name reference).
- Editor font and size override (overrides theme value if set).
- Auto-save on blur: on/off.
- Default front matter format: YAML / TOML.
- Hugo binary path override (defaults to PATH lookup).
- Git binary path override (defaults to PATH lookup).
- Default image upload destination: `static/images/` / `assets/images/` / custom.
- Show drafts in preview: on/off (controls Hugo's `--buildDrafts` flag).
- Default shell (Terminal tab): auto-detect or user-specified.

---

## 5. UX details

- Native window chrome (don't build custom title bar in v1).
- Keyboard shortcuts (standard + app-specific):
  - Ctrl/Cmd+S — save
  - Ctrl/Cmd+F / +H — find / find-and-replace in current file
  - Ctrl/Cmd+P — quick file open (fuzzy filter over content files)
  - Ctrl/Cmd+Shift+P — command palette
  - Ctrl/Cmd+B — toggle file tree panel
  - Ctrl/Cmd+J — toggle bottom drawer
  - Ctrl/Cmd+/ — toggle preview panel
  - Ctrl/Cmd+\` — focus terminal tab in drawer (open drawer if closed)
- Destructive actions (delete, force-discard) require confirmation dialog.
- Long-running operations show progress, never block UI thread.
- Errors via snackbar + drawer entry. No silent failures.

---

## 6. First-run / setup experience

- Detect `hugo` and `git` on PATH.
- If either missing, show setup screen with: clear message, OS-specific install instructions (Homebrew on macOS, apt/winget on Linux/Windows, link to Hugo install docs), "Recheck" button.
- Don't proceed to main UI until both detected, or user clicks "I know what I'm doing" override (sets flag, shows ongoing warnings).

---

## 7. Non-functional requirements

- **Performance:** Cold start < 2s. 1000-file Hugo site renders tree in < 500ms. Editor file-switch < 100ms.
- **Memory:** Idle < 300MB (excluding webview process).
- **Privacy:** No network requests except (a) embedded webview loading from `127.0.0.1`, (b) user-initiated git push/pull/fetch, (c) user-initiated activity inside the terminal.
- **Accessibility:** Standard Flutter semantics. Keyboard nav for all interactive elements. Screen reader labels on icon-only buttons.
- **Internationalization:** `flutter_localizations` from day one. Ship English. Add Polish and Russian once English is stable. No hardcoded user-facing strings.

---

## 8. Suggested dependencies

Recommendations, not mandates. Substitute with reason if better options exist at implementation time.

- `flutter_riverpod` + `riverpod_annotation` — state management
- `freezed` + `freezed_annotation` + `json_serializable` — data classes
- `go_router` — navigation
- `multi_split_view` — resizable panels
- `super_editor` — rich-text markdown editor
- `flutter_code_editor` or `code_text_field` — raw markdown editor
- `markdown` — markdown parsing/serialization
- `yaml` + `toml` — front matter parsing
- `watcher` — file system watching (project files + theme files)
- `path_provider` — OS-appropriate config dirs
- `shared_preferences` — small persistent KV
- `path` — path manipulation
- `desktop_webview_window` (or per-platform combo) — preview pane
- `xterm.dart` + `flutter_pty` — embedded terminal
- `process_run` — `Process.run` ergonomics (optional)
- `logging` — structured app logging
- `flutter_localizations` + `intl` — i18n

---

## 9. Project layout

```
oxipress/
├── lib/
│   ├── main.dart
│   ├── app/                     # app shell, theme runtime, window mgmt
│   ├── core/
│   │   ├── process_runner.dart
│   │   ├── paths.dart           # path utils, URL computation
│   │   ├── storage.dart         # config + project state persistence
│   │   ├── logger.dart
│   │   └── result.dart          # Result<T, E> type
│   ├── features/
│   │   ├── project/
│   │   ├── file_tree/
│   │   ├── editor/
│   │   │   ├── raw_mode/
│   │   │   ├── rich_mode/
│   │   │   ├── frontmatter/
│   │   │   └── tabs/
│   │   ├── preview/
│   │   ├── hugo_process/
│   │   ├── git/                 # GitRepository interface + system-git impl
│   │   ├── drawer/              # tabbed bottom drawer
│   │   │   ├── build_log/
│   │   │   ├── git_log/
│   │   │   └── terminal/
│   │   ├── theming/             # theme loading, validation, runtime
│   │   ├── settings/
│   │   └── setup/
│   ├── shared/
│   │   ├── widgets/             # splitter, drawer, badges
│   │   ├── extensions/
│   │   └── l10n/
│   └── l10n/                    # arb files
├── assets/
│   └── themes/                  # bundled dark.json, light.json
├── test/
├── integration_test/
├── linux/  macos/  windows/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── LICENSE                      # MIT
├── CONTRIBUTING.md
├── docs/
│   └── theming.md               # theme schema reference for users
└── docker-compose.yml           # dev-only test Hugo site
```

---

## 10. Development setup

`docker-compose.yml` at repo root provides a known-good Hugo test site for developing OxiPress against. Not used by the app at runtime.

```yaml
services:
  test-site:
    image: klakegg/hugo:ext-alpine
    working_dir: /src
    volumes:
      - ./test-fixtures/sample-site:/src
    command: server --bind 0.0.0.0 --port 1313
    ports:
      - "1313:1313"
```

`test-fixtures/sample-site/` contains a small Hugo site (~10 pages, 2 sections, basic theme) committed to the repo for manual testing and integration tests.

---

## 11. Acceptance criteria — Definition of done for v1

A v1 release is shippable when ALL of these are true:

1. User opens a Hugo site folder via OS folder picker.
2. Three-panel layout renders with working draggable splitters.
3. File tree shows `content/` with collapsible folders.
4. User can create, rename, and delete files/folders from the tree, with confirmation on destructive actions.
5. Clicking a markdown file opens it in the editor.
6. Editor displays parsed front matter as form and body as editable markdown.
7. Toggle between raw and rich edit modes; round-trip lossless for CommonMark.
8. Saving persists to disk.
9. Hugo serve auto-starts on project open; preview panel shows the site.
10. Selecting a content file navigates preview to corresponding URL.
11. Saving triggers Hugo's LiveReload; preview updates.
12. Toolbar shows accurate Hugo serve status and git branch / ahead-behind / dirty count.
13. User can stage, commit, push, pull through git panel.
14. Bottom drawer provides Build / Git / Terminal tabs; terminal spawns working shell in project root.
15. Theme system loads built-in Dark and Light themes; user can switch live; user can drop custom JSON theme into themes folder and select it.
16. App quits cleanly: Hugo serve and terminal child processes killed, no orphans.
17. Settings persist across restarts.
18. Runs on Linux, macOS, Windows (latest two major versions of each).
19. No crashes on a 1000-file site over 30 minutes of normal use.
20. No outbound network traffic except documented allowed cases (§7).
21. README, LICENSE (MIT), CONTRIBUTING in place; `flutter analyze` zero warnings; tests pass.

---

## 12. Open design questions to resolve before implementation

These need spikes or decisions before locking in:

- **Webview library choice.** Test candidates on all three OSs early. Build a 1-day spike before committing.
- **Rich-text↔markdown round-trip fidelity.** `super_editor` is the best bet but CommonMark coverage isn't 100%. Build a test fixture of 30 markdown patterns (bold, italic, nested lists, code blocks, tables, footnotes, Hugo shortcodes, raw HTML) and verify round-trip.
- **Terminal cross-platform reliability.** Verify `xterm.dart` + `flutter_pty` (or alternatives) work on Linux/macOS/Windows with a simple PoC before depending on it.
- **File system watcher reliability on macOS.** macOS FS events have known quirks; verify `watcher` handles rapid changes from Hugo's writes.
- **Hugo binary version compatibility.** Decide minimum supported version. Recommendation: Hugo 0.115+ extended. Detect on startup, warn if older.
- **(Decision pending user input) Git backend:** system git via `Process.run` (current spec) vs. libgit2 via FFI bindings. See §4.8.
