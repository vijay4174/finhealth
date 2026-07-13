import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'emergency_fund_service.dart';

class EmergencyFundPage extends StatefulWidget {
  const EmergencyFundPage({super.key});

  @override
  State<EmergencyFundPage> createState() => _EmergencyFundPageState();
}

class _EmergencyFundPageState extends State<EmergencyFundPage> {
  final TextEditingController expensesController = TextEditingController();
  final TextEditingController currentFundController = TextEditingController();

  bool isLoading = true;
  bool hasSavedFund = false;
  bool isSaving = false;

  int selectedTargetMonths = 6;

  final List<int> targetMonths = [
    3,
    6,
    9,
    12,
  ];

  final Map<String, bool> _sectionVisible = {};

  @override
  void initState() {
    super.initState();

    expensesController.addListener(refreshCalculations);
    currentFundController.addListener(refreshCalculations);

    loadEmergencyFund();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int index = 0; index < 10; index++) {
        Future.delayed(Duration(milliseconds: 100 + (index * 80)), () {
          if (!mounted) return;
          setState(() {
            _sectionVisible['section_$index'] = true;
          });
        });
      }
    });
  }

  void refreshCalculations() {
    if (mounted) {
      setState(() {});
    }
  }

  double getAmount(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  double get monthlyEssentialExpenses => getAmount(expensesController);
  double get currentFund => getAmount(currentFundController);
  double get targetAmount => monthlyEssentialExpenses * selectedTargetMonths;

  double get remainingAmount {
    final remaining = targetAmount - currentFund;
    return remaining > 0 ? remaining : 0;
  }

  double get exceededAmount {
    final exceeded = currentFund - targetAmount;
    return exceeded > 0 ? exceeded : 0;
  }

  double get actualProgress {
    if (targetAmount <= 0) return 0;
    return currentFund / targetAmount;
  }

  double get progress => actualProgress.clamp(0.0, 1.0);

  bool get isTargetCompleted => targetAmount > 0 && currentFund >= targetAmount;
  bool get isTargetExceeded => targetAmount > 0 && currentFund > targetAmount;

  Future<void> loadEmergencyFund() async {
    final data = await EmergencyFundService.getEmergencyFund();

    if (data != null) {
      final expenses = (data['monthlyEssentialExpenses'] as num?)?.toDouble() ?? 0;
      final fund = (data['currentFund'] as num?)?.toDouble() ?? 0;
      final months = (data['targetMonths'] as num?)?.toInt() ?? 6;

      expensesController.text = expenses.toStringAsFixed(0);
      currentFundController.text = fund.toStringAsFixed(0);

      if (targetMonths.contains(months)) {
        selectedTargetMonths = months;
      } else {
        selectedTargetMonths = 6;
      }
    }

    if (!mounted) return;

    setState(() {
      hasSavedFund = data != null;
      isLoading = false;
    });
  }

  Future<void> saveEmergencyFund() async {
    FocusScope.of(context).unfocus();

    if (expensesController.text.trim().isEmpty) {
      _showSnackBar('Please enter your monthly essential expenses');
      return;
    }

    if (monthlyEssentialExpenses <= 0) {
      _showSnackBar('Monthly essential expenses must be greater than ₹0');
      return;
    }

    if (selectedTargetMonths <= 0) {
      _showSnackBar('Please select a valid target duration');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await EmergencyFundService.saveEmergencyFund(
        monthlyEssentialExpenses: monthlyEssentialExpenses,
        targetMonths: selectedTargetMonths,
        currentFund: currentFund,
      );

      if (!mounted) return;

      setState(() {
        hasSavedFund = true;
      });

      _showSnackBar(isTargetExceeded
          ? 'Emergency fund saved. Your target is exceeded by ₹${exceededAmount.toStringAsFixed(0)}'
          : isTargetCompleted
              ? 'Emergency fund saved. Target completed successfully!'
              : 'Emergency fund saved successfully');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> clearEmergencyFund() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Clear Emergency Fund'),
          content: const Text('Are you sure you want to delete your saved emergency fund plan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Clear', style: TextStyle(color: AppTheme.danger)),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    await EmergencyFundService.clearEmergencyFund();

    expensesController.clear();
    currentFundController.clear();

    if (!mounted) return;

    setState(() {
      selectedTargetMonths = 6;
      hasSavedFund = false;
    });

    _showSnackBar('Emergency fund plan cleared');
  }

  Color getProgressColor() {
    if (actualProgress >= 1.0) return AppTheme.success;
    if (actualProgress >= 0.5) return AppTheme.warning;
    if (actualProgress > 0) return Colors.deepOrange;
    return AppTheme.subtitle;
  }

  String getProgressMessage() {
    if (targetAmount <= 0) return 'Enter your essential expenses to calculate your target.';
    if (isTargetExceeded) return 'Excellent! You have exceeded your target by ₹${exceededAmount.toStringAsFixed(0)}.';
    if (actualProgress >= 1.0) return 'Your emergency fund target is complete.';
    if (actualProgress >= 0.75) return 'You are close to completing your emergency fund target.';
    if (actualProgress >= 0.5) return 'You have completed half of your emergency fund target.';
    if (actualProgress > 0) return 'Continue building your emergency fund consistently.';
    return 'Start building your emergency fund as soon as possible.';
  }

  String getProgressText() {
    if (targetAmount <= 0) return '0% Complete';
    if (isTargetExceeded) return 'Target Exceeded';
    if (isTargetCompleted) return '100% Complete';
    return '${(actualProgress * 100).toStringAsFixed(0)}% Complete';
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
  void dispose() {
    expensesController.removeListener(refreshCalculations);
    currentFundController.removeListener(refreshCalculations);
    expensesController.dispose();
    currentFundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 96,
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency Fund',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.text)),
            const SizedBox(height: 4),
            Text('Build your financial safety net',
                style: TextStyle(fontSize: 13, color: AppTheme.subtitle, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          if (hasSavedFund)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: clearEmergencyFund,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 22),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAnimatedSection(
                        index: 0,
                        child: _buildGradientSummaryCard(),
                      ),
                      const SizedBox(height: 24),
                      _buildAnimatedSection(
                        index: 1,
                        child: _buildSectionHeader('Configuration', 'Define your safety requirements'),
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedSection(
                        index: 2,
                        child: _buildInputCard(),
                      ),
                      const SizedBox(height: 24),
                      _buildAnimatedSection(
                        index: 3,
                        child: _buildSectionHeader('Duration Target', 'How many months of expenses to save?'),
                      ),
                      const SizedBox(height: 12),
                      _buildAnimatedSection(
                        index: 4,
                        child: _buildTargetSelector(),
                      ),
                      const SizedBox(height: 24),
                      _buildAnimatedSection(
                        index: 5,
                        child: _buildInsightCard(),
                      ),
                      const SizedBox(height: 24),
                      _buildAnimatedSection(
                        index: 6,
                        child: _buildActionButtons(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.subtitle, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGradientSummaryCard() {
    final statusColor = getProgressColor();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
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
                  Text('Current Fund', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('₹${currentFund.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Target', '₹${targetAmount.toStringAsFixed(0)}'),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                _buildMiniStat(isTargetExceeded ? 'Exceeded' : 'Remaining',
                    '₹${(isTargetExceeded ? exceededAmount : remainingAmount).toStringAsFixed(0)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          _buildPremiumTextField(
            label: 'Monthly Expenses',
            controller: expensesController,
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 20),
          _buildPremiumTextField(
            label: 'Current Savings',
            controller: currentFundController,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.text)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            prefixText: '₹ ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetSelector() {
    return Row(
      children: targetMonths.map((months) {
        final isSelected = selectedTargetMonths == months;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedTargetMonths = months),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$months m',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightCard() {
    final statusColor = getProgressColor();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: statusColor.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTargetCompleted ? Icons.verified_rounded : Icons.lightbulb_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getProgressText(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: statusColor),
                ),
                const SizedBox(height: 4),
                Text(
                  getProgressMessage(),
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : saveEmergencyFund,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: AppTheme.primary.withOpacity(0.4),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    hasSavedFund ? 'Update Strategy' : 'Initialize Plan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
          ),
        ),
      ],
    );
  }
}