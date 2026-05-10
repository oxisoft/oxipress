import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/oxipress_app.dart';
import 'app/window_management.dart';
import 'core/logger.dart';
import 'core/providers.dart';
import 'core/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeLogging(level: kDebugMode ? Level.FINE : Level.INFO);

  final prefs = await SharedPreferences.getInstance();
  final storage = SharedPreferencesStorage(prefs);

  final lifecycle = WindowLifecycle(WindowPersistence(storage));
  await lifecycle.attach();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const OxiPressApp(),
    ),
  );
}
