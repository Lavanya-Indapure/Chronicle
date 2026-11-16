import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/services/logger_service.dart';
import 'package:chronicle/core/services/notification_service.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';

/// Notification id ranges, one block per reminder kind.
abstract final class ReminderIds {
  static const hydrationStart = 1000;
  static const hydrationEnd = 2000;
  static const dues = 2000;
}

abstract final class ReminderChannels {
  static const hydration = ReminderChannel(
    id: 'hydration',
    name: AppStrings.reminderHydrationChannel,
    description: AppStrings.reminderHydrationChannelDescription,
  );
  static const dues = ReminderChannel(
    id: 'dues',
    name: AppStrings.reminderDuesChannel,
    description: AppStrings.reminderDuesChannelDescription,
  );
}

/// Keeps scheduled local reminders in line with the user's data:
/// water reminders follow the health settings, and a weekly nudge lists
/// pending lend/borrow dues.
class ReminderSync {
  /// Weekly dues nudge: Sunday morning.
  static const duesWeekday = DateTime.sunday;
  static const duesTime = TimeOfDay(hour: 10, minute: 0);

  final Ref _ref;
  final NotificationService _service;
  HealthSettings? _syncedHydration;

  ReminderSync(this._ref, this._service);

  /// Reschedules water reminders for [settings]; skips when nothing changed.
  Future<void> syncHydration(HealthSettings settings) async {
    if (settings == _syncedHydration) return;
    _syncedHydration = settings;
    try {
      await _service.cancelRange(ReminderIds.hydrationStart, ReminderIds.hydrationEnd);
      if (!settings.notificationsEnabled) return;
      if (!await _service.requestPermission()) return;
      final times = settings.hydrationSlotTimes;
      for (var i = 0; i < times.length && i < ReminderIds.hydrationEnd - ReminderIds.hydrationStart; i++) {
        await _service.scheduleDaily(
          id: ReminderIds.hydrationStart + i,
          channel: ReminderChannels.hydration,
          title: AppStrings.reminderHydrationTitle,
          body: AppStrings.reminderHydrationBody,
          time: times[i],
          route: '/health/hydration',
        );
      }
    } catch (e, st) {
      _syncedHydration = null; // retry next time
      LoggerService.error('Hydration reminder sync failed', error: e, stackTrace: st, tag: 'Reminders');
    }
  }

  /// Schedules (or clears) the weekly reminder about pending dues.
  Future<void> syncDues() async {
    try {
      final transactions = await _ref.read(expenseRepositoryProvider).getTransactions();
      await _service.cancelRange(ReminderIds.dues, ReminderIds.dues + 1);
      final body = duesMessage(transactions);
      if (body == null) return;
      if (!await _service.requestPermission()) return;
      await _service.scheduleWeekly(
        id: ReminderIds.dues,
        channel: ReminderChannels.dues,
        title: AppStrings.reminderDuesTitle,
        body: body,
        weekday: duesWeekday,
        time: duesTime,
        route: '/expenses',
      );
    } catch (e, st) {
      LoggerService.error('Dues reminder sync failed', error: e, stackTrace: st, tag: 'Reminders');
    }
  }

  /// "3 pending · ₹4,500 to collect · ₹1,200 to pay", or null when nothing
  /// is pending.
  static String? duesMessage(List<Transaction> transactions) {
    final pending = transactions.where((t) => t.status == TransactionStatus.pending).toList();
    if (pending.isEmpty) return null;
    double sum(TransactionType type) =>
        pending.where((t) => t.type == type).fold(0.0, (total, t) => total + t.amount);
    final collect = sum(TransactionType.LEND);
    final pay = sum(TransactionType.BORROW);
    return [
      '${pending.length} ${pending.length == 1 ? AppStrings.reminderDuePending : AppStrings.reminderDuesPending}',
      if (collect > 0) '${AppFormatters.currency(collect)} ${AppStrings.reminderDuesToCollect}',
      if (pay > 0) '${AppFormatters.currency(pay)} ${AppStrings.reminderDuesToPay}',
    ].join(' · ');
  }
}

final reminderSyncProvider = Provider<ReminderSync>((ref) => ReminderSync(ref, NotificationService.instance));
