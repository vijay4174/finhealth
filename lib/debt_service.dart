import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'subscription_service.dart';

class DebtService {
  static const String _debtKey = 'debts';

  static Future<List<Map<String, dynamic>>>
      getDebts() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedDebts =
        prefs.getStringList(_debtKey) ?? [];

    final List<Map<String, dynamic>> debts = [];

    for (final item in savedDebts) {
      try {
        debts.add(
          Map<String, dynamic>.from(
            jsonDecode(item),
          ),
        );
      } catch (error) {
        continue;
      }
    }

    return debts;
  }

  static Future<void> _saveAllDebts(
    List<Map<String, dynamic>> debts,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final encodedDebts = debts
        .map(
          (debt) => jsonEncode(debt),
        )
        .toList();

    await prefs.setStringList(
      _debtKey,
      encodedDebts,
    );
  }

  static int _notificationId(
    String debtId,
  ) {
    return debtId.hashCode.abs() %
        100000000;
  }

  static Future<void> _scheduleReminder(
    Map<String, dynamic> debt,
  ) async {
    final String id =
        debt['id']?.toString() ?? '';

    if (id.isEmpty) return;

    final int notificationId =
        _notificationId(id);

    final bool isPremium =
        await SubscriptionService.isPremium();

    if (!isPremium) {
      await NotificationService
          .cancelEmiReminders(
        notificationId,
      );

      return;
    }

    final bool isCompleted =
        debt['isCompleted'] == true;

    if (isCompleted) {
      await NotificationService
          .cancelEmiReminders(
        notificationId,
      );

      return;
    }

    final DateTime? nextDueDate =
        DateTime.tryParse(
      debt['nextDueDate']?.toString() ?? '',
    );

    if (nextDueDate == null) {
      await NotificationService
          .cancelEmiReminders(
        notificationId,
      );

      return;
    }

    await NotificationService
        .scheduleEmiReminder(
      notificationId: notificationId,
      loanName:
          debt['loanName']?.toString() ??
              'Loan',
      emiAmount:
          _getDouble(
        debt,
        'monthlyEmi',
      ),
      dueDate: nextDueDate,
    );
  }

  static Future<void>
      syncAllEmiReminders() async {
    final debts = await getDebts();

    final bool isPremium =
        await SubscriptionService.isPremium();

    for (final debt in debts) {
      final String id =
          debt['id']?.toString() ?? '';

      if (id.isEmpty) {
        continue;
      }

      final int notificationId =
          _notificationId(id);

      if (!isPremium) {
        await NotificationService
            .cancelEmiReminders(
          notificationId,
        );

        continue;
      }

      await _scheduleReminder(debt);
    }
  }

  static Future<void> saveDebt({
    required String loanName,
    required double totalAmount,
    required double remainingBalance,
    required double monthlyEmi,
    required double interestRate,
    required int totalEmis,
    required int paidEmis,
    required DateTime loanStartDate,
    required DateTime nextDueDate,
  }) async {
    final debts = await getDebts();

    final remainingEmis =
        (totalEmis - paidEmis).clamp(
      0,
      totalEmis,
    );

    final debt = <String, dynamic>{
      'id': DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      'loanName': loanName,
      'totalAmount': totalAmount,
      'remainingBalance':
          remainingBalance,
      'monthlyEmi': monthlyEmi,
      'interestRate': interestRate,
      'totalEmis': totalEmis,
      'paidEmis': paidEmis,
      'remainingEmis': remainingEmis,
      'loanStartDate':
          loanStartDate.toIso8601String(),
      'nextDueDate':
          nextDueDate.toIso8601String(),
      'paymentHistory':
          <Map<String, dynamic>>[],
      'isCompleted':
          remainingEmis == 0 ||
              remainingBalance <= 0,
      'createdAt':
          DateTime.now().toIso8601String(),
    };

    debts.insert(0, debt);

    await _saveAllDebts(debts);

    await _scheduleReminder(debt);
  }

  static Future<void> updateDebt({
    required String id,
    required String loanName,
    required double totalAmount,
    required double remainingBalance,
    required double monthlyEmi,
    required double interestRate,
    required int totalEmis,
    required int paidEmis,
    required DateTime loanStartDate,
    required DateTime nextDueDate,
  }) async {
    final debts = await getDebts();

    final index = debts.indexWhere(
      (debt) =>
          debt['id'].toString() == id,
    );

    if (index == -1) return;

    final oldDebt = debts[index];

    final remainingEmis =
        (totalEmis - paidEmis).clamp(
      0,
      totalEmis,
    );

    final updatedDebt =
        <String, dynamic>{
      ...oldDebt,
      'id': id,
      'loanName': loanName,
      'totalAmount': totalAmount,
      'remainingBalance':
          remainingBalance,
      'monthlyEmi': monthlyEmi,
      'interestRate': interestRate,
      'totalEmis': totalEmis,
      'paidEmis': paidEmis,
      'remainingEmis': remainingEmis,
      'loanStartDate':
          loanStartDate.toIso8601String(),
      'nextDueDate':
          nextDueDate.toIso8601String(),
      'paymentHistory':
          oldDebt['paymentHistory'] ?? [],
      'isCompleted':
          remainingEmis == 0 ||
              remainingBalance <= 0,
      'updatedAt':
          DateTime.now().toIso8601String(),
    };

    debts[index] = updatedDebt;

    await _saveAllDebts(debts);

    await NotificationService
        .cancelEmiReminders(
      _notificationId(id),
    );

    await _scheduleReminder(
      updatedDebt,
    );
  }

  static Future<void> markEmiAsPaid({
    required String id,
    DateTime? paidDate,
  }) async {
    final debts = await getDebts();

    final index = debts.indexWhere(
      (debt) =>
          debt['id'].toString() == id,
    );

    if (index == -1) return;

    final debt = debts[index];

    final totalEmis =
        _getInt(
      debt,
      'totalEmis',
    );

    final currentPaidEmis =
        _getInt(
      debt,
      'paidEmis',
    );

    final monthlyEmi =
        _getDouble(
      debt,
      'monthlyEmi',
    );

    final currentBalance =
        _getDouble(
      debt,
      'remainingBalance',
    );

    if (currentPaidEmis >= totalEmis ||
        currentBalance <= 0) {
      return;
    }

    final newPaidEmis =
        (currentPaidEmis + 1).clamp(
      0,
      totalEmis,
    );

    final remainingEmis =
        (totalEmis - newPaidEmis).clamp(
      0,
      totalEmis,
    );

    final newBalance =
        (currentBalance - monthlyEmi)
            .clamp(
      0.0,
      double.infinity,
    );

    final currentDueDate =
        _getDate(
      debt,
      'nextDueDate',
    );

    final nextDueDate =
        _addOneMonth(
      currentDueDate,
    );

    final paymentHistory =
        _getPaymentHistory(debt);

    paymentHistory.insert(
      0,
      <String, dynamic>{
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        'amount': monthlyEmi,
        'paidDate':
            (paidDate ?? DateTime.now())
                .toIso8601String(),
        'dueDate':
            currentDueDate
                .toIso8601String(),
        'emiNumber': newPaidEmis,
      },
    );

    final bool isCompleted =
        remainingEmis == 0 ||
            newBalance <= 0;

    final updatedDebt =
        <String, dynamic>{
      ...debt,
      'paidEmis': newPaidEmis,
      'remainingEmis':
          remainingEmis,
      'remainingBalance':
          newBalance,
      'nextDueDate':
          nextDueDate.toIso8601String(),
      'paymentHistory':
          paymentHistory,
      'isCompleted': isCompleted,
      'updatedAt':
          DateTime.now().toIso8601String(),
    };

    debts[index] = updatedDebt;

    await _saveAllDebts(debts);

    await NotificationService
        .cancelEmiReminders(
      _notificationId(id),
    );

    if (!isCompleted) {
      await _scheduleReminder(
        updatedDebt,
      );
    }
  }

  static Future<void>
      undoLastEmiPayment({
    required String id,
  }) async {
    final debts = await getDebts();

    final index = debts.indexWhere(
      (debt) =>
          debt['id'].toString() == id,
    );

    if (index == -1) return;

    final debt = debts[index];

    final paymentHistory =
        _getPaymentHistory(debt);

    if (paymentHistory.isEmpty) {
      return;
    }

    final lastPayment =
        paymentHistory.removeAt(0);

    final paidAmount =
        _getDouble(
      lastPayment,
      'amount',
    );

    final totalAmount =
        _getDouble(
      debt,
      'totalAmount',
    );

    final currentBalance =
        _getDouble(
      debt,
      'remainingBalance',
    );

    final currentPaidEmis =
        _getInt(
      debt,
      'paidEmis',
    );

    final totalEmis =
        _getInt(
      debt,
      'totalEmis',
    );

    final restoredBalance =
        (currentBalance + paidAmount)
            .clamp(
      0.0,
      totalAmount,
    );

    final newPaidEmis =
        (currentPaidEmis - 1).clamp(
      0,
      totalEmis,
    );

    final restoredDueDate =
        DateTime.tryParse(
      lastPayment['dueDate']
              ?.toString() ??
          '',
    );

    final updatedDebt =
        <String, dynamic>{
      ...debt,
      'paidEmis': newPaidEmis,
      'remainingEmis':
          totalEmis - newPaidEmis,
      'remainingBalance':
          restoredBalance,
      'nextDueDate': (
        restoredDueDate ??
            _subtractOneMonth(
              _getDate(
                debt,
                'nextDueDate',
              ),
            )
      ).toIso8601String(),
      'paymentHistory':
          paymentHistory,
      'isCompleted': false,
      'updatedAt':
          DateTime.now().toIso8601String(),
    };

    debts[index] = updatedDebt;

    await _saveAllDebts(debts);

    await NotificationService
        .cancelEmiReminders(
      _notificationId(id),
    );

    await _scheduleReminder(
      updatedDebt,
    );
  }

  static Future<void> deleteDebt(
    String id,
  ) async {
    final debts = await getDebts();

    await NotificationService
        .cancelEmiReminders(
      _notificationId(id),
    );

    debts.removeWhere(
      (debt) =>
          debt['id'].toString() == id,
    );

    await _saveAllDebts(debts);
  }

  static Future<void> clearDebts() async {
    final debts = await getDebts();

    for (final debt in debts) {
      final id =
          debt['id']?.toString() ?? '';

      if (id.isNotEmpty) {
        await NotificationService
            .cancelEmiReminders(
          _notificationId(id),
        );
      }
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_debtKey);
  }

  static double _getDouble(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static int _getInt(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime _getDate(
    Map<String, dynamic> data,
    String key,
  ) {
    return DateTime.tryParse(
          data[key]?.toString() ?? '',
        ) ??
        DateTime.now();
  }

  static List<Map<String, dynamic>>
      _getPaymentHistory(
    Map<String, dynamic> debt,
  ) {
    final rawHistory =
        debt['paymentHistory'];

    if (rawHistory is! List) {
      return [];
    }

    return rawHistory
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  static DateTime _addOneMonth(
    DateTime date,
  ) {
    final nextMonth =
        date.month == 12
            ? 1
            : date.month + 1;

    final nextYear =
        date.month == 12
            ? date.year + 1
            : date.year;

    final lastDayOfNextMonth =
        DateTime(
      nextYear,
      nextMonth + 1,
      0,
    ).day;

    final safeDay =
        date.day > lastDayOfNextMonth
            ? lastDayOfNextMonth
            : date.day;

    return DateTime(
      nextYear,
      nextMonth,
      safeDay,
      date.hour,
      date.minute,
    );
  }

  static DateTime _subtractOneMonth(
    DateTime date,
  ) {
    final previousMonth =
        date.month == 1
            ? 12
            : date.month - 1;

    final previousYear =
        date.month == 1
            ? date.year - 1
            : date.year;

    final lastDayOfPreviousMonth =
        DateTime(
      previousYear,
      previousMonth + 1,
      0,
    ).day;

    final safeDay =
        date.day >
                lastDayOfPreviousMonth
            ? lastDayOfPreviousMonth
            : date.day;

    return DateTime(
      previousYear,
      previousMonth,
      safeDay,
      date.hour,
      date.minute,
    );
  }
}