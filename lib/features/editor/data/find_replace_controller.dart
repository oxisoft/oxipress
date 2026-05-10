import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editor_buffers_controller.dart';

/// State of the find/replace bar overlaid above the editor.
class FindReplaceState {
  const FindReplaceState({
    required this.visible,
    required this.showReplace,
    required this.query,
    required this.replacement,
    required this.caseSensitive,
    required this.wholeWord,
    required this.regex,
    required this.currentMatch,
  });

  final bool visible;
  final bool showReplace;
  final String query;
  final String replacement;
  final bool caseSensitive;
  final bool wholeWord;
  final bool regex;

  /// Zero-based index of the currently-highlighted match within the list
  /// computed for the active buffer's body. `-1` when there's no current
  /// selection yet (e.g. the user just opened the bar).
  final int currentMatch;

  static const FindReplaceState initial = FindReplaceState(
    visible: false,
    showReplace: false,
    query: '',
    replacement: '',
    caseSensitive: false,
    wholeWord: false,
    regex: false,
    currentMatch: -1,
  );

  FindReplaceState copyWith({
    bool? visible,
    bool? showReplace,
    String? query,
    String? replacement,
    bool? caseSensitive,
    bool? wholeWord,
    bool? regex,
    int? currentMatch,
  }) =>
      FindReplaceState(
        visible: visible ?? this.visible,
        showReplace: showReplace ?? this.showReplace,
        query: query ?? this.query,
        replacement: replacement ?? this.replacement,
        caseSensitive: caseSensitive ?? this.caseSensitive,
        wholeWord: wholeWord ?? this.wholeWord,
        regex: regex ?? this.regex,
        currentMatch: currentMatch ?? this.currentMatch,
      );
}

class FindReplaceController extends Notifier<FindReplaceState> {
  @override
  FindReplaceState build() => FindReplaceState.initial;

  void open({bool replace = false}) {
    state = state.copyWith(visible: true, showReplace: replace);
  }

  void toggleReplace() {
    state = state.copyWith(showReplace: !state.showReplace);
  }

  void close() {
    state = FindReplaceState.initial;
  }

  void setQuery(String q) {
    state = state.copyWith(query: q, currentMatch: -1);
  }

  void setReplacement(String r) {
    state = state.copyWith(replacement: r);
  }

  void setCaseSensitive({required bool value}) {
    state = state.copyWith(caseSensitive: value, currentMatch: -1);
  }

  void setWholeWord({required bool value}) {
    state = state.copyWith(wholeWord: value, currentMatch: -1);
  }

  void setRegex({required bool value}) {
    state = state.copyWith(regex: value, currentMatch: -1);
  }

  void next(int totalMatches) {
    if (totalMatches == 0) return;
    final next = state.currentMatch + 1;
    state = state.copyWith(
      currentMatch: next >= totalMatches ? 0 : next,
    );
  }

  void prev(int totalMatches) {
    if (totalMatches == 0) return;
    final prev = state.currentMatch - 1;
    state = state.copyWith(
      currentMatch: prev < 0 ? totalMatches - 1 : prev,
    );
  }

  /// Replaces the currently-selected match (or the first match, if none is
  /// selected) and advances to the next match.
  void replaceOne(String absolutePath, List<RegExpMatch> matches) {
    if (matches.isEmpty) return;
    final target = state.currentMatch >= 0 &&
            state.currentMatch < matches.length
        ? matches[state.currentMatch]
        : matches.first;
    final buffers = ref.read(editorBuffersProvider);
    final buffer = buffers[absolutePath];
    if (buffer == null) return;
    final body = buffer.currentBody;
    final updated = body.replaceRange(target.start, target.end, state.replacement);
    ref
        .read(editorBuffersProvider.notifier)
        .updateBody(absolutePath, updated);
    // Recompute by clearing currentMatch; widget recomputes matches.
    state = state.copyWith(currentMatch: -1);
  }

  void replaceAll(String absolutePath, List<RegExpMatch> matches) {
    if (matches.isEmpty) return;
    final buffers = ref.read(editorBuffersProvider);
    final buffer = buffers[absolutePath];
    if (buffer == null) return;
    final body = buffer.currentBody;
    final buffer2 = StringBuffer();
    var cursor = 0;
    for (final match in matches) {
      buffer2.write(body.substring(cursor, match.start));
      buffer2.write(state.replacement);
      cursor = match.end;
    }
    buffer2.write(body.substring(cursor));
    ref
        .read(editorBuffersProvider.notifier)
        .updateBody(absolutePath, buffer2.toString());
    state = state.copyWith(currentMatch: -1);
  }
}

final findReplaceProvider =
    NotifierProvider<FindReplaceController, FindReplaceState>(
  FindReplaceController.new,
);

/// Pure: compute the match list for a body + state combination.
List<RegExpMatch> computeFindMatches(String body, FindReplaceState s) {
  if (s.query.isEmpty) return const [];
  try {
    final pattern = s.regex
        ? s.query
        : s.wholeWord
            ? r'\b' + RegExp.escape(s.query) + r'\b'
            : RegExp.escape(s.query);
    final re = RegExp(pattern, caseSensitive: s.caseSensitive);
    return re.allMatches(body).toList(growable: false);
  } on FormatException catch (_) {
    return const [];
  }
}
