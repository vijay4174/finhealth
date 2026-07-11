import 'package:flutter/material.dart';

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
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.lock_outline,
              size: 55,
            ),

            const SizedBox(height: 15),

            const Text(
              'Advanced Analytics Locked',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Upgrade to Premium to unlock month-to-month comparisons, financial trends and advanced insights.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.compare_arrows,
              ),
              title: Text(
                'Month-to-Month Comparison',
              ),
            ),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.trending_up,
              ),
              title: Text(
                'Income & Expense Trends',
              ),
            ),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.savings_outlined,
              ),
              title: Text(
                'Savings & Investment Trends',
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openPremiumPage,
                icon: const Icon(
                  Icons.workspace_premium,
                ),
                label: const Text(
                  'Unlock Advanced Analytics',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Analytics',
        ),
        centerTitle: true,
        actions: [
          if (isPremium)
            const Padding(
              padding: EdgeInsets.only(
                right: 12,
              ),
              child: Icon(
                Icons.workspace_premium,
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : records.isEmpty
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.analytics_outlined,
                          size: 80,
                          color: Colors.deepPurple,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'No Analytics Available',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Add monthly financial records first to view trends and analytics.',
                          textAlign:
                              TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'At least 2 months of data is recommended for comparison.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadRecords,
                  child: ListView(
                    padding:
                        const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Financial Overview',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          if (isPremium)
                            const Chip(
                              avatar: Icon(
                                Icons
                                    .workspace_premium,
                                size: 18,
                              ),
                              label: Text(
                                'Premium',
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        children: [
                          buildSummaryCard(
                            title: 'Avg Income',
                            amount:
                                getAverage('income'),
                            icon: Icons
                                .account_balance_wallet,
                          ),

                          buildSummaryCard(
                            title: 'Avg Expenses',
                            amount:
                                getAverage('expenses'),
                            icon: Icons.money_off,
                          ),

                          buildSummaryCard(
                            title: 'Avg Savings',
                            amount:
                                getAverage('savings'),
                            icon: Icons.savings,
                          ),

                          buildSummaryCard(
                            title:
                                'Avg Investments',
                            amount: getAverage(
                              'investments',
                            ),
                            icon:
                                Icons.trending_up,
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      if (!isPremium)
                        buildPremiumLockCard(),

                      if (isPremium) ...[
                        if (records.length >= 2) ...[
                          Text(
                            '${getLatestMonthName()} vs ${getPreviousMonthName()}',
                            style:
                                const TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          buildComparisonCard(
                            title: 'Income',
                            keyName: 'income',
                            icon: Icons
                                .account_balance_wallet,
                          ),

                          buildComparisonCard(
                            title: 'Expenses',
                            keyName: 'expenses',
                            icon: Icons.money_off,
                          ),

                          buildComparisonCard(
                            title: 'Savings',
                            keyName: 'savings',
                            icon: Icons.savings,
                          ),

                          buildComparisonCard(
                            title: 'Investments',
                            keyName:
                                'investments',
                            icon:
                                Icons.trending_up,
                          ),

                          const SizedBox(
                            height: 15,
                          ),
                        ],

                        if (records.length < 2)
                          Card(
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                18,
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons
                                        .calendar_month_outlined,
                                    size: 40,
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),

                                  const Text(
                                    'More Data Needed',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  const Text(
                                    'Add at least 2 months of records to view month-to-month comparisons.',
                                    textAlign:
                                        TextAlign
                                            .center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        const Text(
                          'Monthly Trends',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        buildTrendSection(
                          title: 'Income Trend',
                          keyName: 'income',
                          icon: Icons
                              .account_balance_wallet,
                        ),

                        buildTrendSection(
                          title: 'Expense Trend',
                          keyName: 'expenses',
                          icon: Icons.money_off,
                        ),

                        buildTrendSection(
                          title: 'Savings Trend',
                          keyName: 'savings',
                          icon: Icons.savings,
                        ),

                        buildTrendSection(
                          title:
                              'Investment Trend',
                          keyName:
                              'investments',
                          icon:
                              Icons.trending_up,
                        ),
                      ],

                      const SizedBox(height: 30),
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
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            FittedBox(
              child: Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildComparisonCard({
    required String title,
    required String keyName,
    required IconData icon,
  }) {
    final change =
        getPercentageChange(keyName);

    final current =
        getAmount(records.last, keyName);

    final color =
        getChangeColor(keyName, change);

    return Card(
      elevation: 4,
      margin:
          const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Latest: ₹${current.toStringAsFixed(0)}',
        ),
        trailing: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              getChangeIcon(
                keyName,
                change,
              ),
              color: color,
            ),
            Text(
              '${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTrendSection({
    required String title,
    required String keyName,
    required IconData icon,
  }) {
    final maxValue =
        getMaxValue(keyName);

    return Card(
      elevation: 5,
      margin:
          const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),

                const SizedBox(width: 10),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ...records.map((record) {
              final month =
                  (record['month'] as num)
                      .toInt();

              final year =
                  (record['year'] as num)
                      .toInt();

              final value =
                  getAmount(
                record,
                keyName,
              );

              final progress =
                  (value / maxValue)
                      .clamp(0.0, 1.0);

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: Text(
                        '${monthNames[month - 1]} $year',
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child:
                          LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 80,
                      child: Text(
                        '₹${value.toStringAsFixed(0)}',
                        textAlign:
                            TextAlign.end,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}