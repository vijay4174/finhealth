import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EmergencyFundService {
  static const String _emergencyFundKey =
      'emergency_fund';

  static Future<void> saveEmergencyFund({
    required double monthlyEssentialExpenses,
    required int targetMonths,
    required double currentFund,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final Map<String, dynamic> data = {
      'monthlyEssentialExpenses':
          monthlyEssentialExpenses,
      'targetMonths': targetMonths,
      'currentFund': currentFund,
      'updatedAt':
          DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      _emergencyFundKey,
      jsonEncode(data),
    );
  }

  static Future<Map<String, dynamic>?>
      getEmergencyFund() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? savedData =
        prefs.getString(_emergencyFundKey);

    if (savedData == null ||
        savedData.isEmpty) {
      return null;
    }

    try {
      return Map<String, dynamic>.from(
        jsonDecode(savedData),
      );
    } catch (error) {
      return null;
    }
  }

  static Future<bool> hasEmergencyFund() async {
    final data = await getEmergencyFund();

    return data != null;
  }

  static Future<void>
      addMoneyToEmergencyFund({
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError(
        'Amount must be greater than 0',
      );
    }

    final data = await getEmergencyFund();

    if (data == null) {
      throw StateError(
        'Emergency fund plan not found',
      );
    }

    final double monthlyEssentialExpenses =
        _getDouble(
      data,
      'monthlyEssentialExpenses',
    );

    final int targetMonths =
        _getInt(
      data,
      'targetMonths',
    );

    final double currentFund =
        _getDouble(
      data,
      'currentFund',
    );

    final double targetAmount =
        monthlyEssentialExpenses *
            targetMonths;

    if (targetAmount <= 0) {
      throw StateError(
        'Emergency fund target is invalid',
      );
    }

    final double remainingAmount =
        targetAmount - currentFund;

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

    final double updatedCurrentFund =
        currentFund + amount;

    final prefs =
        await SharedPreferences.getInstance();

    final Map<String, dynamic> updatedData = {
      ...data,
      'currentFund': updatedCurrentFund,
      'updatedAt':
          DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      _emergencyFundKey,
      jsonEncode(updatedData),
    );
  }

  static Future<void>
      clearEmergencyFund() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _emergencyFundKey,
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