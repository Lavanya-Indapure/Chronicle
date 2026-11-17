import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:chronicle/core/services/logger_service.dart';

/// A notification channel (Android) / category of reminders.
class ReminderChannel {
  final String id;
  final String name;
  final String description;

  const ReminderChannel({required this.id, required this.name, required this.description});
}

/// Thin wrapper over `flutter_local_notifications` for scheduled local
/// reminders. Every method is a no-op on platforms without scheduling
/// support (web, desktop) or before [init] — so tests and unsupported
/// platforms never touch the plugin.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Route to open for the notification that launched the app, if any.
  String? launchRoute;

  /// Opens a route when a notification carrying one is tapped.
  void Function(String route)? onOpenRoute;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (_ready || !isSupported) return;
    try {
      await _initTimeZone();
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload;
          if (route != null && route.isNotEmpty) onOpenRoute?.call(route);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        launchRoute = launch!.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e, st) {
      LoggerService.error('Notification init failed', error: e, stackTrace: st, tag: 'Notify');
    }
  }

  Future<void> _initTimeZone() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Unknown identifier: fall back to any zone with the device's offset.
      final offset = DateTime.now().timeZoneOffset;
      final match = tz.timeZoneDatabase.locations.values
          .where((l) => l.currentTimeZone.offset == offset)
          .firstOrNull;
      if (match != null) tz.setLocalLocation(match);
    }
  }

  /// Asks for permission to post notifications (Android 13+, iOS/macOS).
  /// Returns false when denied or unsupported.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final granted = switch (defaultTargetPlatform) {
        TargetPlatform.android => await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission(),
        TargetPlatform.iOS => await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true),
        TargetPlatform.macOS => await _plugin
            .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true),
        _ => false,
      };
      return granted ?? false;
    } catch (e, st) {
      LoggerService.error('Notification permission request failed', error: e, stackTrace: st, tag: 'Notify');
      return false;
    }
  }

  /// Repeats every day at [time].
  Future<void> scheduleDaily({
    required int id,
    required ReminderChannel channel,
    required String title,
    required String body,
    required TimeOfDay time,
    String? route,
  }) =>
      _schedule(id, channel, title, body, _next(time), DateTimeComponents.time, route);

  /// Repeats every week on [weekday] (1 = Monday … 7 = Sunday) at [time].
  Future<void> scheduleWeekly({
    required int id,
    required ReminderChannel channel,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
    String? route,
  }) {
    var when = _next(time);
    while (when.weekday != weekday) {
      when = when.add(const Duration(days: 1));
    }
    return _schedule(id, channel, title, body, when, DateTimeComponents.dayOfWeekAndTime, route);
  }

  /// Next occurrence of [time] (today if still ahead, else tomorrow).
  tz.TZDateTime _next(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  Future<void> _schedule(
    int id,
    ReminderChannel channel,
    String title,
    String body,
    tz.TZDateTime when,
    DateTimeComponents repeat,
    String? route,
  ) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      payload: route,
      matchDateTimeComponents: repeat,
      // Inexact: no exact-alarm permission needed; a few minutes' drift is fine
      // for reminders.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name, channelDescription: channel.description),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Cancels every pending notification (e.g. on sign-out, so the previous
  /// user's reminders stop firing).
  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e, st) {
      LoggerService.error('Cancelling notifications failed', error: e, stackTrace: st, tag: 'Notify');
    }
  }

  /// Cancels every pending notification whose id is in [from, to).
  Future<void> cancelRange(int from, int to) async {
    if (!_ready) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= from && p.id < to) await _plugin.cancel(id: p.id);
    }
  }
}
