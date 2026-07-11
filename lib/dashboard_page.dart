import 'dart:convert';

import 'package:flutter/material.dart';

import 'analytics_page.dart';
import 'budget_page.dart';
import 'debt_page.dart';
import 'emergency_fund_page.dart';
import 'financial_details.dart';
import 'goal_service.dart';
import 'goals_page.dart';
import 'history_service.dart';
import 'monthly_service.dart';
import 'monthly_tracking_page.dart';
import 'recommendations_page.dart';
import 'savings_wallet_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;

  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> monthlyRecords = [];
  List<Map<String, dynamic>> goals = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final historyStrings =
        await HistoryService.getHistory();

    final savedMonthlyRecords =
        await MonthlyService.getMonthlyRecords();

    final savedGoals =
        await GoalService.getGoals();

    final decodedHistory = historyStrings.map((item) {
      return Map<String, dynamic>.from(
        jsonDecode(item),
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      history = decodedHistory;
      monthlyRecords = savedMonthlyRecords;
      goals = savedGoals;
      isLoading = false;
    });
  }

  Map<String, dynamic>? get latestHistory {
    if (history.isEmpty) return null;

    return history.first;
  }

  Map<String, dynamic>? get latestMonthlyRecord {
    if (monthlyRecords.isEmpty) return null;

    final sortedRecords =
        List<Map<String, dynamic>>.from(
      monthlyRecords,
    );

    sortedRecords.sort((a, b) {
      final dateA = DateTime(
        (a['year'] as num).toInt(),
        (a['month'] as num).toInt(),
      );

      final dateB = DateTime(
        (b['year'] as num).toInt(),
        (b['month'] as num).toInt(),
      );

      return dateB.compareTo(dateA);
    });

    return sortedRecords.first;
  }

  double getDoubleValue(
    Map<String, dynamic>? data,
    String key,
  ) {
    if (data == null) return 0;

    final value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  bool getBoolValue(
    Map<String, dynamic>? data,
    String key,
  ) {
    if (data == null) return false;

    final value = data[key];

    if (value is bool) {
      return value;
    }

    final text =
        value?.toString().toLowerCase() ?? '';

    return text == 'true' ||
        text == 'yes' ||
        text == '1';
  }

  int get latestScore {
    final latest = latestHistory;

    if (latest == null) return 0;

    final value = latest['score'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String get latestStatus {
    final latest = latestHistory;

    if (latest == null) {
      return 'No Assessment';
    }

    return latest['status']?.toString() ??
        'No Assessment';
  }

  Color getStatusColor() {
    if (latestScore >= 80) {
      return Colors.green;
    } else if (latestScore >= 60) {
      return Colors.orange;
    } else if (latestScore >= 40) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  double get totalGoalTarget {
    return goals.fold<double>(
      0,
      (total, goal) =>
          total +
          getDoubleValue(
            goal,
            'targetAmount',
          ),
    );
  }

  double get totalGoalSaved {
    return goals.fold<double>(
      0,
      (total, goal) =>
          total +
          getDoubleValue(
            goal,
            'savedAmount',
          ),
    );
  }

  double get goalProgress {
    if (totalGoalTarget <= 0) return 0;

    return (totalGoalSaved / totalGoalTarget)
        .clamp(0.0, 1.0);
  }

  Future<void> openAssessment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const FinancialDetailsPage(),
      ),
    );

    await loadDashboard();
  }

  Future<void> openMonthlyTracking() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const MonthlyTrackingPage(),
      ),
    );

    await loadDashboard();
  }

  Future<void> openGoals() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const GoalsPage(),
      ),
    );

    await loadDashboard();
  }

  Future<void> openSavingsWallet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SavingsWalletPage(),
      ),
    );

    await loadDashboard();
  }

  void openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AnalyticsPage(),
      ),
    );
  }

  void openBudgetPlanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const BudgetPage(),
      ),
    );
  }

  void openEmergencyFund() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EmergencyFundPage(),
      ),
    );
  }

  void openDebtTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const DebtPage(),
      ),
    );
  }

  void openRecommendations() {
    final monthly = latestMonthlyRecord;
    final assessment = latestHistory;

    final double income = monthly != null
        ? getDoubleValue(
            monthly,
            'income',
          )
        : getDoubleValue(
            assessment,
            'income',
          );

    final double expenses = monthly != null
        ? getDoubleValue(
            monthly,
            'expenses',
          )
        : getDoubleValue(
            assessment,
            'expenses',
          );

    final double savings = monthly != null
        ? getDoubleValue(
            monthly,
            'savings',
          )
        : getDoubleValue(
            assessment,
            'savings',
          );

    final double investments = monthly != null
        ? getDoubleValue(
            monthly,
            'investments',
          )
        : getDoubleValue(
            assessment,
            'investments',
          );

    final double emergencyFund =
        getDoubleValue(
      assessment,
      'emergencyFund',
    );

    final double totalDebt =
        getDoubleValue(
      assessment,
      'totalDebt',
    );

    final bool hasHealthInsurance =
        getBoolValue(
      assessment,
      'hasHealthInsurance',
    );

    final bool hasTermInsurance =
        getBoolValue(
      assessment,
      'hasTermInsurance',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecommendationsPage(
          income: income,
          expenses: expenses,
          savings: savings,
          investments: investments,
          emergencyFund: emergencyFund,
          totalDebt: totalDebt,
          hasHealthInsurance:
              hasHealthInsurance,
          hasTermInsurance:
              hasTermInsurance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthly = latestMonthlyRecord;

    final double income =
        getDoubleValue(
      monthly,
      'income',
    );

    final double expenses =
        getDoubleValue(
      monthly,
      'expenses',
    );

    final double savings =
        getDoubleValue(
      monthly,
      'savings',
    );

    final double investments =
        getDoubleValue(
      monthly,
      'investments',
    );

    return Scaffold(
  backgroundColor: const Color(0xFFF5F7FB),
     appBar: AppBar(
  backgroundColor: const Color(0xFFF5F7FB),
  elevation: 0,
  centerTitle: false,
  toolbarHeight: 80,
  title: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "👋 Good Morning, Vijay",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
      ),
      SizedBox(height: 2),
      Text(
        "Welcome back to FinHealth",
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
      ),
    ],
  ),
),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
  width: double.infinity,
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      colors: [
        Color(0xFF2563EB),
        Color(0xFF3B82F6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.blueAccent.withOpacity(0.25),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: Column(
    children: [
      const Text(
        "Financial Health Score",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 18),

      CircleAvatar(
  radius: 54,
  backgroundColor: Colors.white.withOpacity(0.20),
  child: CircleAvatar(
    radius: 46,
    backgroundColor: Colors.white,
    child: Text(
      history.isEmpty ? "--" : "$latestScore",
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: getStatusColor(),
      ),
    ),
  ),
),

      const SizedBox(height: 16),

      Text(
        latestStatus,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 18),

      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: history.isEmpty ? 0 : latestScore / 100,
          minHeight: 10,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        ),
      ),

      const SizedBox(height: 20),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: openAssessment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            history.isEmpty
                ? "Start Assessment"
                : "Recalculate Score",
          ),
        ),
      ),
    ],
  ),
),

                  const SizedBox(height: 20),

                  const Text(
  "Today's Financial Snapshot",
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
  ),
),

                  const SizedBox(height: 12),

                  GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 14,
  mainAxisSpacing: 14,
  childAspectRatio: 1.18,
  children: [
    buildSnapshotTile(
      title: "Income",
      amount: income,
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF22C55E),
    ),
    buildSnapshotTile(
      title: "Expenses",
      amount: expenses,
      icon: Icons.payments_rounded,
      color: const Color(0xFFEF4444),
    ),
    buildSnapshotTile(
      title: "Savings",
      amount: savings,
      icon: Icons.savings_rounded,
      color: const Color(0xFF2563EB),
    ),
    buildSnapshotTile(
      title: "Investments",
      amount: investments,
      icon: Icons.trending_up_rounded,
      color: const Color(0xFFF59E0B),
    ),
  ],
),

                  const SizedBox(height: 20),

                  const Text(
  'Goals & Dreams',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
  ),
),
const SizedBox(height: 4),

