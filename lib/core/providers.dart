import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'process_runner.dart';
import 'storage.dart';

/// Overridden in `main()` after `SharedPreferences.getInstance()` resolves.
/// Tests override this with a `SharedPreferences` instance from `setMockInitialValues`,
/// or override [storageProvider] directly with [InMemoryStorage].
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  ),
);

final storageProvider = Provider<Storage>(
  (ref) => SharedPreferencesStorage(ref.watch(sharedPreferencesProvider)),
);

final processRunnerProvider = Provider<ProcessRunner>(
  (ref) => const SystemProcessRunner(),
);
