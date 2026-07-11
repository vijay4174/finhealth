import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ExpenseService {
  static const String _expenseKey =
      'smart_expenses';

  static Future<void> saveExpense({
    required double amount,
    required String category,
    required String title,
    required String source,
    String scannedText = '',
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> expenses =
        prefs.getStringList(_expenseKey) ?? [];

    final Map<String, dynamic> expense = {
      'id': DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      'amount': amount,
      'category': category,
      'title': title,
      'source': source,
      'scannedText': scannedText,
      'date': DateTime.now().toIso8601String(),
    };

    expenses.insert(
      0,
      jsonEncode(expense),
    );

    await prefs.setStringList(
      _expenseKey,
      expenses,
    );
  }

  static Future<List<Map<String, dynamic>>>
      getExpenses() async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> savedExpenses =
        prefs.getStringList(_expenseKey) ?? [];

    final List<Map<String, dynamic>> expenses = [];

    for (final item in savedExpenses) {
      try {
        expenses.add(
          Map<String, dynamic>.from(
            jsonDecode(item),
          ),
        );
      } catch (error) {
        continue;
      }
    }

    return expenses;
  }

  static Future<void> deleteExpense(
    String id,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> savedExpenses =
        prefs.getStringList(_expenseKey) ?? [];

    savedExpenses.removeWhere((item) {
      try {
        final data =
            Map<String, dynamic>.from(
          jsonDecode(item),
        );

        return data['id'].toString() == id;
      } catch (error) {
        return false;
      }
    });

    await prefs.setStringList(
      _expenseKey,
      savedExpenses,
    );
  }

  static Future<double> getCategorySpent(
    String category,
  ) async {
    final expenses = await getExpenses();

    return expenses
        .where(
          (expense) =>
              expense['category']
                  .toString()
                  .toLowerCase() ==
              category.toLowerCase(),
        )
        .fold<double>(
          0,
          (total, expense) =>
              total +
              ((expense['amount'] as num?)
                      ?.toDouble() ??
                  0),
        );
  }

  static Future<double>
      getTotalSpent() async {
    final expenses = await getExpenses();

    return expenses.fold<double>(
      0,
      (total, expense) =>
          total +
          ((expense['amount'] as num?)
                  ?.toDouble() ??
              0),
    );
  }

  static Future<void> clearExpenses() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_expenseKey);
  }
}