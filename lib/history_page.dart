import 'dart:convert';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'history_service.dart';
import 'premium_page.dart';
import 'subscription_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() =>
      _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> historyData = [];
  List<Map<String, dynamic>> visibleHistoryData = [];

  bool isLoading = true;
  bool isPremium = false;
  String searchQuery = '';
  String selectedFilter = 'All';

  late final AnimationController _badgeController;

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    loadHistory();
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> get _filteredHistoryData {
    final query = searchQuery.toLowerCase().trim();

    return visibleHistoryData.where((item) {
      final status = item['status'].toString();
      final matchesFilter = selectedFilter == 'All' || status == selectedFilter;
      final matchesQuery = query.isEmpty ||
          status.toLowerCase().contains(query) ||
          item['score'].toString().contains(query) ||
          DateTime.parse(item['date'].toString()).toString().toLowerCase().contains(query);

      return matchesFilter && matchesQuery;
    }).toList();
  }

  Future<void> _showReportDetails(BuildContext context, Map<String, dynamic> item) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Financial Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: ${item['score']}/100', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Status: ${item['status']}'),
              const SizedBox(height: 8),
              Text('Income: ₹${(item['income'] as num).toStringAsFixed(0)}'),
              Text('Expenses: ₹${(item['expenses'] as num).toStringAsFixed(0)}'),
              Text('Savings: ₹${(item['savings'] as num).toStringAsFixed(0)}'),
              Text('Investments: ₹${(item['investments'] as num).toStringAsFixed(0)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hiddenReports = historyData.length - visibleHistoryData.length;
    final filteredHistoryData = _filteredHistoryData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 84,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assessment History', style: TextStyle(color: AppTheme.text, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Your financial journey', style: TextStyle(color: AppTheme.subtitle, fontSize: 13)),
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
          : historyData.isEmpty
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
                            child: const Icon(Icons.history_edu_rounded, size: 64, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 20),
                          const Text('No history available', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.text)),
                          const SizedBox(height: 8),
                          const Text('Complete an assessment to build your financial history.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.subtitle, height: 1.4)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: loadHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh History'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadHistory,
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
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF111827)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 22, offset: const Offset(0, 10))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                                            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Best financial score', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                                                const SizedBox(height: 4),
                                                Text('${getBestScore()}/100', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Status', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                                  const SizedBox(height: 2),
                                                  Text(getBestStatus(), style: TextStyle(color: getStatusColor(getBestStatus()), fontWeight: FontWeight.w800, fontSize: 15)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Reports', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                                  const SizedBox(height: 2),
                                                  Text('${visibleHistoryData.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          searchQuery = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Search assessments',
                                        hintStyle: const TextStyle(color: AppTheme.subtitle),
                                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 40,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: ['All', 'Excellent', 'Good', 'Average', 'Weak']
                                            .map((filter) => Padding(
                                                  padding: const EdgeInsets.only(right: 8),
                                                  child: _buildFilterChip(filter),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _buildStatCard('Total Assessments', visibleHistoryData.length.toDouble(), Icons.analytics_outlined)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildStatCard('Highest Score', getBestScore().toDouble(), Icons.trending_up_rounded)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _buildStatCard('Average Score', _averageScore().toDouble(), Icons.bar_chart_rounded)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildStatCard('Lowest Score', _lowestScore().toDouble(), Icons.trending_down_rounded)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('Previous reports', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
                                  ),
                                  if (historyData.isNotEmpty)
                                    IconButton(
                                      onPressed: clearHistory,
                                      tooltip: 'Clear All History',
                                      icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.danger),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (filteredHistoryData.isEmpty)
                                _buildAnimatedSection(
                                  index: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
                                    ),
                                    child: const Text('No assessments match your search.', style: TextStyle(color: AppTheme.subtitle, fontWeight: FontWeight.w600)),
                                  ),
                                )
                              else
                                ...filteredHistoryData.map((item) {
                                final date = DateTime.parse(item['date'].toString());
                                final formattedDate = '${date.day}/${date.month}/${date.year}';
                                final status = item['status'].toString();

                                return _buildAnimatedSection(
                                  index: 1,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
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
                                            _buildScoreBadge((item['score'] as num).toInt()),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(formattedDate, style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700, fontSize: 13)),
                                            ),
                                            IconButton(
                                              onPressed: () => deleteSingleHistory(item),
                                              tooltip: 'Delete Report',
                                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(color: getStatusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                                          child: Text(status, style: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.w700, fontSize: 11)),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(child: _buildDetailChip('Income', (item['income'] as num).toStringAsFixed(0))),
                                            const SizedBox(width: 8),
                                            Expanded(child: _buildDetailChip('Expenses', (item['expenses'] as num).toStringAsFixed(0))),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(child: _buildDetailChip('Savings', (item['savings'] as num).toStringAsFixed(0))),
                                            const SizedBox(width: 8),
                                            Expanded(child: _buildDetailChip('Investments', (item['investments'] as num).toStringAsFixed(0))),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextButton.icon(
                                            onPressed: () => _showReportDetails(context, item),
                                            icon: const Icon(Icons.visibility_rounded, size: 18),
                                            label: const Text('View Report →'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.primary,
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (!isPremium && hiddenReports > 0)
                                _buildAnimatedSection(
                                  index: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFF8FAFC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.lock_outline_rounded, size: 36, color: AppTheme.primary),
                                        const SizedBox(height: 10),
                                        Text('$hiddenReports older report${hiddenReports == 1 ? '' : 's'} locked', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.text), textAlign: TextAlign.center),
                                        const SizedBox(height: 8),
                                        const Text('Free users can view the latest 5 financial reports. Upgrade to Premium to unlock complete financial history.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.subtitle, height: 1.4)),
                                        const SizedBox(height: 14),
                                        ElevatedButton.icon(
                                          onPressed: openPremiumPage,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          icon: const Icon(Icons.workspace_premium_rounded),
                                          label: const Text('Unlock Full History'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 550 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: childWidget),
        );
      },
      child: child,
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [AppTheme.primary, Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.text,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    return AnimatedBuilder(
      animation: _badgeController,
      builder: (context, child) {
        final start = Color.lerp(AppTheme.primary, const Color(0xFF38BDF8), _badgeController.value)!;
        final end = Color.lerp(const Color(0xFF2563EB), const Color(0xFF7C3AED), _badgeController.value)!;

        return Transform.scale(
          scale: 1.0 + (0.02 * _badgeController.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [start, end], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [BoxShadow(color: start.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Text('$score/100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, double value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  title.contains('Highest') ? const Color(0xFF7C3AED) : const Color(0xFF38BDF8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: AppTheme.subtitle, fontSize: 11.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Text(animatedValue.toStringAsFixed(0), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.subtitle, fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('₹$value', style: const TextStyle(color: AppTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  double _averageScore() {
    if (visibleHistoryData.isEmpty) return 0;
    final total = visibleHistoryData.fold<int>(0, (sum, item) => sum + (item['score'] as num).toInt());
    return total / visibleHistoryData.length;
  }

  double _lowestScore() {
    if (visibleHistoryData.isEmpty) return 0;
    return visibleHistoryData.map((item) => (item['score'] as num).toInt()).reduce((a, b) => a < b ? a : b).toDouble();
  }
}