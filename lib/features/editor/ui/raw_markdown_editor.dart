import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/editor_buffers_controller.dart';
import '../data/find_replace_controller.dart';
import '../domain/editor_buffer.dart';

/// Editable markdown body. Routes every change through [editorBuffersProvider]
/// so the buffer's `currentBody` is always in sync. External edits (revert,
/// reload from disk) push back into the underlying [TextEditingController]
/// through a `ref.listen` bridge.
///
/// When Find/Replace navigates between matches, this widget moves the
/// caret, selects the matched range, and asks the text field to scroll the
/// selection into view so the user can see what was found.
class RawMarkdownEditor extends ConsumerStatefulWidget {
  const RawMarkdownEditor({
    super.key,
    required this.absolutePath,
  });

  final String absolutePath;

  @override
  ConsumerState<RawMarkdownEditor> createState() =>
      _RawMarkdownEditorState();
}

class _RawMarkdownEditorState extends ConsumerState<RawMarkdownEditor> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  int _lastAppliedMatchIndex = -1;
  String _lastAppliedQuery = '';

  @override
  void initState() {
    super.initState();
    final initial = ref
            .read(editorBuffersProvider)[widget.absolutePath]
            ?.currentBody ??
        '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sync the TextEditingController back to the buffer when an external
    // change updates the buffer (revert, reload from disk).
    ref.listen<EditorBuffer?>(
      editorBuffersProvider
          .select((m) => m[widget.absolutePath]),
      (previous, next) {
        if (next == null) return;
        if (next.currentBody != _controller.text) {
          _controller.value = TextEditingValue(
            text: next.currentBody,
            selection: TextSelection.collapsed(
              offset: next.currentBody.length,
            ),
          );
        }
      },
    );

    // React to Find/Replace navigation: select the match and focus the
    // editor so the user actually sees what was found.
    ref.listen<FindReplaceState>(findReplaceProvider, (previous, next) {
      _maybeApplyFindSelection(next);
    });

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        minLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.all(16),
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
          fontSize: 13.5,
          height: 1.45,
        ),
        onChanged: (value) {
          ref
              .read(editorBuffersProvider.notifier)
              .updateBody(widget.absolutePath, value);
        },
      ),
    );
  }

  void _maybeApplyFindSelection(FindReplaceState state) {
    if (!state.visible) {
      _lastAppliedMatchIndex = -1;
      return;
    }
    if (state.currentMatch < 0) return;
    if (state.currentMatch == _lastAppliedMatchIndex &&
        state.query == _lastAppliedQuery) {
      return;
    }
    final body = _controller.text;
    final matches = computeFindMatches(body, state);
    if (matches.isEmpty || state.currentMatch >= matches.length) return;
    final match = matches[state.currentMatch];

    _lastAppliedMatchIndex = state.currentMatch;
    _lastAppliedQuery = state.query;

    _focusNode.requestFocus();
    _controller.selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
  }
}
