import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'analytics_page.dart';
import 'app_theme.dart';
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
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;

  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> monthlyRecords = [];
  List<Map<String, dynamic>> goals = [];
  final Map<String, bool> _sectionVisible = {};

  @override
  void initState() {
    super.initState();
    loadDashboard();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int index = 0; index < 18; index++) {
        Future.delayed(Duration(milliseconds: 120 + (index * 80)), () {
          if (!mounted) return;
          setState(() {
            _sectionVisible['section_$index'] = true;
          });
        });
      }
    });
  }

  Future<void> loadDashboard() async {
    final historyStrings = await HistoryService.getHistory();
    final savedMonthlyRecords = await MonthlyService.getMonthlyRecords();
    final savedGoals = await GoalService.getGoals();

    final decodedHistory = historyStrings.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item));
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

    final sortedRecords = List<Map<String, dynamic>>.from(monthlyRecords);

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

  double getDoubleValue(Map<String, dynamic>? data, String key) {
    if (data == null) return 0;

    final value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool getBoolValue(Map<String, dynamic>? data, String key) {
    if (data == null) return false;

    final value = data[key];

    if (value is bool) {
      return value;
    }

    final text = value?.toString().toLowerCase() ?? '';

    return text == 'true' || text == 'yes' || text == '1';
  }

  int get latestScore {
    final latest = latestHistory;

    if (latest == null) return 0;

    final value = latest['score'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get latestStatus {
    final latest = latestHistory;

    if (latest == null) {
      return 'No Assessment';
    }

    return latest['status']?.toString() ?? 'No Assessment';
  }

  Color getStatusColor() {
    if (latestScore >= 80) {
      return AppTheme.success;
    } else if (latestScore >= 60) {
      return AppTheme.warning;
    } else if (latestScore >= 40) {
      return AppTheme.danger;
    } else {
      return AppTheme.danger;
    }
  }

  double get totalGoalTarget {
    return goals.fold<double>(
      0,
      (total, goal) => total + getDoubleValue(goal, 'targetAmount'),
    );
  }

  double get totalGoalSaved {
    return goals.fold<double>(
      0,
      (total, goal) => total + getDoubleValue(goal, 'savedAmount'),
    );
  }

  double get goalProgress {
    if (totalGoalTarget <= 0) return 0;

    return (totalGoalSaved / totalGoalTarget).clamp(0.0, 1.0);
  }

  Future<void> openAssessment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FinancialDetailsPage()),
    );

    await loadDashboard();
  }

  Future<void> openMonthlyTracking() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MonthlyTrackingPage()),
    );

    await loadDashboard();
  }

  Future<void> openGoals() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalsPage()),
    );

    await loadDashboard();
  }

  Future<void> openSavingsWallet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavingsWalletPage()),
    );

    await loadDashboard();
  }

  void openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsPage()),
    );
  }

  void openBudgetPlanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BudgetPage()),
    );
  }

  void openEmergencyFund() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyFundPage()),
    );
  }

  void openDebtTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DebtPage()),
    );
  }

  void openRecommendations() {
    final monthly = latestMonthlyRecord;
    final assessment = latestHistory;

    final double income = monthly != null
        ? getDoubleValue(monthly, 'income')
        : getDoubleValue(assessment, 'income');

    final double expenses = monthly != null
        ? getDoubleValue(monthly, 'expenses')
        : getDoubleValue(assessment, 'expenses');

    final double savings = monthly != null
        ? getDoubleValue(monthly, 'savings')
        : getDoubleValue(assessment, 'savings');

    final double investments = monthly != null
        ? getDoubleValue(monthly, 'investments')
        : getDoubleValue(assessment, 'investments');

    final double emergencyFund = getDoubleValue(assessment, 'emergencyFund');
    final double totalDebt = getDoubleValue(assessment, 'totalDebt');
    final bool hasHealthInsurance = getBoolValue(
      assessment,
      'hasHealthInsurance',
    );
    final bool hasTermInsurance = getBoolValue(assessment, 'hasTermInsurance');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationsPage(
          income: income,
          expenses: expenses,
          savings: savings,
          investments: investments,
          emergencyFund: emergencyFund,
          totalDebt: totalDebt,
          hasHealthInsurance: hasHealthInsurance,
          hasTermInsurance: hasTermInsurance,
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required Widget child, required int index}) {
    final visible = _sectionVisible['section_$index'] ?? false;

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  String _formatGreetingDate(DateTime date) {
    final weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final monthly = latestMonthlyRecord;

    final double income = getDoubleValue(monthly, 'income');
    final double expenses = getDoubleValue(monthly, 'expenses');
    final double savings = getDoubleValue(monthly, 'savings');
    final double investments = getDoubleValue(monthly, 'investments');

    final scoreValue = history.isEmpty ? 0 : latestScore;
    final scoreProgress = history.isEmpty
        ? 0.0
        : (scoreValue / 100).clamp(0.0, 1.0);
    final scoreColor = getStatusColor();
    final emergencyTarget = expenses * 3;
    final emergencyProgress = emergencyTarget <= 0
        ? 0.0
        : (savings / emergencyTarget).clamp(0.0, 1.0);
    final displayedGoals = goals.take(3).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 96,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, Vijay',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatGreetingDate(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.subtitle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAnimatedSection(
                            index: 0,
                            child: _buildScoreCard(
                              scoreValue,
                              scoreProgress,
                              scoreColor,
                              latestStatus,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 1,
                            child: _buildSectionTitle(
                              'Financial Snapshot',
                              'Your latest financial overview',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.95,
                                children: [
                                  _buildAnimatedSection(
                                    index: 2,
                                    child: buildSnapshotTile(
                                      title: 'Income',
                                      amount: income,
                                      icon: Icons.account_balance_wallet_rounded,
                                      color: const Color(0xFF22C55E),
                                    ),
                                  ),
                                  _buildAnimatedSection(
                                    index: 3,
                                    child: buildSnapshotTile(
                                      title: 'Expenses',
                                      amount: expenses,
                                      icon: Icons.payments_rounded,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                  _buildAnimatedSection(
                                    index: 4,
                                    child: buildSnapshotTile(
                                      title: 'Savings',
                                      amount: savings,
                                      icon: Icons.savings_rounded,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  _buildAnimatedSection(
                                    index: 5,
                                    child: buildSnapshotTile(
                                      title: 'Investments',
                                      amount: investments,
                                      icon: Icons.trending_up_rounded,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 6,
                            child: _buildEmergencyFundCard(
                              emergencyProgress,
                              savings,
                              emergencyTarget,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 7,
                            child: _buildGoalsCard(displayedGoals),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 8,
                            child: _buildSectionTitle(
                              'Quick Actions',
                              'Access your financial tools',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.2,
                                children: [
                                  _buildAnimatedSection(
                                    index: 9,
                                    child: buildQuickAction(
                                      icon: Icons.account_balance_wallet,
                                      title: 'Wallet',
                                      onTap: openSavingsWallet,
                                    ),
                                  ),
                                  _buildAnimatedSection(
                                    index: 10,
                                    child: buildQuickAction(
                                      icon: Icons.calculate,
                                      title: 'Assess',
                                      onTap: openAssessment,
                                    ),
                                  ),
                                  _buildAnimatedSection(
                                    index: 11,
                                    child: buildQuickAction(
                                      icon: Icons.calendar_month,
                                      title: 'Monthly',
                                      onTap: openMonthlyTracking,
                                    ),
                                  ),
                                  _buildAnimatedSection(
                                    index: 12,
                                    child: buildQuickAction(
                                      icon: Icons.flag,
                                      title: 'Goals',
                                      onTap: openGoals,
                                    ),
                                  ),
                                  _buildAnimatedSection(
                                    index: 13,
                                    child: buildQuickAction(
                                      icon: Icons.analytics,
                                      title: 'Analytics',
                                      onTap: openAnalytics,
                                    ),
                                  ),
                                  _buildAnimatedSection(
                                    index: 14,
                                    child: buildQuickAction(
                                      icon: Icons.account_balance_wallet_outlined,
                                      title: 'Budget',
                                      onTap: openBudgetPlanner,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 15,
                            child: _buildRecentActivityCard(),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 16,
                            child: _buildTipCard(),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 17,
                            child: _buildUpgradeCard(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAssessment,
        heroTag: 'dashboardAssessment',
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Assessment'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildScoreCard(
    int score,
    double progress,
    Color statusColor,
    String status,
  ) {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 700),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF081B3A), Color(0xFF1E4ACB), Color(0xFF5A8EFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.28),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              left: -28,
              bottom: -28,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withOpacity(0.16)),
                            ),
                            child: const Text(
                              'Financial Health Score',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.auto_awesome_rounded, color: Colors.white.withOpacity(0.95)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    tween: Tween<double>(begin: 0, end: progress),
                                    builder: (context, value, child) {
                                      return CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 8,
                                        backgroundColor: Colors.white24,
                                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      score.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your progress looks strong and momentum is building.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.88),
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    tween: Tween<double>(begin: 0, end: progress),
                                    builder: (context, value, child) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: value,
                                          minHeight: 10,
                                          backgroundColor: Colors.white24,
                                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: openAssessment,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(history.isEmpty ? 'Start Assessment' : 'Recalculate Score'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.subtitle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyFundCard(
    double progress,
    double savings,
    double target,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: progress),
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    );
                  },
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Emergency Fund',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.text),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Build a reliable safety buffer',
                            style: TextStyle(fontSize: 13, color: AppTheme.subtitle),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Stable',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You have built ${_formatCurrency(savings)} toward a ${_formatCurrency(target)} safety buffer.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.subtitle, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('₹${savings.toStringAsFixed(0)} saved', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text)),
                    const Spacer(),
                    Text('Target ₹${target.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.subtitle)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(List<Map<String, dynamic>> displayedGoals) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Goals Progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.text),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Track your financial goals',
                      style: TextStyle(fontSize: 13, color: AppTheme.subtitle),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: openGoals, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            Column(
              children: [
                const Text('No financial goals created yet. Create one to begin tracking.', style: TextStyle(color: AppTheme.subtitle)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: openGoals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Create Goal'),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(goalProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary),
                            ),
                            Text(
                              '₹${totalGoalSaved.toStringAsFixed(0)} / ₹${totalGoalTarget.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.text),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: goalProgress),
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: AppTheme.primary.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                if (displayedGoals.isNotEmpty)
                  Column(
                    children: displayedGoals.map((goal) {
                      final target = getDoubleValue(goal, 'targetAmount');
                      final saved = getDoubleValue(goal, 'savedAmount');
                      final percent = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primary.withOpacity(0.10),
                                  ),
                                  child: const Icon(Icons.savings_rounded, color: AppTheme.primary, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    goal['title']?.toString() ?? 'Goal',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.text),
                                  ),
                                ),
                                Text('${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.subtitle)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final recentItems = history.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.text)),
              SizedBox(height: 3),
              Text('Latest updates', style: TextStyle(fontSize: 13, color: AppTheme.subtitle)),
            ],
          ),
          const SizedBox(height: 12),
          if (recentItems.isEmpty)
            const Text('No recent activity yet. Complete an assessment to get started.', style: TextStyle(color: AppTheme.subtitle))
          else
            Column(
              children: recentItems.map((item) {
                final score = getDoubleValue(item, 'score');
                final status = item['status']?.toString() ?? 'Assessment';
                final dotColor = status.toLowerCase().contains('good') || status.toLowerCase().contains('excellent')
                    ? AppTheme.success
                    : AppTheme.warning;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                          ),
                          const SizedBox(height: 4),
                          Container(width: 1, height: 30, color: Colors.grey.shade200),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(status, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.text)),
                                    const SizedBox(height: 2),
                                    Text('Score ${score.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.subtitle, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('Just now', style: const TextStyle(color: AppTheme.subtitle, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFEEF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.primary.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.tips_and_updates_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Tip of the Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text)),
                SizedBox(height: 3),
                Text('Small habits create big wealth', style: TextStyle(fontSize: 13, color: AppTheme.subtitle)),
                SizedBox(height: 6),
                Text(
                  'Automate a small transfer to savings every payday to build momentum without feeling the pinch.',
                  style: TextStyle(color: AppTheme.subtitle, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.95), const Color(0xFF5B8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Upgrade to Premium', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('Unlock deeper insights, AI recommendations, and smarter planning tools.', style: TextStyle(color: Colors.white70, height: 1.45)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Upgrade'),
              ),
            ],
          ),
        ],
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
            child: Icon(icon, color: color, size: 26),
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
                    color: AppTheme.subtitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
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
    final trend = title == 'Income'
        ? '+5%'
        : title == 'Expenses'
            ? '-2%'
            : title == 'Savings'
                ? '+8%'
                : '+12%';
    final trendColor = title == 'Expenses' ? AppTheme.danger : AppTheme.success;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 132),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: AppTheme.subtitle, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              _formatCurrency(amount),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text),
            ),
          ],
        ),
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
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        double scale = 1.0;

        return GestureDetector(
          onTap: onTap,
          onTapDown: (_) => setLocalState(() => scale = 0.95),
          onTapUp: (_) => setLocalState(() => scale = 1.0),
          onTapCancel: () => setLocalState(() => scale = 1.0),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2563EB),
                                Color(0xFF5B8CFF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.24),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      final value = amount / 10000000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}Cr';
    }
    if (amount >= 100000) {
      final value = amount / 100000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}
