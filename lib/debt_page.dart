import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'debt_service.dart';
import 'notification_service.dart';
import 'premium_page.dart';
import 'subscription_service.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({super.key});

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  bool isLoading = true;
  bool isProcessing = false;

  List<Map<String, dynamic>> debts = [];
  bool isPremium = false;

  final Map<String, bool> _sectionVisible = {};

  @override
  void initState() {
    super.initState();
    initializeDebtPage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int index = 0; index < 15; index++) {
        Future.delayed(Duration(milliseconds: 100 + (index * 80)), () {
          if (!mounted) return;
          setState(() {
            _sectionVisible['section_$index'] = true;
          });
        });
      }
    });
  }

  Future<void> initializeDebtPage() async {
    await loadDebts();
    isPremium = await SubscriptionService.isPremium();
    if (!mounted) return;
    setState(() {});
    await NotificationService.requestPermission();
  }

  Future<void> loadDebts() async {
    final savedDebts = await DebtService.getDebts();
    if (!mounted) return;
    setState(() {
      debts = savedDebts;
      isLoading = false;
    });
  }

  double getDouble(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int getInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? getDate(Map<String, dynamic> data, String key) {
    return DateTime.tryParse(data[key]?.toString() ?? '');
  }

  List<Map<String, dynamic>> getPaymentHistory(Map<String, dynamic> debt) {
    final rawHistory = debt['paymentHistory'];
    if (rawHistory is! List) return [];
    return rawHistory
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Not Available';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double get totalOriginalDebt {
    return debts.fold<double>(0, (total, debt) => total + getDouble(debt, 'totalAmount'));
  }

  double get totalRemainingDebt {
    return debts.fold<double>(0, (total, debt) => total + getDouble(debt, 'remainingBalance'));
  }

  double get totalMonthlyEmi {
    return debts
        .where((debt) => getDouble(debt, 'remainingBalance') > 0)
        .fold<double>(0, (total, debt) => total + getDouble(debt, 'monthlyEmi'));
  }

  double get totalRepaid => totalOriginalDebt - totalRemainingDebt;

  double get overallProgress {
    if (totalOriginalDebt <= 0) return 0;
    return (totalRepaid / totalOriginalDebt).clamp(0.0, 1.0);
  }

  int get totalRemainingEmis {
    return debts.fold<int>(0, (total, debt) => total + getInt(debt, 'remainingEmis'));
  }

  Widget _buildAnimatedSection({required Widget child, required int index}) {
    final visible = _sectionVisible['section_$index'] ?? false;
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildPremiumAppBar(),
      floatingActionButton: _buildPremiumFAB(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDebts,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: debts.isEmpty ? _buildEmptyState() : _buildDebtList(),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      toolbarHeight: 90,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debt Tracker',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage loans with confidence',
            style: TextStyle(
              color: AppTheme.subtitle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: AppTheme.primary, size: 22),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)]),
              boxShadow: [
                BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: const Center(
              child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumFAB() {
    return FloatingActionButton.extended(
      onPressed: () => tryOpenDebtForm(),
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
      label: const Text('Add Debt', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        _buildAnimatedSection(
          index: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))
              ],
            ),
            child: const Icon(Icons.account_balance_outlined, size: 100, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 40),
        _buildAnimatedSection(
          index: 1,
          child: const Text(
            'No debts added yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.text),
          ),
        ),
        const SizedBox(height: 12),
        _buildAnimatedSection(
          index: 2,
          child: const Text(
            'Track your EMIs and loan repayments in one premium dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.subtitle, height: 1.5),
          ),
        ),
        const SizedBox(height: 40),
        _buildAnimatedSection(
          index: 3,
          child: ElevatedButton(
            onPressed: () => tryOpenDebtForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
            ),
            child: const Text('Add Your First Debt', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
          _buildAnimatedSection(index: 0, child: _buildSummaryCard()),
        const SizedBox(height: 24),
        _buildAnimatedSection(index: 1, child: _buildQuickActions()),
        const SizedBox(height: 24),
        _buildAnimatedSection(index: 2, child: _buildInsightCard()),
        const SizedBox(height: 24),
        _buildAnimatedSection(
          index: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Loans (${debts.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
              TextButton(onPressed: loadDebts, child: const Text('Refresh')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...debts.asMap().entries.map((entry) {
          return _buildAnimatedSection(
            index: entry.key + 4,
            child: buildDebtCard(entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF081B3A), Color(0xFF1E4ACB), Color(0xFF5A8EFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.28), blurRadius: 32, offset: const Offset(0, 18)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24, top: -24,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                left: -28, bottom: -28,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Debt', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('₹${totalOriginalDebt.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 76,
                              height: 76,
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(begin: 0, end: overallProgress),
                                builder: (context, value, child) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 7,
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
                                    strokeCap: StrokeCap.round,
                                  );
                                },
                              ),
                            ),
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.16),
                              ),
                              child: Center(
                                child: Text('${(overallProgress * 100).toInt()}%',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildSummaryStat('Remaining', '₹${totalRemainingDebt.toStringAsFixed(0)}')),
                          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.15)),
                          Expanded(child: _buildSummaryStat('Monthly EMI', '₹${totalMonthlyEmi.toStringAsFixed(0)}')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => tryOpenDebtForm(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_circle_rounded, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(height: 8),
                    const Text('Add Debt',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.text)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () {
                if (debts.isNotEmpty) markEmiPaid(debts.first);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payments_rounded, color: AppTheme.success, size: 24),
                    ),
                    const SizedBox(height: 8),
                    const Text('Record EMI',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.text)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    String message = "Keep tracking your EMIs to stay debt-free.";
    if (debts.isNotEmpty) {
      if (overallProgress >= 1.0) {
        message = "Congratulations! You are completely debt-free.";
      } else if (overallProgress >= 0.5) {
        message = "You have repaid ${(overallProgress * 100).toStringAsFixed(0)}% of your total debt. Great job!";
      } else {
        message = "Consistent payments will help you clear your debts faster.";
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppTheme.text, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDebtCard(Map<String, dynamic> debt) {
    final totalAmount = getDouble(debt, 'totalAmount');
    final remainingBalance = getDouble(debt, 'remainingBalance');
    final monthlyEmi = getDouble(debt, 'monthlyEmi');
    final interestRate = getDouble(debt, 'interestRate');
    final totalEmis = getInt(debt, 'totalEmis');
    final paidEmis = getInt(debt, 'paidEmis');
    final remainingEmis = getInt(debt, 'remainingEmis');
    final nextDueDate = getDate(debt, 'nextDueDate');
    final repaid = totalAmount - remainingBalance;
    final progress = totalAmount > 0 ? (repaid / totalAmount).clamp(0.0, 1.0) : 0.0;
    final status = getDueStatus(debt);
    final statusColor = getDueStatusColor(status);
    final isCompleted = remainingBalance <= 0 || remainingEmis <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(isCompleted ? Icons.verified_rounded : Icons.account_balance_rounded,
                      color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt['loanName'].toString(),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.text)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                            child: Text(status,
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          Text('${interestRate.toStringAsFixed(1)}% Interest',
                              style: const TextStyle(fontSize: 11, color: AppTheme.subtitle)),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) {
                    if (value == 'edit') tryOpenDebtForm(existingDebt: debt);
                    if (value == 'history') showPaymentHistory(debt);
                    if (value == 'delete') deleteDebt(debt);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit Loan')])),
                    const PopupMenuItem(
                        value: 'history',
                        child: Row(children: [
                          Icon(Icons.history_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Payment History')
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Loan', style: TextStyle(color: Colors.red))
                        ])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${repaid.toStringAsFixed(0)} repaid',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.text)),
                    Text('₹${remainingBalance.toStringAsFixed(0)} left',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.subtitle)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDebtDetail('Original', '₹${totalAmount.toStringAsFixed(0)}'),
                    _buildDebtDetail('Monthly EMI', '₹${monthlyEmi.toStringAsFixed(0)}'),
                    _buildDebtDetail('Due Date', isCompleted ? 'Paid' : formatDate(nextDueDate)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildDebtDetail('Total EMIs', '$totalEmis'),
                    _buildDebtDetail('Paid', '$paidEmis'),
                    _buildDebtDetail('Remaining', '$remainingEmis'),
                  ],
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : () => markEmiPaid(debt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Pay EMI ₹${monthlyEmi.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.subtitle, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.text),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Future<void> showPremiumDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Premium Feature')),
            ],
          ),
          content: const Text('Free plan supports up to 3 loans. Upgrade to Premium to track unlimited loans.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage()));
                isPremium = await SubscriptionService.isPremium();
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upgrade'),
            ),
          ],
        );
      },
    );
  }

  Future<void> tryOpenDebtForm({Map<String, dynamic>? existingDebt}) async {
    if (existingDebt != null) {
      await openDebtForm(existingDebt: existingDebt);
      return;
    }
    final canAddDebt = await SubscriptionService.canAddDebt(debts.length);
    if (!mounted) return;
    if (!canAddDebt) {
      await showPremiumDialog();
      return;
    }
    await openDebtForm();
  }

  Future<void> openDebtForm({Map<String, dynamic>? existingDebt}) async {
    final loanNameController = TextEditingController(text: existingDebt?['loanName']?.toString() ?? '');
    final totalAmountController = TextEditingController(
        text: existingDebt == null ? '' : getDouble(existingDebt, 'totalAmount').toStringAsFixed(0));
    final remainingBalanceController = TextEditingController(
        text: existingDebt == null ? '' : getDouble(existingDebt, 'remainingBalance').toStringAsFixed(0));
    final monthlyEmiController = TextEditingController(
        text: existingDebt == null ? '' : getDouble(existingDebt, 'monthlyEmi').toStringAsFixed(0));
    final interestRateController = TextEditingController(
        text: existingDebt == null ? '' : getDouble(existingDebt, 'interestRate').toString());
    final totalEmisController =
        TextEditingController(text: existingDebt == null ? '' : getInt(existingDebt, 'totalEmis').toString());
    final paidEmisController =
        TextEditingController(text: existingDebt == null ? '0' : getInt(existingDebt, 'paidEmis').toString());

    DateTime loanStartDate = getDate(existingDebt ?? {}, 'loanStartDate') ?? DateTime.now();
    DateTime nextDueDate = getDate(existingDebt ?? {}, 'nextDueDate') ?? DateTime.now().add(const Duration(days: 30));

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectLoanStartDate() async {
              final selectedDate = await showDatePicker(
                  context: dialogContext, initialDate: loanStartDate, firstDate: DateTime(1950), lastDate: DateTime(2100));
              if (selectedDate != null) setDialogState(() => loanStartDate = selectedDate);
            }

            Future<void> selectNextDueDate() async {
              final selectedDate = await showDatePicker(
                  context: dialogContext, initialDate: nextDueDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (selectedDate != null) setDialogState(() => nextDueDate = selectedDate);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Text(existingDebt == null ? 'Add Smart Loan' : 'Edit Loan',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPremiumTextField(
                          controller: loanNameController, label: 'Loan Name', icon: Icons.account_balance),
                      const SizedBox(height: 16),
                      _buildPremiumTextField(
                          controller: totalAmountController, label: 'Total Loan Amount', icon: Icons.currency_rupee, isNumber: true),
                      const SizedBox(height: 16),
                      _buildPremiumTextField(
                          controller: remainingBalanceController, label: 'Remaining Balance', icon: Icons.account_balance_wallet_outlined, isNumber: true),
                      const SizedBox(height: 16),
                      _buildPremiumTextField(
                          controller: monthlyEmiController, label: 'Monthly EMI', icon: Icons.calendar_month, isNumber: true),
                      const SizedBox(height: 16),
                      _buildPremiumTextField(
                          controller: interestRateController, label: 'Interest Rate', icon: Icons.percent, isDecimal: true),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildPremiumTextField(
                                  controller: totalEmisController, label: 'Total EMIs', icon: Icons.format_list_numbered, isNumber: true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildPremiumTextField(
                                  controller: paidEmisController, label: 'Paid EMIs', icon: Icons.check_circle_outline, isNumber: true)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDatePickerTile(label: 'Loan Start Date', date: loanStartDate, onTap: selectLoanStartDate),
                      const SizedBox(height: 12),
                      _buildDatePickerTile(label: 'Next EMI Due Date', date: nextDueDate, onTap: selectNextDueDate),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final loanName = loanNameController.text.trim();
                    final totalAmount = double.tryParse(totalAmountController.text) ?? 0;
                    final remainingBalance = double.tryParse(remainingBalanceController.text) ?? 0;
                    final monthlyEmi = double.tryParse(monthlyEmiController.text) ?? 0;
                    final interestRate = double.tryParse(interestRateController.text) ?? 0;
                    final totalEmis = int.tryParse(totalEmisController.text) ?? 0;
                    final paidEmis = int.tryParse(paidEmisController.text) ?? 0;

                    if (loanName.isEmpty || totalAmount <= 0 || remainingBalance < 0 || monthlyEmi <= 0 || totalEmis <= 0 || paidEmis < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid loan details')));
                      return;
                    }
                    if (remainingBalance > totalAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remaining balance cannot exceed total loan amount')));
                      return;
                    }
                    if (paidEmis > totalEmis) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paid EMIs cannot exceed total EMIs')));
                      return;
                    }
                    final remainingEmis = totalEmis - paidEmis;
                    if (remainingEmis > 0 && remainingBalance <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remaining balance must be greater than ₹0 when EMIs are still remaining')));
                      return;
                    }
                    if (paidEmis == totalEmis && remainingBalance != 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remaining balance must be ₹0 when all EMIs are paid')));
                      return;
                    }

                    if (existingDebt == null) {
                      await DebtService.saveDebt(
                        loanName: loanName, totalAmount: totalAmount, remainingBalance: remainingBalance,
                        monthlyEmi: monthlyEmi, interestRate: interestRate, totalEmis: totalEmis,
                        paidEmis: paidEmis, loanStartDate: loanStartDate, nextDueDate: nextDueDate,
                      );
                    } else {
                      await DebtService.updateDebt(
                        id: existingDebt['id'].toString(), loanName: loanName, totalAmount: totalAmount,
                        remainingBalance: remainingBalance, monthlyEmi: monthlyEmi, interestRate: interestRate,
                        totalEmis: totalEmis, paidEmis: paidEmis, loanStartDate: loanStartDate, nextDueDate: nextDueDate,
                      );
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(existingDebt == null ? 'Add Loan' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    loanNameController.dispose();
    totalAmountController.dispose();
    remainingBalanceController.dispose();
    monthlyEmiController.dispose();
    interestRateController.dispose();
    totalEmisController.dispose();
    paidEmisController.dispose();

    if (saved == true) await loadDebts();
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller, required String label, required IconData icon,
    bool isNumber = false, bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.text)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : (isNumber ? TextInputType.number : TextInputType.text),
          inputFormatters: isDecimal 
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
              : (isNumber ? [FilteringTextInputFormatter.digitsOnly] : []),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerTile({required String label, required DateTime date, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.subtitle)),
      subtitle: Text(formatDate(date), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.text)),
      trailing: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
      onTap: onTap,
    );
  }

  String getDueStatus(Map<String, dynamic> debt) {
    final remainingBalance = getDouble(debt, 'remainingBalance');
    final remainingEmis = getInt(debt, 'remainingEmis');
    if (remainingBalance <= 0 || remainingEmis <= 0) return 'Paid';
    final nextDueDate = getDate(debt, 'nextDueDate');
    if (nextDueDate == null) return 'Upcoming';
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    final difference = dueDate.difference(currentDate).inDays;
    if (difference < 0) return 'Overdue';
    if (difference <= 3) return 'Due Soon';
    return 'Upcoming';
  }

  Color getDueStatusColor(String status) {
    switch (status) {
      case 'Paid': return AppTheme.success;
      case 'Overdue': return AppTheme.danger;
      case 'Due Soon': return Colors.orange;
      default: return AppTheme.primary;
    }
  }

  Future<void> markEmiPaid(Map<String, dynamic> debt) async {
    final monthlyEmi = getDouble(debt, 'monthlyEmi');
    final shouldPay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: Text('Mark EMI of ₹${monthlyEmi.toStringAsFixed(0)} for ${debt['loanName']} as paid?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Mark as Paid'),
            ),
          ],
        );
      },
    );
    if (shouldPay != true) return;
    setState(() => isProcessing = true);
    await DebtService.markEmiAsPaid(id: debt['id'].toString());
    await loadDebts();
    if (!mounted) return;
    setState(() => isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('EMI marked as paid successfully')));
  }

  Future<void> undoLastPayment(Map<String, dynamic> debt) async {
    final shouldUndo = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.undo_rounded, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Undo Last Payment', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text('This will restore the last EMI payment and remaining balance.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Undo'),
            ),
          ],
        );
      },
    );
    if (shouldUndo != true) return;
    await DebtService.undoLastEmiPayment(id: debt['id'].toString());
    await loadDebts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Last EMI payment restored')));
  }

  void showPaymentHistory(Map<String, dynamic> debt) {
    final history = getPaymentHistory(debt);
    showModalBottomSheet(
      context: context, isScrollControlled: true, showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('${debt['loanName']} History', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.text)),
                  const SizedBox(height: 20),
                  if (history.isEmpty)
                    const Expanded(child: Center(child: Text('No EMI payments recorded yet')))
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 24),
                        itemBuilder: (context, index) {
                          final payment = history[index];
                          final amount = getDouble(payment, 'amount');
                          final paidDate = getDate(payment, 'paidDate');
                          final emiNumber = getInt(payment, 'emiNumber');
                          return Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.check, color: AppTheme.success, size: 18),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('EMI #$emiNumber - ₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text)),
                                    const SizedBox(height: 4),
                                    Text('Paid on ${formatDate(paidDate)}', style: const TextStyle(fontSize: 12, color: AppTheme.subtitle)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  if (history.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () { Navigator.pop(sheetContext); undoLastPayment(debt); },
                        icon: const Icon(Icons.undo_rounded), label: const Text('Undo Last Payment'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteDebt(Map<String, dynamic> debt) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Delete Loan', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: Text('Delete ${debt['loanName']} and its payment history? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ],
        );
      },
    );
    if (shouldDelete != true) return;
    await DebtService.deleteDebt(debt['id'].toString());
    await loadDebts();
  }
}