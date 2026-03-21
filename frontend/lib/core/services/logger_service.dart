import 'package:flutter/foundation.dart';

/// Structured logger — replaces all `print` statements.
/// No-ops in release builds.
abstract final class LoggerService {
  static void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }

  static void warning(String message, {String? tag}) {
    _log('WARN', message, tag: tag);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    _log('ERROR', message, tag: tag);
    if (error != null) debugPrint('  → $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
  }

  static void _log(String level, String message, {String? tag}) {
    assert(() {
      final prefix = tag != null ? '[$level][$tag]' : '[$level]';
      debugPrint('$prefix $message');
      return true;
    }());
  }
}
