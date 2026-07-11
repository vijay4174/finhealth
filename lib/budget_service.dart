import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BudgetService {
  static const String _budgetKey = 'monthly_budget';

  static Future<void> saveBudget({
    required double monthlyIncome,
    required double food,
    required double rent,
    required double travel,
    required double shopping,
    required double bills,
    required double entertainment,
    required double other,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final Map<String, dynamic> budgetData = {
      'monthlyIncome': monthlyIncome,
      'food': food,
      'rent': rent,
      'travel': travel,
      'shopping': shopping,
      'bills': bills,
      'entertainment': entertainment,
      'other': other,
      'updatedAt':
          DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      _budgetKey,
      jsonEncode(budgetData),
    );
  }

  static Future<Map<String, dynamic>?>
      getBudget() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? savedBudget =
        prefs.getString(_budgetKey);

    if (savedBudget == null ||
        savedBudget.isEmpty) {
      return null;
    }

    try {
      return Map<String, dynamic>.from(
        jsonDecode(savedBudget),
      );
    } catch (error) {
      return null;
    }
  }

  static Future<bool> hasBudget() async {
    final budget = await getBudget();

    return budget != null;
  }

  static Future<void> clearBudget() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_budgetKey);
  }
}