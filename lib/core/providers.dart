import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_system.dart';
import 'file_watcher.dart';
import 'os_opener.dart';
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

final fileSystemProvider = Provider<FileSystem>(
  (ref) => const RealFileSystem(),
);

final fileWatcherProvider = Provider<FileWatcher>(
  (ref) => const WatcherFileWatcher(),
);

final osOpenerProvider = Provider<OsOpener>(
  (ref) => RealOsOpener(processRunner: ref.watch(processRunnerProvider)),
);
