import 'package:flutter/material.dart';

import 'subscription_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() =>
      _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool isLoading = true;
  bool isPremium = false;
  int remainingFreeScans = 0;

  @override
  void initState() {
    super.initState();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final premium =
        await SubscriptionService.isPremium();

    final scans = await SubscriptionService
        .getRemainingFreeBillScans();

    if (!mounted) return;

    setState(() {
      isPremium = premium;
      remainingFreeScans = scans;
      isLoading = false;
    });
  }

  void showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Secure Premium payment is coming soon.',
        ),
      ),
    );
  }

  Widget buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildComparisonRow({
    required String feature,
    required String free,
    required String premium,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Health Premium',
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 70,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          isPremium
                              ? 'Premium Active'
                              : 'Unlock Your Full Financial Potential',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isPremium
                              ? 'You have access to all Premium features.'
                              : 'Get smarter automation, advanced insights and unlimited tracking.',
                          textAlign: TextAlign.center,
                        ),
                        if (!isPremium) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Text(
                              '$remainingFreeScans of 3 free bill scans remaining',
                              textAlign:
                                  TextAlign.center,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Premium Features',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                buildFeatureRow(
                  icon: Icons.document_scanner,
                  title: 'Smart Bill Scanner',
                  subtitle:
                      'Scan bills and receipts to extract the amount, detect the category and save the expense automatically.',
                ),

                buildFeatureRow(
                  icon: Icons.notifications_active,
                  title: 'Automatic EMI Reminders',
                  subtitle:
                      'Get reminders 3 days before, on the due date and when an EMI may be overdue.',
                ),

                buildFeatureRow(
                  icon: Icons.analytics,
                  title: 'Advanced Analytics',
                  subtitle:
                      'View long-term trends, comparisons and deeper financial insights.',
                ),

                buildFeatureRow(
                  icon: Icons.auto_awesome,
                  title: 'Smart Recommendations',
                  subtitle:
                      'Receive personalized recommendations based on your real financial data.',
                ),

                buildFeatureRow(
                  icon: Icons.picture_as_pdf,
                  title: 'PDF Financial Reports',
                  subtitle:
                      'Create, download and share detailed monthly financial health reports.',
                ),

                buildFeatureRow(
                  icon: Icons.all_inclusive,
                  title: 'Unlimited Tracking',
                  subtitle:
                      'Unlimited history, monthly records, financial goals and debt tracking.',
                ),

                buildFeatureRow(
                  icon: Icons.savings_outlined,
                  title: 'Advanced Financial Planning',
                  subtitle:
                      'Get advanced budget insights, goal reminders and emergency fund recommendations.',
                ),

                const SizedBox(height: 10),

                const Text(
                  'Free vs Premium',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Feature',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Free',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Premium',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 25),

                        buildComparisonRow(
                          feature: 'History',
                          free: '5',
                          premium: 'Unlimited',
                        ),
                        buildComparisonRow(
                          feature: 'Monthly Track',
                          free: '6 months',
                          premium: 'Unlimited',
                        ),
                        buildComparisonRow(
                          feature: 'Goals',
                          free: '3',
                          premium: 'Unlimited',
                        ),
                        buildComparisonRow(
                          feature: 'Loans',
                          free: '3',
                          premium: 'Unlimited',
                        ),
                        buildComparisonRow(
                          feature: 'Bill Scanner',
                          free: '3 scans',
                          premium: 'Unlimited',
                        ),
                        buildComparisonRow(
                          feature: 'Analytics',
                          free: 'Basic',
                          premium: 'Advanced',
                        ),
                        buildComparisonRow(
                          feature: 'EMI Alerts',
                          free: 'No',
                          premium: 'Yes',
                        ),
                        buildComparisonRow(
                          feature: 'PDF Reports',
                          free: 'No',
                          premium: 'Yes',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                if (!isPremium)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: showComingSoon,
                      icon: const Icon(
                        Icons.workspace_premium,
                      ),
                      label: const Padding(
                        padding:
                            EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        child: Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.verified,
                      ),
                      title: Text(
                        'Premium Membership Active',
                      ),
                      subtitle: Text(
                        'All Premium features are unlocked.',
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }
}