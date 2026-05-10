import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/app/welcome_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders app name, tagline, and disabled Open Project button',
        (tester) async {
      await pumpAppWith(tester, const WelcomeScreen());

      expect(find.text('OxiPress'), findsOneWidget);
      expect(find.text('Edit Hugo sites with live preview.'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('Open Project'), findsOneWidget);
    });

    testWidgets('shows the app version', (tester) async {
      await pumpAppWith(tester, const WelcomeScreen());
      expect(find.textContaining('v0.0.1'), findsOneWidget);
    });
  });
}
