import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/result.dart';

void main() {
  group('Result', () {
    test('Success carries value and reports success', () {
      const r = Result<int, String>.success(42);
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.errorOrNull, isNull);
    });

    test('Failure carries error and reports failure', () {
      const r = Result<int, String>.failure('boom');
      expect(r.isSuccess, isFalse);
      expect(r.isFailure, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.errorOrNull, 'boom');
    });

    test('fold dispatches to the correct branch', () {
      const ok = Result<int, String>.success(1);
      const err = Result<int, String>.failure('x');
      expect(ok.fold((v) => 'ok:$v', (e) => 'err:$e'), 'ok:1');
      expect(err.fold((v) => 'ok:$v', (e) => 'err:$e'), 'err:x');
    });

    test('map transforms only success', () {
      const ok = Result<int, String>.success(2);
      const err = Result<int, String>.failure('x');
      expect(ok.map((v) => v * 10).valueOrNull, 20);
      expect(err.map((v) => v * 10).errorOrNull, 'x');
    });

    test('mapError transforms only failure', () {
      const ok = Result<int, String>.success(2);
      const err = Result<int, String>.failure('x');
      expect(ok.mapError((e) => e.length).valueOrNull, 2);
      expect(err.mapError((e) => e.length).errorOrNull, 1);
    });

    test('flatMap chains success and short-circuits on failure', () {
      const ok = Result<int, String>.success(2);
      const err = Result<int, String>.failure('x');
      expect(
        ok.flatMap((v) => Result<int, String>.success(v + 1)).valueOrNull,
        3,
      );
      expect(
        ok.flatMap((v) => const Result<int, String>.failure('inner')).errorOrNull,
        'inner',
      );
      expect(
        err.flatMap((v) => Result<int, String>.success(v + 1)).errorOrNull,
        'x',
      );
    });

    test('equality is structural', () {
      expect(
        const Result<int, String>.success(1),
        equals(const Result<int, String>.success(1)),
      );
      expect(
        const Result<int, String>.failure('e'),
        equals(const Result<int, String>.failure('e')),
      );
      expect(
        const Result<int, String>.success(1),
        isNot(equals(const Result<int, String>.failure('e'))),
      );
    });
  });
}
