import 'dart:convert';

import 'package:flutter/material.dart';

import 'history_service.dart';
import 'premium_page.dart';
import 'subscription_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() =>
      _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> historyData = [];
  List<Map<String, dynamic>> visibleHistoryData = [];

  bool isLoading = true;
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final history =
        await HistoryService.getHistory();

    final premiumStatus =
        await SubscriptionService.isPremium();

    final decodedHistory = history.map((item) {
      return Map<String, dynamic>.from(
        jsonDecode(item),
      );
    }).toList();

    final visibleHistory = premiumStatus
        ? decodedHistory
        : decodedHistory
            .take(
              SubscriptionService.freeHistoryLimit,
            )
            .toList();

    if (!mounted) return;

    setState(() {
      historyData = decodedHistory;
      visibleHistoryData = visibleHistory;
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  int getBestScore() {
    if (visibleHistoryData.isEmpty) {
      return 0;
    }

    return visibleHistoryData
        .map(
          (item) =>
              (item['score'] as num).toInt(),
        )
        .reduce(
          (a, b) => a > b ? a : b,
        );
  }

  String getBestStatus() {
    final bestScore = getBestScore();

    if (bestScore >= 80) {
      return 'Excellent';
    }

    if (bestScore >= 60) {
      return 'Good';
    }

    if (bestScore >= 40) {
      return 'Average';
    }

    return 'Weak';
  }

  Color getStatusColor(String status) {
    if (status == 'Excellent') {
      return Colors.green;
    }

    if (status == 'Good') {
      return Colors.orange;
    }

    if (status == 'Average') {
      return Colors.deepOrange;
    }

    return Colors.red;
  }

  Future<void> openPremiumPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PremiumPage(),
      ),
    );

    await loadHistory();
  }

  Future<void> deleteSingleHistory(
    Map<String, dynamic> item,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Report',
          ),
          content: const Text(
            'Are you sure you want to delete this report?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final actualIndex =
        historyData.indexOf(item);

    if (actualIndex == -1) return;

    await HistoryService.deleteHistory(
      actualIndex,
    );

    await loadHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Report deleted',
        ),
      ),
    );
  }

  Future<void> clearHistory() async {
    final shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear History',
          ),
          content: const Text(
            'Are you sure you want to delete all financial history?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    await HistoryService.clearHistory();

    await loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final hiddenReports =
        historyData.length -
            visibleHistoryData.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial History',
        ),
        centerTitle: true,
        actions: [
          if (historyData.isNotEmpty)
            IconButton(
              onPressed: clearHistory,
              icon: const Icon(
                Icons.delete_sweep_outlined,
              ),
              tooltip:
                  'Clear All History',
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : historyData.isEmpty
              ? const Center(
                  child: Text(
                    'No history available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadHistory,
                  child: ListView(
                    padding:
                        const EdgeInsets.all(16),
                    children: [
                      Card(
                        elevation: 8,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            20,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                size: 45,
                                color: Colors.amber,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              const Text(
                                'Best Financial Score',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              Text(
                                '${getBestScore()}/100',
                                style:
                                    const TextStyle(
                                  fontSize: 38,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                getBestStatus(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      getStatusColor(
                                    getBestStatus(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Previous Reports',
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

                      ...visibleHistoryData
                          .map((item) {
                        final date =
                            DateTime.parse(
                          item['date'].toString(),
                        );

                        final formattedDate =
                            '${date.day}/${date.month}/${date.year}';

                        final status =
                            item['status'].toString();

                        return Card(
                          elevation: 5,
                          margin:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '📅 $formattedDate',
                                        style:
                                            const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      onPressed: () {
                                        deleteSingleHistory(
                                          item,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons
                                            .delete_outline,
                                        color:
                                            Colors.red,
                                      ),
                                      tooltip:
                                          'Delete Report',
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  'Score : ${item['score']}/100',
                                  style:
                                      const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  'Status : $status',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        getStatusColor(
                                      status,
                                    ),
                                  ),
                                ),

                                const Divider(
                                  height: 25,
                                ),

                                Text(
                                  'Income : ₹${(item['income'] as num).toStringAsFixed(0)}',
                                ),

                                Text(
                                  'Expenses : ₹${(item['expenses'] as num).toStringAsFixed(0)}',
                                ),

                                Text(
                                  'Savings : ₹${(item['savings'] as num).toStringAsFixed(0)}',
                                ),

                                Text(
                                  'Investments : ₹${(item['investments'] as num).toStringAsFixed(0)}',
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      if (!isPremium &&
                          hiddenReports > 0)
                        Card(
                          elevation: 7,
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              20,
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 45,
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                Text(
                                  '$hiddenReports older report${hiddenReports == 1 ? '' : 's'} locked',
                                  style:
                                      const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                  textAlign:
                                      TextAlign.center,
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                const Text(
                                  'Free users can view the latest 5 financial reports. Upgrade to Premium to unlock complete financial history.',
                                  textAlign:
                                      TextAlign.center,
                                ),

                                const SizedBox(
                                  height: 18,
                                ),

                                ElevatedButton.icon(
                                  onPressed:
                                      openPremiumPage,
                                  icon: const Icon(
                                    Icons
                                        .workspace_premium,
                                  ),
                                  label: const Text(
                                    'Unlock Full History',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}