const Text(
  'Track your financial goals',
  style: TextStyle(
    fontSize: 14,
    color: Color(0xFF6B7280),
  ),
),

                  const SizedBox(height: 12),

                  Container(
  padding: const EdgeInsets.all(22),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 15,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  
                      child: goals.isEmpty
                          ? Column(
                              children: [
                                const Icon(
                                  Icons.flag_outlined,
                                  size: 45,
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  'No financial goals created',
                                ),

                                const SizedBox(height: 15),

                                ElevatedButton(
                                  onPressed: openGoals,
                                  child: const Text(
                                    'Create Goal',
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Text(
  "${(goalProgress * 100).toStringAsFixed(0)}%",
  style: const TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2563EB),
  ),
),
                                

                                const SizedBox(height: 12),

                                ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: LinearProgressIndicator(
    value: goalProgress,
    minHeight: 12,
    backgroundColor: Colors.grey.shade200,
    valueColor: const AlwaysStoppedAnimation(
      Color(0xFF2563EB),
    ),
  ),
),
                                const SizedBox(height: 12),

                                Text(
  "₹${totalGoalSaved.toStringAsFixed(0)} of ₹${totalGoalTarget.toStringAsFixed(0)} Saved",
  style: const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
  ),
),

                                const SizedBox(height: 12),

                                Text(
                                  '${goals.length} active goal${goals.length == 1 ? '' : 's'}',
                                ),

                                const SizedBox(height: 15),

                                ElevatedButton(
                                  onPressed: openGoals,
                                  child: const Text(
                                    'View Goals',
                                  ),
                                ),
                              ],
                            ),
                    ),
                

                  const SizedBox(height: 28),

                  const Text(
  'Services',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
  ),
),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      buildQuickAction(
                        icon: Icons
                            .account_balance_wallet,
                        title: 'Smart Wallet',
                        onTap: openSavingsWallet,
                      ),

                      buildQuickAction(
                        icon: Icons.calculate,
                        title: 'Assessment',
                        onTap: openAssessment,
                      ),

                      buildQuickAction(
                        icon: Icons.calendar_month,
                        title: 'Monthly Track',
                        onTap: openMonthlyTracking,
                      ),

                      buildQuickAction(
                        icon: Icons.flag,
                        title: 'Goals',
                        onTap: openGoals,
                      ),

                      buildQuickAction(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        onTap: openAnalytics,
                      ),

                      buildQuickAction(
                        icon: Icons
                            .account_balance_wallet_outlined,
                        title: 'Budget Planner',
                        onTap: openBudgetPlanner,
                      ),

                      buildQuickAction(
                        icon: Icons.shield_outlined,
                        title: 'Emergency Fund',
                        onTap: openEmergencyFund,
                      ),

                      buildQuickAction(
                        icon: Icons.credit_card,
                        title: 'Debt Tracker',
                        onTap: openDebtTracker,
                      ),

                      buildQuickAction(
                        icon: Icons.lightbulb_outline,
                        title: 'Recommendations',
                        onTap: openRecommendations,
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
Widget buildPremiumSummaryCard({
  required IconData icon,
  required String title,
  required double amount,
  required Color color,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            icon,
            color: color,
            size: 26,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "₹${amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),

        Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.grey.shade400,
          size: 18,
        ),
      ],
    ),
  );
}
Widget buildSnapshotTile({
  required String title,
  required double amount,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(.12),
          child: Icon(icon, color: color),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    ),
  );
}
  Widget buildSummaryRow({
    required IconData icon,
    required String title,
    required double amount,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        '₹${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildQuickAction({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 12,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE8F1FF),
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                  size: 28,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}