import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String historyKey =
      "financial_history";

  static Future<void> saveHistory({
    required int score,
    required String status,
    required double income,
    required double expenses,
    required double savings,
    required double investments,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> history =
        List<String>.from(
      prefs.getStringList(historyKey) ?? [],
    );

    final Map<String, dynamic> data = {
      "id":
          DateTime.now().microsecondsSinceEpoch.toString(),
      "date": DateTime.now().toIso8601String(),
      "score": score,
      "status": status,
      "income": income,
      "expenses": expenses,
      "savings": savings,
      "investments": investments,
    };

    history.insert(
      0,
      jsonEncode(data),
    );

    await prefs.setStringList(
      historyKey,
      history,
    );
  }

  static Future<List<String>> getHistory() async {
    final prefs =
        await SharedPreferences.getInstance();

    return List<String>.from(
      prefs.getStringList(historyKey) ?? [],
    );
  }

  static Future<void> deleteHistory(
    int index,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> history =
        List<String>.from(
      prefs.getStringList(historyKey) ?? [],
    );

    if (index < 0 || index >= history.length) {
      return;
    }

    history.removeAt(index);

    await prefs.setStringList(
      historyKey,
      history,
    );
  }

  static Future<void> clearHistory() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(historyKey);
  }
}