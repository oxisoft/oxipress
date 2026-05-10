# Phase 9 — Rich-text editor + image drop

## Goal

User can toggle the editor body between Raw and Rich modes. Round-trip is lossless for CommonMark and the Hugo shortcodes used in the fixture set. Hugo shortcodes appear as placeholder cards in Rich mode. Drag-and-drop of images into the editor copies the image into the configured destination and inserts a markdown reference.

## Scope (in)

- **Round-trip fidelity spike (decision gate, must precede implementation)**: 30-pattern fixture (bold, italic, nested lists, code blocks, tables, footnotes, blockquotes, links, images, autolinks, raw HTML, common Hugo shortcodes — `youtube`, `figure`, `gist`, etc.). Acceptance: 100% round-trip lossless for CommonMark; documented limitations for HTML / shortcodes.
- **`super_editor` integration** for Rich mode.
- **Toggle** in panel header (already shown disabled in Phase 2).
- **Shortcode handling**
  - In Rich mode: shortcodes render as placeholder cards (e.g. "📹 YouTube: id"), draggable / deletable, not text-editable.
  - In Raw mode: shown as text.
- **Drag-and-drop image**
  - Destination configurable (default `static/images/`); wired to settings in Phase 10.
  - Inserts markdown reference at cursor.
  - Avoids name collisions (auto-suffix).

## Out of scope

- Image cropping / resizing UI.
- Asset library panel (deferred).
- Custom shortcode template definitions in Rich mode (deferred).

## New components / interfaces

- `RichEditorAdapter` (wraps super_editor; handles serialization to markdown and back).
- `ShortcodeBlock` (custom super_editor block).
- `ImageDropHandler`.
- `MarkdownRoundTripFixtures` (test asset).

## Tests

- **Unit**: 30-fixture round-trip lossless verification; shortcode parser + reverse renderer; image filename collision suffixer.
- **Widget**: toggle raw↔rich preserves dirty state; shortcode placeholder rendering; image drop inserts markdown.
- **Integration**: open fixture post → toggle to rich → make a styled change → toggle back → raw markdown reflects change correctly.

## User acceptance checklist

- [ ] Toggle Raw↔Rich is enabled.
- [ ] Round-trip on the fixture set is lossless.
- [ ] Shortcodes appear as cards in Rich; as text in Raw.
- [ ] Drag-drop image into editor → copied to configured destination → markdown reference inserted at cursor.
- [ ] Editing in Rich preserves dirty state and saves correctly via the same Save flow.

## Risks and spikes

- super_editor markdown coverage gaps (highest-risk feature in the project per spec §12). Spike must conclude with a documented coverage report before implementation locks.
- Mixed CRLF/LF line endings during round-trip.

## Depends on

- Phase 4.
