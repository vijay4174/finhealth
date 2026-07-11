import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'emergency_fund_service.dart';
import 'goal_service.dart';

class WalletService {
  static const String _transactionsKey =
      'wallet_transactions';

  static Future<List<Map<String, dynamic>>>
      getTransactions() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedTransactions =
        prefs.getStringList(
              _transactionsKey,
            ) ??
            [];

    final List<Map<String, dynamic>>
        transactions = [];

    for (final item in savedTransactions) {
      try {
        transactions.add(
          Map<String, dynamic>.from(
            jsonDecode(item),
          ),
        );
      } catch (error) {
        continue;
      }
    }

    transactions.sort((a, b) {
      final dateA = DateTime.tryParse(
            a['createdAt']?.toString() ?? '',
          ) ??
          DateTime(1970);

      final dateB = DateTime.tryParse(
            b['createdAt']?.toString() ?? '',
          ) ??
          DateTime(1970);

      return dateB.compareTo(dateA);
    });

    return transactions;
  }

  static Future<void> _saveTransactions(
    List<Map<String, dynamic>>
        transactions,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final encodedTransactions =
        transactions
            .map(
              (transaction) =>
                  jsonEncode(transaction),
            )
            .toList();

    final bool saved =
        await prefs.setStringList(
      _transactionsKey,
      encodedTransactions,
    );

    if (!saved) {
      throw StateError(
        'Failed to save wallet transaction',
      );
    }
  }

  static Future<void> addMoney({
    required double amount,
    String paymentMethod = 'Manual',
    String? paymentReference,
  }) async {
    if (amount <= 0) {
      throw ArgumentError(
        'Amount must be greater than 0',
      );
    }

    final transactions =
        await getTransactions();

    final transaction =
        <String, dynamic>{
      'id': DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      'type': 'credit',
      'amount': amount,
      'category': 'Add Money',
      'destination': 'Wallet',
      'paymentMethod': paymentMethod,
      'paymentReference':
          paymentReference ?? '',
      'status': 'success',
      'createdAt':
          DateTime.now().toIso8601String(),
    };

    transactions.insert(
      0,
      transaction,
    );

    await _saveTransactions(
      transactions,
    );
  }

  static Future<void> allocateMoney({
    required double amount,
    required String destination,
    String? destinationId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError(
        'Amount must be greater than 0',
      );
    }

    final balance =
        await getWalletBalance();

    if (amount > balance) {
      throw StateError(
        'Insufficient wallet balance',
      );
    }

    final transactions =
        await getTransactions();

    final transaction =
        <String, dynamic>{
      'id': DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      'type': 'debit',
      'amount': amount,
      'category': 'Allocation',
      'destination': destination,
      'destinationId':
          destinationId ?? '',
      'paymentMethod': 'Wallet',
      'paymentReference': '',
      'status': 'success',
      'createdAt':
          DateTime.now().toIso8601String(),
    };

    transactions.insert(
      0,
      transaction,
    );

    await _saveTransactions(
      transactions,
    );
  }

  static Future<void>
      allocateToGoalSafely({
    required double amount,
    required String goalId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError(
        'Amount must be greater than 0',
      );
    }

    final double balance =
        await getWalletBalance();

    if (amount > balance) {
      throw StateError(
        'Insufficient wallet balance',
      );
    }

    final goals =
        await GoalService.getGoals();

    final int goalIndex =
        goals.indexWhere(
      (goal) =>
          goal['id']?.toString() ==
          goalId,
    );

    if (goalIndex == -1) {
      throw StateError(
        'Goal not found',
      );
    }

    final Map<String, dynamic> goal =
        Map<String, dynamic>.from(
      goals[goalIndex],
    );

    final String goalName =
        goal['goalName']?.toString() ??
            'Financial Goal';

    final double targetAmount =
        _getDouble(
      goal,
      'targetAmount',
    );

    final double oldSavedAmount =
        _getDouble(
      goal,
      'savedAmount',
    );

    final double remainingAmount =
        targetAmount -
            oldSavedAmount;

    if (remainingAmount <= 0) {
      throw StateError(
        'Goal is already completed',
      );
    }

    if (amount > remainingAmount) {
      throw StateError(
        'Amount exceeds the remaining goal amount',
      );
    }

    bool goalUpdated = false;

    try {
      await GoalService.addSavingsToGoal(
        id: goalId,
        amount: amount,
      );

      goalUpdated = true;

      await allocateMoney(
        amount: amount,
        destination: goalName,
        destinationId: goalId,
      );
    } catch (error) {
      if (goalUpdated) {
        try {
          await GoalService.updateGoal(
            id: goalId,
            goalName: goalName,
            targetAmount: targetAmount,
            savedAmount:
                oldSavedAmount,
          );
        } catch (_) {
          throw StateError(
            'Wallet allocation failed and goal rollback also failed',
          );
        }
      }

      rethrow;
    }
  }

  static Future<void>
      allocateToEmergencyFundSafely({
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError(
        'Amount must be greater than 0',
      );
    }

    final double balance =
        await getWalletBalance();

    if (amount > balance) {
      throw StateError(
        'Insufficient wallet balance',
      );
    }

    final emergencyFund =
        await EmergencyFundService
            .getEmergencyFund();

    if (emergencyFund == null) {
      throw StateError(
        'Emergency fund plan not found',
      );
    }

    final double
        monthlyEssentialExpenses =
        _getDouble(
      emergencyFund,
      'monthlyEssentialExpenses',
    );

    final int targetMonths =
        _getInt(
      emergencyFund,
      'targetMonths',
    );

    final double oldCurrentFund =
        _getDouble(
      emergencyFund,
      'currentFund',
    );

    final double targetAmount =
        monthlyEssentialExpenses *
            targetMonths;

    final double remainingAmount =
        targetAmount -
            oldCurrentFund;

    if (targetAmount <= 0) {
      throw StateError(
        'Emergency fund target is invalid',
      );
    }

    if (remainingAmount <= 0) {
      throw StateError(
        'Emergency fund target is already completed',
      );
    }

    if (amount > remainingAmount) {
      throw StateError(
        'Amount exceeds the remaining emergency fund target',
      );
    }

    bool emergencyFundUpdated = false;

    try {
      await EmergencyFundService
          .addMoneyToEmergencyFund(
        amount: amount,
      );

      emergencyFundUpdated = true;

      await allocateMoney(
        amount: amount,
        destination:
            'Emergency Fund',
      );
    } catch (error) {
      if (emergencyFundUpdated) {
        try {
          await EmergencyFundService
              .saveEmergencyFund(
            monthlyEssentialExpenses:
                monthlyEssentialExpenses,
            targetMonths:
                targetMonths,
            currentFund:
                oldCurrentFund,
          );
        } catch (_) {
          throw StateError(
            'Wallet allocation failed and emergency fund rollback also failed',
          );
        }
      }

      rethrow;
    }
  }

  static Future<double>
      getWalletBalance() async {
    final transactions =
        await getTransactions();

    double balance = 0;

    for (final transaction
        in transactions) {
      final amount = _getDouble(
        transaction,
        'amount',
      );

      final type =
          transaction['type']?.toString();

      final status =
          transaction['status']?.toString();

      if (status != 'success') {
        continue;
      }

      if (type == 'credit') {
        balance += amount;
      }

      if (type == 'debit') {
        balance -= amount;
      }
    }

    return balance < 0 ? 0 : balance;
  }

  static Future<double>
      getTotalAddedMoney() async {
    final transactions =
        await getTransactions();

    double total = 0;

    for (final transaction
        in transactions) {
      if (transaction['type'] ==
              'credit' &&
          transaction['status'] ==
              'success') {
        total += _getDouble(
          transaction,
          'amount',
        );
      }
    }

    return total;
  }

  static Future<double>
      getTotalAllocatedMoney() async {
    final transactions =
        await getTransactions();

    double total = 0;

    for (final transaction
        in transactions) {
      if (transaction['type'] ==
              'debit' &&
          transaction['status'] ==
              'success') {
        total += _getDouble(
          transaction,
          'amount',
        );
      }
    }

    return total;
  }

  static Future<void>
      clearWalletData() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _transactionsKey,
    );
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
}