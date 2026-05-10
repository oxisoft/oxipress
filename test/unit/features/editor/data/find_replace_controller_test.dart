import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/editor/data/find_replace_controller.dart';

FindReplaceState _state({
  String query = '',
  bool caseSensitive = false,
  bool wholeWord = false,
  bool regex = false,
}) =>
    FindReplaceState.initial.copyWith(
      query: query,
      caseSensitive: caseSensitive,
      wholeWord: wholeWord,
      regex: regex,
    );

void main() {
  group('computeFindMatches', () {
    test('returns empty list for empty query', () {
      expect(computeFindMatches('any body', _state()), isEmpty);
    });

    test('plain match is case-insensitive by default', () {
      final matches =
          computeFindMatches('Hello hello HELLO', _state(query: 'hello'));
      expect(matches, hasLength(3));
    });

    test('case sensitive only matches exact case', () {
      final matches = computeFindMatches(
        'Hello hello HELLO',
        _state(query: 'hello', caseSensitive: true),
      );
      expect(matches, hasLength(1));
    });

    test('whole word excludes substring matches', () {
      final matches = computeFindMatches(
        'cat catfish category',
        _state(query: 'cat', wholeWord: true),
      );
      expect(matches, hasLength(1));
    });

    test('regex enables pattern matching', () {
      final matches = computeFindMatches(
        'foo123 bar456',
        _state(query: r'\d+', regex: true),
      );
      expect(matches, hasLength(2));
      expect(matches[0].group(0), '123');
      expect(matches[1].group(0), '456');
    });

    test('invalid regex returns empty list', () {
      final matches = computeFindMatches(
        'abc',
        _state(query: '(', regex: true),
      );
      expect(matches, isEmpty);
    });

    test('escapes special characters in plain mode', () {
      final matches = computeFindMatches(
        r'price $5 and $10',
        _state(query: r'$5'),
      );
      expect(matches, hasLength(1));
    });
  });
}
