import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MonthlyService {
  static const String monthlyDataKey =
      'monthly_financial_records';

  static Future<void> saveMonthlyRecord({
    required int year,
    required int month,
    required double income,
    required double expenses,
    required double savings,
    required double investments,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> records = List<String>.from(
      prefs.getStringList(monthlyDataKey) ?? [],
    );

    final String recordId = '$year-$month';

    final Map<String, dynamic> newRecord = {
      'id': recordId,
      'year': year,
      'month': month,
      'income': income,
      'expenses': expenses,
      'savings': savings,
      'investments': investments,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final int existingIndex =
        records.indexWhere((record) {
      final Map<String, dynamic> decoded =
          Map<String, dynamic>.from(
        jsonDecode(record),
      );

      return decoded['id'].toString() == recordId;
    });

    if (existingIndex >= 0) {
      records[existingIndex] =
          jsonEncode(newRecord);
    } else {
      records.add(
        jsonEncode(newRecord),
      );
    }

    records.sort((a, b) {
      final Map<String, dynamic> recordA =
          Map<String, dynamic>.from(
        jsonDecode(a),
      );

      final Map<String, dynamic> recordB =
          Map<String, dynamic>.from(
        jsonDecode(b),
      );

      final int yearA =
          (recordA['year'] as num).toInt();

      final int monthA =
          (recordA['month'] as num).toInt();

      final int yearB =
          (recordB['year'] as num).toInt();

      final int monthB =
          (recordB['month'] as num).toInt();

      final DateTime dateA =
          DateTime(yearA, monthA);

      final DateTime dateB =
          DateTime(yearB, monthB);

      return dateB.compareTo(dateA);
    });

    await prefs.setStringList(
      monthlyDataKey,
      records,
    );
  }

  static Future<List<Map<String, dynamic>>>
      getMonthlyRecords() async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> records =
        prefs.getStringList(monthlyDataKey) ?? [];

    return records.map((record) {
      return Map<String, dynamic>.from(
        jsonDecode(record),
      );
    }).toList();
  }

  static Future<void> deleteMonthlyRecord(
    String id,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> records = List<String>.from(
      prefs.getStringList(monthlyDataKey) ?? [],
    );

    records.removeWhere((record) {
      final Map<String, dynamic> decoded =
          Map<String, dynamic>.from(
        jsonDecode(record),
      );

      return decoded['id'].toString() == id;
    });

    await prefs.setStringList(
      monthlyDataKey,
      records,
    );
  }

  static Future<void> clearMonthlyRecords() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(monthlyDataKey);
  }
}