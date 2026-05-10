import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// Thin wrapper over `package:logging` that supports structured fields.
///
/// Used everywhere we want a named logger; instantiate one per feature/module.
class AppLogger {
  AppLogger(String name) : _logger = Logger(name);

  final Logger _logger;

  void debug(String message, {Map<String, Object?>? fields}) =>
      _logger.fine(_format(message, fields));

  void info(String message, {Map<String, Object?>? fields}) =>
      _logger.info(_format(message, fields));

  void warn(String message, {Map<String, Object?>? fields}) =>
      _logger.warning(_format(message, fields));

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) =>
      _logger.severe(_format(message, fields), error, stackTrace);

  String _format(String message, Map<String, Object?>? fields) {
    if (fields == null || fields.isEmpty) return message;
    final buffer = StringBuffer(message);
    for (final entry in fields.entries) {
      buffer.write(' ${entry.key}=${entry.value}');
    }
    return buffer.toString();
  }
}

/// Initialize the root logger to forward records to `dart:developer`.
///
/// Call once during app bootstrap.
void initializeLogging({Level level = Level.INFO}) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      time: record.time,
      sequenceNumber: record.sequenceNumber,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}
