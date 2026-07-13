import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'emergency_fund_service.dart';
import 'goal_service.dart';
import 'wallet_service.dart';

class SavingsWalletPage extends StatefulWidget {
  const SavingsWalletPage({super.key});

  @override
  State<SavingsWalletPage> createState() => _SavingsWalletPageState();
}

class _SavingsWalletPageState extends State<SavingsWalletPage> {
  bool isLoading = true;

  double walletBalance = 0;
  double totalAdded = 0;
  double totalAllocated = 0;

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> goals = [];

  Map<String, dynamic>? emergencyFund;

  final Map<String, bool> _sectionVisible = {};

  @override
  void initState() {
    super.initState();
    loadWallet();

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

  Future<void> loadWallet() async {
    final savedTransactions = await WalletService.getTransactions();
    final balance = await WalletService.getWalletBalance();
    final added = await WalletService.getTotalAddedMoney();
    final allocated = await WalletService.getTotalAllocatedMoney();
    final savedGoals = await GoalService.getGoals();
    final savedEmergencyFund = await EmergencyFundService.getEmergencyFund();

    if (!mounted) return;

    setState(() {
      transactions = savedTransactions;
      walletBalance = balance;
      totalAdded = added;
      totalAllocated = allocated;
      goals = savedGoals;
      emergencyFund = savedEmergencyFund;
      isLoading = false;
    });
  }

  double getDoubleValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int getIntValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> get incompleteGoals {
    return goals.where((goal) {
      final double targetAmount = getDoubleValue(goal, 'targetAmount');
      final double savedAmount = getDoubleValue(goal, 'savedAmount');
      return targetAmount > 0 && savedAmount < targetAmount;
    }).toList();
  }

  double get emergencyFundTarget {
    if (emergencyFund == null) return 0;
    final double monthlyExpenses = getDoubleValue(emergencyFund!, 'monthlyEssentialExpenses');
    final int targetMonths = getIntValue(emergencyFund!, 'targetMonths');
    return monthlyExpenses * targetMonths;
  }

  double get emergencyFundCurrent {
    if (emergencyFund == null) return 0;
    return getDoubleValue(emergencyFund!, 'currentFund');
  }

  double get emergencyFundRemaining {
    final double remaining = emergencyFundTarget - emergencyFundCurrent;
    return remaining > 0 ? remaining : 0;
  }

  bool get hasIncompleteEmergencyFund {
    return emergencyFund != null && emergencyFundTarget > 0 && emergencyFundCurrent < emergencyFundTarget;
  }

  // Design Helpers
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
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadWallet,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildAnimatedSection(index: 0, child: _buildBalanceCard()),
                      const SizedBox(height: 24),
                      _buildAnimatedSection(index: 1, child: _buildQuickActions()),
                      const SizedBox(height: 24),
                      _buildAnimatedSection(index: 2, child: _buildInsightsCard()),
                      const SizedBox(height: 24),
                      _buildAnimatedSection(index: 3, child: _buildSectionTitle('Wallet Stats')),
                      const SizedBox(height: 12),
                      _buildAnimatedSection(index: 4, child: _buildStatsGrid()),
                      const SizedBox(height: 24),
                      _buildAnimatedSection(index: 5, child: _buildSectionTitle('Transaction History')),
                      const SizedBox(height: 12),
                      if (transactions.isEmpty)
                        _buildAnimatedSection(index: 6, child: _buildEmptyState())
                      else
                        ...transactions.asMap().entries.map((entry) {
                          return _buildAnimatedSection(
                            index: entry.key + 6,
                            child: buildTransactionCard(entry.value),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      toolbarHeight: 90,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Savings Wallet',
              style: TextStyle(color: AppTheme.text, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Grow your savings every day',
              style: TextStyle(color: AppTheme.subtitle, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: const Icon(Icons.notifications_none_rounded, color: AppTheme.primary, size: 22),
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
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Center(child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('₹${walletBalance.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniBalanceStat('Added', '₹${totalAdded.toStringAsFixed(0)}', Icons.arrow_downward_rounded, Colors.greenAccent),
                Container(width: 1, height: 24, color: Colors.white.withOpacity(0.1)),
                _buildMiniBalanceStat('Allocated', '₹${totalAllocated.toStringAsFixed(0)}', Icons.arrow_upward_rounded, Colors.orangeAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBalanceStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Add Money',
            icon: Icons.add_rounded,
            color: AppTheme.primary,
            onTap: showAddMoneyDialog,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'Allocate',
            icon: Icons.north_east_rounded,
            color: const Color(0xFFF59E0B),
            onTap: showAllocateMoneyDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    String message = "Start adding money to see your savings insights grow.";
    if (totalAdded > 0) {
      if (totalAllocated >= totalAdded * 0.8) {
        message = "Excellent! You have allocated 80% of your savings to goals.";
      } else {
        message = "You have ₹${walletBalance.toStringAsFixed(0)} available to allocate to your goals.";
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
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.primary, size: 22),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text));
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatTile('Total Deposits', totalAdded, Icons.south_west_rounded, Colors.green),
        _buildStatTile('Withdrawals', totalAllocated, Icons.north_east_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatTile(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppTheme.subtitle, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text('₹${value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No wallet transactions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
          const SizedBox(height: 8),
          const Text('Your deposits and goal allocations will appear here.',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.subtitle, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: showAddMoneyDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Add First Deposit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionCard(Map<String, dynamic> transaction) {
    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final bool isCredit = transaction['type'] == 'credit';
    final color = getTransactionColor(transaction);
    final icon = getTransactionIcon(transaction);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(getTransactionTitle(transaction),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.text)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(getTransactionSubtitle(transaction),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.subtitle)),
            const SizedBox(height: 2),
            Text(formatDate(transaction['createdAt']?.toString()),
                style: TextStyle(fontSize: 11, color: AppTheme.subtitle.withOpacity(0.7))),
          ],
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }

  // Dialogs Redesign
  Future<void> showAddMoneyDialog() async {
    final amountController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter amount to add to your savings wallet.', style: TextStyle(color: AppTheme.subtitle)),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.primary),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final double amount = double.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0) return;
                await WalletService.addMoney(amount: amount, paymentMethod: 'Manual Test');
                Navigator.pop(dialogContext);
                await loadWallet();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added successfully')));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Add Money'),
            ),
          ],
        );
      },
    );
    amountController.dispose();
  }

  Future<void> showAllocateMoneyDialog() async {
    if (walletBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add money before allocating')));
      return;
    }
    String selectedDestination = 'General Savings';
    Map<String, dynamic>? selectedGoal;
    final amountController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final double? goalTarget = selectedGoal == null ? null : getDoubleValue(selectedGoal!, 'targetAmount');
          final double? goalSaved = selectedGoal == null ? null : getDoubleValue(selectedGoal!, 'savedAmount');
          final double? goalRemaining = (goalTarget != null && goalSaved != null) ? goalTarget - goalSaved : null;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text('Allocate Money', style: TextStyle(fontWeight: FontWeight.w800)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Balance: ₹${walletBalance.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedDestination,
                    decoration: InputDecoration(
                        labelText: 'Allocate To',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    items: const [
                      DropdownMenuItem(value: 'General Savings', child: Text('General Savings')),
                      DropdownMenuItem(value: 'Financial Goal', child: Text('Financial Goal')),
                      DropdownMenuItem(value: 'Emergency Fund', child: Text('Emergency Fund')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedDestination = value;
                        selectedGoal = null;
                        amountController.clear();
                      });
                    },
                  ),
                  if (selectedDestination == 'Financial Goal') ...[
                    const SizedBox(height: 16),
                    if (incompleteGoals.isEmpty)
                      const Text('No active goals available', style: TextStyle(color: AppTheme.subtitle))
                    else
                      DropdownButtonFormField<String>(
                        value: selectedGoal?['id']?.toString(),
                        decoration: InputDecoration(
                            labelText: 'Select Goal',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                        items: incompleteGoals.map((goal) {
                          final double remaining = getDoubleValue(goal, 'targetAmount') - getDoubleValue(goal, 'savedAmount');
                          return DropdownMenuItem<String>(value: goal['id'].toString(), child: Text('${goal['goalName']} (₹${remaining.toStringAsFixed(0)})'));
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedGoal = incompleteGoals.firstWhere((goal) => goal['id'].toString() == value);
                          });
                        },
                      ),
                  ],
                  if (selectedDestination == 'Emergency Fund' && emergencyFund != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Text('Emergency Fund Target', style: TextStyle(fontSize: 11, color: AppTheme.subtitle, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('₹${emergencyFundRemaining.toStringAsFixed(0)} left', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final double amount = double.tryParse(amountController.text.trim()) ?? 0;
                  if (amount <= 0 || amount > walletBalance) return;
                  if (selectedDestination == 'Financial Goal' && selectedGoal == null) return;

                  String destinationName = selectedDestination;
                  if (selectedDestination == 'Financial Goal') {
                    final double remaining = getDoubleValue(selectedGoal!, 'targetAmount') - getDoubleValue(selectedGoal!, 'savedAmount');
                    if (amount > remaining) return;
                    destinationName = selectedGoal!['goalName'].toString();
                    await WalletService.allocateToGoalSafely(amount: amount, goalId: selectedGoal!['id'].toString());
                  } else if (selectedDestination == 'Emergency Fund') {
                    if (amount > emergencyFundRemaining) return;
                    await WalletService.allocateToEmergencyFundSafely(amount: amount);
                  } else {
                    await WalletService.allocateMoney(amount: amount, destination: 'General Savings');
                  }

                  Navigator.pop(dialogContext);
                  await loadWallet();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('₹${amount.toStringAsFixed(0)} allocated to $destinationName')));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Allocate'),
              ),
            ],
          );
        });
      },
    );
    amountController.dispose();
  }

  // Helper methods
  String formatDate(String? dateText) {
    final date = DateTime.tryParse(dateText ?? '');
    if (date == null) return '';
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }

  IconData getTransactionIcon(Map<String, dynamic> transaction) {
    if (transaction['type'] == 'credit') return Icons.add_circle_outline_rounded;
    final destination = transaction['destination']?.toString();
    if (destination == 'General Savings') return Icons.savings_rounded;
    if (destination == 'Emergency Fund') return Icons.shield_rounded;
    return Icons.flag_rounded;
  }

  Color getTransactionColor(Map<String, dynamic> transaction) {
    return transaction['type'] == 'credit' ? AppTheme.success : const Color(0xFFF59E0B);
  }

  String getTransactionTitle(Map<String, dynamic> transaction) {
    return transaction['type'] == 'credit' ? 'Money Added' : 'Money Allocated';
  }

  String getTransactionSubtitle(Map<String, dynamic> transaction) {
    if (transaction['type'] == 'credit') return transaction['paymentMethod']?.toString() ?? 'Wallet';
    return transaction['destination']?.toString() ?? 'Allocation';
  }
}