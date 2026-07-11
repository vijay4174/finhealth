import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GoalService {
  static const String goalsKey =
      'financial_goals';

  static Future<void> addGoal({
    required String goalName,
    required double targetAmount,
    required double savedAmount,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> goals =
        List<String>.from(
      prefs.getStringList(goalsKey) ?? [],
    );

    final Map<String, dynamic> goal = {
      'id': DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      'goalName': goalName,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'createdAt':
          DateTime.now().toIso8601String(),
    };

    goals.insert(
      0,
      jsonEncode(goal),
    );

    await prefs.setStringList(
      goalsKey,
      goals,
    );
  }

  static Future<List<Map<String, dynamic>>>
      getGoals() async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> goals =
        prefs.getStringList(goalsKey) ?? [];

    return goals.map((goal) {
      return Map<String, dynamic>.from(
        jsonDecode(goal),
      );
    }).toList();
  }

  static Future<void> updateGoal({
    required String id,
    required String goalName,
    required double targetAmount,
    required double savedAmount,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> goals =
        List<String>.from(
      prefs.getStringList(goalsKey) ?? [],
    );

    final int index =
        goals.indexWhere((goal) {
      final Map<String, dynamic>
          decodedGoal =
          Map<String, dynamic>.from(
        jsonDecode(goal),
      );

      return decodedGoal['id']
              .toString() ==
          id;
    });

    if (index == -1) return;

    final Map<String, dynamic> oldGoal =
        Map<String, dynamic>.from(
      jsonDecode(goals[index]),
    );

    final Map<String, dynamic>
        updatedGoal = {
      ...oldGoal,
      'goalName': goalName,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
    };

    goals[index] =
        jsonEncode(updatedGoal);

    await prefs.setStringList(
      goalsKey,
      goals,
    );
  }

  static Future<void> addSavingsToGoal({
    required String id,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError(
        'Amount must be greater than 0',
      );
    }

    final prefs =
        await SharedPreferences.getInstance();

    final List<String> goals =
        List<String>.from(
      prefs.getStringList(goalsKey) ?? [],
    );

    final int index =
        goals.indexWhere((goal) {
      final Map<String, dynamic>
          decodedGoal =
          Map<String, dynamic>.from(
        jsonDecode(goal),
      );

      return decodedGoal['id']
              .toString() ==
          id;
    });

    if (index == -1) {
      throw StateError(
        'Goal not found',
      );
    }

    final Map<String, dynamic> goal =
        Map<String, dynamic>.from(
      jsonDecode(goals[index]),
    );

    final double targetAmount =
        _getDouble(
      goal,
      'targetAmount',
    );

    final double currentSavedAmount =
        _getDouble(
      goal,
      'savedAmount',
    );

    final double remainingAmount =
        targetAmount -
            currentSavedAmount;

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

    final double newSavedAmount =
        currentSavedAmount + amount;

    final Map<String, dynamic>
        updatedGoal = {
      ...goal,
      'savedAmount': newSavedAmount,
      'updatedAt':
          DateTime.now().toIso8601String(),
    };

    goals[index] =
        jsonEncode(updatedGoal);

    await prefs.setStringList(
      goalsKey,
      goals,
    );
  }

  static Future<void> deleteGoal(
    String id,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> goals =
        List<String>.from(
      prefs.getStringList(goalsKey) ?? [],
    );

    goals.removeWhere((goal) {
      final Map<String, dynamic>
          decodedGoal =
          Map<String, dynamic>.from(
        jsonDecode(goal),
      );

      return decodedGoal['id']
              .toString() ==
          id;
    });

    await prefs.setStringList(
      goalsKey,
      goals,
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
}