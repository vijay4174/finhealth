import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'monthly_service.dart';
import 'premium_page.dart';
import 'subscription_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() =>
      _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<Map<String, dynamic>> records = [];

  bool isLoading = true;
  bool isPremium = false;

  final List<String> monthNames = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final savedRecords =
        await MonthlyService.getMonthlyRecords();

    final premiumStatus =
        await SubscriptionService.isPremium();

    savedRecords.sort((a, b) {
      final dateA = DateTime(
        (a['year'] as num).toInt(),
        (a['month'] as num).toInt(),
      );

      final dateB = DateTime(
        (b['year'] as num).toInt(),
        (b['month'] as num).toInt(),
      );

      return dateA.compareTo(dateB);
    });

    if (!mounted) return;

    setState(() {
      records = savedRecords;
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  Future<void> openPremiumPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PremiumPage(),
      ),
    );

    await loadRecords();
  }

  double getAmount(
    Map<String, dynamic> record,
    String key,
  ) {
    final value = record[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double getTotal(String key) {
    return records.fold<double>(
      0,
      (total, record) =>
          total + getAmount(record, key),
    );
  }

  double getAverage(String key) {
    if (records.isEmpty) return 0;

    return getTotal(key) / records.length;
  }

  double getPercentageChange(
    String key,
  ) {
    if (records.length < 2) return 0;

    final current =
        getAmount(records.last, key);

    final previous =
        getAmount(
      records[records.length - 2],
      key,
    );

    if (previous == 0) {
      return current > 0 ? 100 : 0;
    }

    return ((current - previous) / previous) *
        100;
  }

  String getLatestMonthName() {
    if (records.isEmpty) return '';

    final latest = records.last;

    final month =
        (latest['month'] as num).toInt();

    final year =
        (latest['year'] as num).toInt();

    return '${monthNames[month - 1]} $year';
  }

  String getPreviousMonthName() {
    if (records.length < 2) return '';

    final previous =
        records[records.length - 2];

    final month =
        (previous['month'] as num).toInt();

    final year =
        (previous['year'] as num).toInt();

    return '${monthNames[month - 1]} $year';
  }

  Color getChangeColor(
    String key,
    double change,
  ) {
    if (change == 0) {
      return Colors.grey;
    }

    if (key == 'expenses') {
      return change < 0
          ? Colors.green
          : Colors.red;
    }

    return change > 0
        ? Colors.green
        : Colors.red;
  }

  IconData getChangeIcon(
    String key,
    double change,
  ) {
    if (change == 0) {
      return Icons.remove;
    }

    if (key == 'expenses') {
      return change < 0
          ? Icons.trending_down
          : Icons.trending_up;
    }

    return change > 0
        ? Icons.trending_up
        : Icons.trending_down;
  }

  double getMaxValue(String key) {
    if (records.isEmpty) return 1;

    double maxValue = 0;

    for (final record in records) {
      final value =
          getAmount(record, key);

      if (value > maxValue) {
        maxValue = value;
      }
    }

    return maxValue > 0 ? maxValue : 1;
  }

  Widget buildPremiumLockCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock premium analytics',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Access richer comparisons, animated trends, and premium insights with one tap.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          _buildLockFeature(Icons.compare_arrows_rounded, 'Month-to-month comparisons'),
          _buildLockFeature(Icons.insights_rounded, 'Smarter financial insight cards'),
          _buildLockFeature(Icons.savings_rounded, 'Savings and investment trends'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: openPremiumPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Unlock Advanced Analytics'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 82,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics', style: TextStyle(color: AppTheme.text, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Track your financial performance', style: TextStyle(color: AppTheme.subtitle, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.warning]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.16), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: const Center(child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : records.isEmpty
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
                            ),
                            child: const Icon(Icons.analytics_outlined, size: 64, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 20),
                          const Text('No analytics available', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.text)),
                          const SizedBox(height: 8),
                          const Text('Add monthly financial records first to view premium insights.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.subtitle, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadRecords,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Premium overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text)),
                                          const SizedBox(height: 2),
                                          Text('Your financial story at a glance', style: TextStyle(color: AppTheme.subtitle, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    if (isPremium)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.workspace_premium_rounded, size: 14, color: AppTheme.primary),
                                            SizedBox(width: 4),
                                            Text('Premium', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.12,
                                children: [
                                  buildSummaryCard(title: 'Avg Income', amount: getAverage('income'), icon: Icons.account_balance_wallet_rounded),
                                  buildSummaryCard(title: 'Avg Expenses', amount: getAverage('expenses'), icon: Icons.payments_rounded),
                                  buildSummaryCard(title: 'Avg Savings', amount: getAverage('savings'), icon: Icons.savings_rounded),
                                  buildSummaryCard(title: 'Avg Investments', amount: getAverage('investments'), icon: Icons.trending_up_rounded),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (!isPremium) buildPremiumLockCard(),
                              if (isPremium) ...[
                                if (records.length >= 2) ...[
                                  const SizedBox(height: 2),
                                  Text('${getLatestMonthName()} vs ${getPreviousMonthName()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
                                  const SizedBox(height: 10),
                                  buildComparisonCard(title: 'Income', keyName: 'income', icon: Icons.account_balance_wallet_rounded),
                                  buildComparisonCard(title: 'Expenses', keyName: 'expenses', icon: Icons.payments_rounded),
                                  buildComparisonCard(title: 'Savings', keyName: 'savings', icon: Icons.savings_rounded),
                                  buildComparisonCard(title: 'Investments', keyName: 'investments', icon: Icons.trending_up_rounded),
                                  const SizedBox(height: 14),
                                ],
                                if (records.length < 2)
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.calendar_month_outlined, size: 40, color: AppTheme.primary),
                                        const SizedBox(height: 10),
                                        const Text('More data needed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
                                        const SizedBox(height: 8),
                                        const Text('Add at least 2 months of records to view month-to-month comparisons.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.subtitle, height: 1.4)),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                const Text('Monthly trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
                                const SizedBox(height: 10),
                                buildTrendSection(title: 'Income Trend', keyName: 'income', icon: Icons.account_balance_wallet_rounded),
                                buildTrendSection(title: 'Expense Trend', keyName: 'expenses', icon: Icons.payments_rounded),
                                buildTrendSection(title: 'Savings Trend', keyName: 'savings', icon: Icons.savings_rounded),
                                buildTrendSection(title: 'Investment Trend', keyName: 'investments', icon: Icons.trending_up_rounded),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
  }) {
    final trend = title.contains('Expenses') ? '-3%' : '+8%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF5B8CFF)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: title.contains('Expenses') ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(trend, style: TextStyle(color: title.contains('Expenses') ? AppTheme.danger : AppTheme.success, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12.5, color: AppTheme.subtitle, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: amount),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text('₹${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text));
            },
          ),
        ],
      ),
    );
  }

  Widget buildComparisonCard({
    required String title,
    required String keyName,
    required IconData icon,
  }) {
    final change = getPercentageChange(keyName);
    final current = getAmount(records.last, keyName);
    final color = getChangeColor(keyName, change);
    final maxValue = getMaxValue(keyName);
    final progress = (getAmount(records.last, keyName) / maxValue).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withOpacity(0.22), color.withOpacity(0.08)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
                    const SizedBox(height: 2),
                    Text('Latest: ₹${current.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.subtitle, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    Icon(getChangeIcon(keyName, change), color: color, size: 14),
                    const SizedBox(width: 4),
                    Text('${change.abs().toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: value,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildTrendSection({
    required String title,
    required String keyName,
    required IconData icon,
  }) {
    final maxValue = getMaxValue(keyName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF5B8CFF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.text)),
            ],
          ),
          const SizedBox(height: 16),
          ...records.map((record) {
            final month = (record['month'] as num).toInt();
            final year = (record['year'] as num).toInt();
            final value = getAmount(record, keyName);
            final progress = (value / maxValue).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
                        child: Text('${monthNames[month - 1]} $year', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.subtitle)),
                      ),
                      const Spacer(),
                      Text('₹${value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: animatedValue,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(keyName == 'expenses' ? AppTheme.danger : AppTheme.primary),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}