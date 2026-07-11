import 'package:flutter/material.dart';

import 'premium_page.dart';
import 'recommendation_service.dart';
import 'subscription_service.dart';

class RecommendationsPage extends StatefulWidget {
  final double income;
  final double expenses;
  final double savings;
  final double investments;
  final double emergencyFund;
  final double totalDebt;
  final bool hasHealthInsurance;
  final bool hasTermInsurance;

  const RecommendationsPage({
    super.key,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.investments,
    required this.emergencyFund,
    required this.totalDebt,
    required this.hasHealthInsurance,
    required this.hasTermInsurance,
  });

  @override
  State<RecommendationsPage> createState() =>
      _RecommendationsPageState();
}

class _RecommendationsPageState
    extends State<RecommendationsPage> {
  bool isLoading = true;
  bool isPremium = false;

  List<Map<String, dynamic>> recommendations = [];

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final premiumStatus =
        await SubscriptionService.isPremium();

    final generatedRecommendations =
        RecommendationService.generateRecommendations(
      income: widget.income,
      expenses: widget.expenses,
      savings: widget.savings,
      investments: widget.investments,
      emergencyFund: widget.emergencyFund,
      totalDebt: widget.totalDebt,
      hasHealthInsurance:
          widget.hasHealthInsurance,
      hasTermInsurance:
          widget.hasTermInsurance,
      isPremium: premiumStatus,
    );

    if (!mounted) return;

    setState(() {
      isPremium = premiumStatus;
      recommendations = generatedRecommendations;
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

    await loadRecommendations();
  }

  IconData getRecommendationIcon(
    String iconName,
  ) {
    switch (iconName) {
      case 'income':
        return Icons.account_balance_wallet;

      case 'expenses':
        return Icons.money_off;

      case 'savings':
        return Icons.savings;

      case 'investment':
        return Icons.trending_up;

      case 'emergency':
        return Icons.health_and_safety;

      case 'debt':
        return Icons.credit_card_off;

      case 'insurance':
        return Icons.shield_outlined;

      case 'premium':
        return Icons.auto_awesome;

      case 'success':
        return Icons.verified_outlined;

      default:
        return Icons.lightbulb_outline;
    }
  }

  Color getPriorityColor(
    String priority,
  ) {
    switch (priority) {
      case 'High':
        return Colors.red;

      case 'Medium':
        return Colors.orange;

      case 'Premium':
        return Colors.deepPurple;

      case 'Good':
        return Colors.green;

      default:
        return Colors.blueGrey;
    }
  }

  String getPriorityLabel(
    String priority,
  ) {
    switch (priority) {
      case 'High':
        return 'High Priority';

      case 'Medium':
        return 'Medium Priority';

      case 'Premium':
        return 'Premium Insight';

      case 'Good':
        return 'Good Progress';

      default:
        return priority;
    }
  }

  int getHighPriorityCount() {
    return recommendations.where((item) {
      return item['priority'] == 'High';
    }).length;
  }

  int getMediumPriorityCount() {
    return recommendations.where((item) {
      return item['priority'] == 'Medium';
    }).length;
  }

  Widget buildSummaryCard() {
    final highPriorityCount =
        getHighPriorityCount();

    final mediumPriorityCount =
        getMediumPriorityCount();

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 55,
            ),

            const SizedBox(height: 12),

            const Text(
              'Your Financial Action Plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Recommendations are generated from your current financial data.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: buildCountBox(
                    title: 'High',
                    count: highPriorityCount,
                    icon: Icons.priority_high,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildCountBox(
                    title: 'Medium',
                    count: mediumPriorityCount,
                    icon: Icons.schedule,
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildCountBox(
                    title: 'Total',
                    count: recommendations.length,
                    icon: Icons.checklist,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCountBox({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
          ),

          const SizedBox(height: 6),

          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecommendationCard(
    Map<String, dynamic> recommendation,
  ) {
    final priority =
        recommendation['priority']?.toString() ??
            '';

    final title =
        recommendation['title']?.toString() ??
            'Recommendation';

    final message =
        recommendation['message']?.toString() ??
            '';

    final iconName =
        recommendation['icon']?.toString() ??
            '';

    final priorityColor =
        getPriorityColor(priority);

    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Icon(
                    getRecommendationIcon(
                      iconName,
                    ),
                    color: priorityColor,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              priorityColor.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: Text(
                          getPriorityLabel(
                            priority,
                          ),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

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
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPremiumLockCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 50,
            ),

            const SizedBox(height: 14),

            const Text(
              'Advanced Recommendations Locked',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Upgrade to Premium for deeper insights based on your spending, savings, investments, emergency fund and debt position.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 18),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.analytics_outlined,
              ),
              title: Text(
                'Deeper Financial Analysis',
              ),
            ),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.route_outlined,
              ),
              title: Text(
                'Personalized Action Plan',
              ),
            ),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.trending_up,
              ),
              title: Text(
                'Wealth Growth Insights',
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
                  'Unlock Advanced Recommendations',
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
          'Smart Recommendations',
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
          : RefreshIndicator(
              onRefresh: loadRecommendations,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  buildSummaryCard(),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recommended Actions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      if (isPremium)
                        const Chip(
                          avatar: Icon(
                            Icons.workspace_premium,
                            size: 18,
                          ),
                          label: Text(
                            'Premium',
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  ...recommendations.map(
                    buildRecommendationCard,
                  ),

                  if (!isPremium) ...[
                    const SizedBox(height: 5),
                    buildPremiumLockCard(),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}