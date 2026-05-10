import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../core/logger.dart';
import '../core/storage.dart';

/// Persisted window geometry.
class WindowState {
  const WindowState({
    required this.width,
    required this.height,
    this.x,
    this.y,
  });

  final double width;
  final double height;
  final double? x;
  final double? y;

  static const WindowState defaults = WindowState(width: 1280, height: 800);

  Map<String, Object?> toJson() => {
        'width': width,
        'height': height,
        'x': x,
        'y': y,
      };

  static WindowState fromJson(Map<String, Object?> json) => WindowState(
        width: (json['width']! as num).toDouble(),
        height: (json['height']! as num).toDouble(),
        x: (json['x'] as num?)?.toDouble(),
        y: (json['y'] as num?)?.toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WindowState &&
          other.width == width &&
          other.height == height &&
          other.x == x &&
          other.y == y);

  @override
  int get hashCode => Object.hash(width, height, x, y);
}

/// Reads/writes [WindowState] through the [Storage] abstraction.
class WindowPersistence {
  WindowPersistence(this._storage);

  static const String _key = 'window.state.v1';

  final Storage _storage;

  Future<WindowState> load() async {
    final raw = await _storage.getString(_key);
    if (raw == null) return WindowState.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return WindowState.fromJson(decoded);
      }
    } on FormatException catch (_) {
      // Fall through to defaults.
    } on TypeError catch (_) {
      // Fall through to defaults.
    }
    return WindowState.defaults;
  }

  Future<void> save(WindowState state) async {
    await _storage.setString(_key, jsonEncode(state.toJson()));
  }
}

/// Wires `window_manager` events to [WindowPersistence]. Owns the lifecycle
/// of saving size/position changes.
class WindowLifecycle with WindowListener {
  WindowLifecycle(this._persistence) : _logger = AppLogger('window');

  final WindowPersistence _persistence;
  final AppLogger _logger;

  Timer? _saveDebounce;

  /// Initializes window_manager, restores geometry, and starts listening.
  /// Call after `WidgetsFlutterBinding.ensureInitialized()` and before
  /// `runApp`.
  Future<void> attach() async {
    await windowManager.ensureInitialized();

    final state = await _persistence.load();
    final options = WindowOptions(
      size: Size(state.width, state.height),
      minimumSize: const Size(800, 600),
      title: 'OxiPress',
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      if (state.x != null && state.y != null) {
        await windowManager.setPosition(Offset(state.x!, state.y!));
      } else {
        await windowManager.center();
      }
      await windowManager.show();
      await windowManager.focus();
    });

    windowManager.addListener(this);
    _logger.info('window attached', fields: {
      'width': state.width,
      'height': state.height,
      'x': state.x,
      'y': state.y,
    });
  }

  Future<void> detach() async {
    _saveDebounce?.cancel();
    windowManager.removeListener(this);
  }

  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowMove() => _scheduleSave();

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), _saveNow);
  }

  Future<void> _saveNow() async {
    try {
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();
      await _persistence.save(
        WindowState(
          width: size.width,
          height: size.height,
          x: position.dx,
          y: position.dy,
        ),
      );
    } on Exception catch (e, st) {
      _logger.error('failed to persist window state',
          error: e, stackTrace: st);
    }
  }
}
