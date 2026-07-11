import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _isPremiumKey = 'isPremium';
  static const String _freeBillScansUsedKey =
      'freeBillScansUsed';

  static const int freeHistoryLimit = 5;
  static const int freeMonthlyTrackingLimit = 6;
  static const int freeGoalsLimit = 3;
  static const int freeDebtsLimit = 3;
  static const int freeBillScanLimit = 3;

  static Future<bool> isPremium() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(_isPremiumKey) ?? false;
  }

  static Future<void> setPremium(
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _isPremiumKey,
      value,
    );
  }

  static Future<int>
      getFreeBillScansUsed() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt(
          _freeBillScansUsedKey,
        ) ??
        0;
  }

  static Future<int>
      getRemainingFreeBillScans() async {
    final used =
        await getFreeBillScansUsed();

    return (freeBillScanLimit - used).clamp(
      0,
      freeBillScanLimit,
    );
  }

  static Future<bool>
      canUseBillScanner() async {
    if (await isPremium()) {
      return true;
    }

    final used =
        await getFreeBillScansUsed();

    return used < freeBillScanLimit;
  }

  static Future<void>
      recordBillScan() async {
    if (await isPremium()) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final used =
        await getFreeBillScansUsed();

    final newValue = (used + 1).clamp(
      0,
      freeBillScanLimit,
    );

    await prefs.setInt(
      _freeBillScansUsedKey,
      newValue,
    );
  }

  static Future<bool> canAddGoal(
    int currentGoalCount,
  ) async {
    if (await isPremium()) {
      return true;
    }

    return currentGoalCount <
        freeGoalsLimit;
  }

  static Future<bool> canAddDebt(
    int currentDebtCount,
  ) async {
    if (await isPremium()) {
      return true;
    }

    return currentDebtCount <
        freeDebtsLimit;
  }

  static Future<bool> canAddMonthlyRecord(
    int currentRecordCount,
  ) async {
    if (await isPremium()) {
      return true;
    }

    return currentRecordCount <
        freeMonthlyTrackingLimit;
  }

  static Future<bool>
      hasUnlimitedHistory() async {
    return isPremium();
  }

  static Future<bool>
      hasUnlimitedMonthlyTracking() async {
    return isPremium();
  }

  static Future<bool>
      hasAdvancedAnalytics() async {
    return isPremium();
  }

  static Future<bool>
      hasEmiNotifications() async {
    return isPremium();
  }

  static Future<bool>
      hasPdfReports() async {
    return isPremium();
  }

  static Future<bool>
      hasAdvancedBudgetInsights() async {
    return isPremium();
  }

  static Future<bool>
      hasAdvancedRecommendations() async {
    return isPremium();
  }

  static Future<bool>
      hasGoalReminders() async {
    return isPremium();
  }

  static Future<bool>
      hasAdvancedEmergencyFund() async {
    return isPremium();
  }
}