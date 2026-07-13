import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'budget_service.dart';
import 'expense_scanner_page.dart';
import 'expense_service.dart';
import 'premium_page.dart';
import 'subscription_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() =>
      _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final incomeController = TextEditingController();
  final foodController = TextEditingController();
  final rentController = TextEditingController();
  final travelController = TextEditingController();
  final shoppingController = TextEditingController();
  final billsController = TextEditingController();
  final entertainmentController =
      TextEditingController();
  final otherController = TextEditingController();

  bool isLoading = true;
  bool hasSavedBudget = false;
  bool isPremium = false;

  final Map<String, bool> _sectionVisible = {};

  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();

    final controllers = [
      incomeController,
      foodController,
      rentController,
      travelController,
      shoppingController,
      billsController,
      entertainmentController,
      otherController,
    ];

    for (final controller in controllers) {
      controller.addListener(refreshCalculations);
    }

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

    loadPageData();
  }

  void refreshCalculations() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadPageData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final budget = await BudgetService.getBudget();

    final savedExpenses =
        await ExpenseService.getExpenses();

    final premiumStatus =
        await SubscriptionService.isPremium();

    if (budget != null) {
      incomeController.text =
          getValue(
            budget,
            'monthlyIncome',
          ).toStringAsFixed(0);

      foodController.text =
          getValue(
            budget,
            'food',
          ).toStringAsFixed(0);

      rentController.text =
          getValue(
            budget,
            'rent',
          ).toStringAsFixed(0);

      travelController.text =
          getValue(
            budget,
            'travel',
          ).toStringAsFixed(0);

      shoppingController.text =
          getValue(
            budget,
            'shopping',
          ).toStringAsFixed(0);

      billsController.text =
          getValue(
            budget,
            'bills',
          ).toStringAsFixed(0);

      entertainmentController.text =
          getValue(
            budget,
            'entertainment',
          ).toStringAsFixed(0);

      otherController.text =
          getValue(
            budget,
            'other',
          ).toStringAsFixed(0);
    }

    if (!mounted) return;

    setState(() {
      expenses = savedExpenses;
      hasSavedBudget = budget != null;
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  Future<void> openExpenseScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ExpenseScannerPage(),
      ),
    );

    if (result == true) {
      await loadPageData();
    }
  }

  Future<void> openPremiumPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PremiumPage(),
      ),
    );

    await loadPageData();
  }

  double getValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double getAmount(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  double get monthlyIncome =>
      getAmount(incomeController);

  double get totalBudget =>
      getAmount(foodController) +
      getAmount(rentController) +
      getAmount(travelController) +
      getAmount(shoppingController) +
      getAmount(billsController) +
      getAmount(entertainmentController) +
      getAmount(otherController);

  double get remainingIncome =>
      monthlyIncome - totalBudget;

  double get budgetUsage {
    if (monthlyIncome <= 0) {
      return 0;
    }

    return totalBudget / monthlyIncome;
  }

  double getCategorySpent(
    String category,
  ) {
    return expenses
        .where(
          (expense) =>
              expense['category']
                  .toString()
                  .toLowerCase() ==
              category.toLowerCase(),
        )
        .fold<double>(
          0,
          (total, expense) {
            final amount = expense['amount'];

            if (amount is num) {
              return total + amount.toDouble();
            }

            return total;
          },
        );
  }

  double get totalActualSpent {
    return expenses.fold<double>(
      0,
      (total, expense) {
        final amount = expense['amount'];

        if (amount is num) {
          return total + amount.toDouble();
        }

        return total;
      },
    );
  }

  Future<void> showBudgetTallyMismatchDialog() async {
    final double excess =
        totalBudget - monthlyIncome;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          iconPadding: const EdgeInsets.only(top: 24),
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.danger.withOpacity(0.10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 34,
              color: AppTheme.danger,
            ),
          ),
          title: const Text(
            'Budget Tally Mismatch',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppTheme.text,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    buildTallyRow(
                      title: 'Monthly Income',
                      amount: monthlyIncome,
                    ),
                    buildTallyRow(
                      title: 'Total Planned Budget',
                      amount: totalBudget,
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFE9EDF2),
                    ),
                    buildTallyRow(
                      title: 'Exceeded By',
                      amount: excess,
                      isWarning: true,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your total category budget cannot exceed your monthly income. Please reduce one or more category limits.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.subtitle,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Correct Budget',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveBudget() async {
    if (monthlyIncome <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter your monthly income',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

      return;
    }

    if (totalBudget > monthlyIncome) {
      await showBudgetTallyMismatchDialog();
      return;
    }

    await BudgetService.saveBudget(
      monthlyIncome: monthlyIncome,
      food: getAmount(foodController),
      rent: getAmount(rentController),
      travel: getAmount(travelController),
      shopping: getAmount(shoppingController),
      bills: getAmount(billsController),
      entertainment:
          getAmount(entertainmentController),
      other: getAmount(otherController),
    );

    if (!mounted) return;

    setState(() {
      hasSavedBudget = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Budget saved successfully',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> clearBudget() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.danger.withOpacity(0.10),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 28,
              color: AppTheme.danger,
            ),
          ),
          title: const Text(
            'Clear Budget',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppTheme.text,
            ),
          ),
          content: const Text(
            'This will delete your budget limits. Saved expenses will not be deleted.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.subtitle,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                        false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.subtitle,
                      side: BorderSide(color: AppTheme.subtitle.withOpacity(0.30)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                        true,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    await BudgetService.clearBudget();

    incomeController.clear();
    foodController.clear();
    rentController.clear();
    travelController.clear();
    shoppingController.clear();
    billsController.clear();
    entertainmentController.clear();
    otherController.clear();

    if (!mounted) return;

    setState(() {
      hasSavedBudget = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Budget cleared',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Color getBudgetColor() {
    if (monthlyIncome <= 0) {
      return AppTheme.subtitle;
    }

    if (budgetUsage > 1) {
      return AppTheme.danger;
    }

    if (budgetUsage >= 0.8) {
      return AppTheme.warning;
    }

    return AppTheme.success;
  }

  String getBudgetMessage() {
    if (monthlyIncome <= 0) {
      return 'Enter your monthly income to start planning.';
    }

    if (budgetUsage > 1) {
      return 'Your planned budget exceeds your monthly income.';
    }

    if (budgetUsage >= 0.8) {
      return 'You are using most of your monthly income.';
    }

    return 'Your budget is within a healthy range.';
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

  Widget buildNumberField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.text,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppTheme.subtitle,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: AppTheme.primary,
            size: 22,
          ),
          prefixText: '₹  ',
          prefixStyle: const TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: AppTheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget buildTallyRow({
    required String title,
    required double amount,
    bool isWarning = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isBold
                    ? FontWeight.bold
                    : FontWeight.normal,
                color:
                    isWarning ? AppTheme.danger : AppTheme.text,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isBold
                  ? FontWeight.bold
                  : FontWeight.w600,
              color:
                  isWarning ? AppTheme.danger : AppTheme.text,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategoryProgress({
    required String category,
    required IconData icon,
    required double budget,
  }) {
    final double spent =
        getCategorySpent(category);

    final double remaining =
        budget - spent;

    final double usage = budget > 0
        ? spent / budget
        : 0;

    final double progress =
        usage.clamp(0.0, 1.0);

    final bool isOverBudget =
        budget > 0 && spent > budget;

    Color progressColor;

    if (isOverBudget) {
      progressColor = AppTheme.danger;
    } else if (usage >= 0.8) {
      progressColor = AppTheme.warning;
    } else {
      progressColor = AppTheme.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                Text(
                  '₹${spent.toStringAsFixed(0)} / '
                  '₹${budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: progress),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: AppTheme.background,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget <= 0
                        ? 'No budget set'
                        : '${(usage * 100).toStringAsFixed(0)}% used',
                    style: const TextStyle(
                      color: AppTheme.subtitle,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  isOverBudget
                      ? 'Over by ₹${remaining.abs().toStringAsFixed(0)}'
                      : 'Remaining ₹${remaining < 0 ? 0 : remaining.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOverBudget
                        ? AppTheme.danger
                        : progressColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryRow({
    required String title,
    required double amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.subtitle,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPremiumLockCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF081B3A), Color(0xFF1E4ACB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.24),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.14),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Advanced Budget Insights Locked',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upgrade to Premium to compare your budget with actual spending and track every category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.88),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: Column(
                children: [
                  _buildLockedFeature(
                    icon: Icons.compare_arrows,
                    title: 'Budget vs Actual Spending',
                  ),
                  const SizedBox(height: 6),
                  _buildLockedFeature(
                    icon: Icons.category_outlined,
                    title: 'Category-wise Spending Tracking',
                  ),
                  const SizedBox(height: 6),
                  _buildLockedFeature(
                    icon: Icons.warning_amber_outlined,
                    title: 'Over-Budget Warnings',
                  ),
                  const SizedBox(height: 6),
                  _buildLockedFeature(
                    icon: Icons.insights_outlined,
                    title: 'Advanced Budget Progress',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openPremiumPage,
                icon: const Icon(
                  Icons.workspace_premium,
                  size: 20,
                ),
                label: const Text(
                  'Unlock Advanced Budget Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedFeature({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.95),
          size: 22,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    incomeController.dispose();
    foodController.dispose();
    rentController.dispose();
    travelController.dispose();
    shoppingController.dispose();
    billsController.dispose();
    entertainmentController.dispose();
    otherController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
        budgetUsage.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Budget Planner',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 36,
              height: 36,
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
              child: IconButton(
                onPressed: loadPageData,
                icon: const Icon(
                  Icons.refresh,
                  size: 20,
                  color: AppTheme.primary,
                ),
                tooltip: 'Refresh Expenses',
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasSavedBudget)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 36,
                height: 36,
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
                child: IconButton(
                  onPressed: clearBudget,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppTheme.danger,
                  ),
                  tooltip: 'Clear Budget',
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadPageData,
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
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
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
                                                    'Smart Expense Scanner',
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
                                            Icon(Icons.auto_awesome_rounded, color: Colors.white.withOpacity(0.95), size: 20),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'Scan a receipt or ticket to automatically detect the amount and expense category.',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.88),
                                            fontSize: 14,
                                            height: 1.45,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: openExpenseScanner,
                                            icon: const Icon(
                                              Icons.document_scanner,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Scan Receipt / Ticket',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: AppTheme.primary,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          _buildAnimatedSection(
                            index: 1,
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Budget Planning',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.text,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Set your monthly income and category limits',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.subtitle,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isPremium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.workspace_premium,
                                          size: 16,
                                          color: AppTheme.primary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Premium',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          _buildAnimatedSection(
                            index: 2,
                            child: buildNumberField(
                              label: 'Monthly Income',
                              icon: Icons.account_balance_wallet,
                              controller: incomeController,
                            ),
                          ),

                          const SizedBox(height: 24),

                          _buildAnimatedSection(
                            index: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category Budget Limits',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Set the maximum amount you want to spend in each category.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.subtitle,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                buildNumberField(
                                  label: 'Food',
                                  icon: Icons.restaurant,
                                  controller: foodController,
                                ),
                                const SizedBox(height: 14),
                                buildNumberField(
                                  label: 'Rent',
                                  icon: Icons.home,
                                  controller: rentController,
                                ),
                                const SizedBox(height: 14),
                                buildNumberField(
                                  label: 'Travel',
                                  icon: Icons.directions_bus,
                                  controller: travelController,
                                ),
                                const SizedBox(height: 14),
                                buildNumberField(
                                  label: 'Shopping',
                                  icon: Icons.shopping_bag,
                                  controller: shoppingController,
                                ),
                                const SizedBox(height: 14),
                                buildNumberField(
                                  label: 'Bills',
                                  icon: Icons.receipt_long,
                                  controller: billsController,
                                ),
                                const SizedBox(height: 14),
                                buildNumberField(
                                  label: 'Entertainment',
                                  icon: Icons.movie,
                                  controller: entertainmentController,
                                ),
                                const SizedBox(height: 14),
                                buildNumberField(
                                  label: 'Other',
                                  icon: Icons.more_horiz,
                                  controller: otherController,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          _buildAnimatedSection(
                            index: 4,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: saveBudget,
                                icon: const Icon(
                                  Icons.save,
                                  size: 20,
                                ),
                                label: Text(
                                  hasSavedBudget
                                      ? 'Update Budget'
                                      : 'Save Budget',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          _buildAnimatedSection(
                            index: 5,
                            child: Container(
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
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.pie_chart_rounded,
                                          color: AppTheme.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Budget Summary',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.text,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  buildSummaryRow(
                                    title: 'Monthly Income',
                                    amount: monthlyIncome,
                                  ),
                                  buildSummaryRow(
                                    title: 'Total Planned Budget',
                                    amount: totalBudget,
                                  ),
                                  buildSummaryRow(
                                    title: 'Actual Expenses',
                                    amount: totalActualSpent,
                                  ),
                                  buildSummaryRow(
                                    title: remainingIncome >= 0
                                        ? 'Unallocated Income'
                                        : 'Planned Over Budget',
                                    amount: remainingIncome.abs(),
                                  ),
                                  const SizedBox(height: 18),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 900),
                                      curve: Curves.easeOutCubic,
                                      tween: Tween<double>(begin: 0, end: progress),
                                      builder: (context, value, child) {
                                        return LinearProgressIndicator(
                                          value: value,
                                          minHeight: 12,
                                          backgroundColor: AppTheme.background,
                                          valueColor: AlwaysStoppedAnimation<Color>(getBudgetColor()),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    monthlyIncome <= 0
                                        ? '0%'
                                        : '${(budgetUsage * 100).toStringAsFixed(0)}% of income planned',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: getBudgetColor(),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        budgetUsage > 1
                                            ? Icons.warning_amber_rounded
                                            : Icons.check_circle_outline,
                                        color: getBudgetColor(),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          getBudgetMessage(),
                                          style: TextStyle(
                                            color: getBudgetColor(),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          if (!isPremium)
                            _buildAnimatedSection(
                              index: 6,
                              child: buildPremiumLockCard(),
                            ),

                          if (isPremium) ...[
                            _buildAnimatedSection(
                              index: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Budget vs Actual Spending',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    expenses.isEmpty
                                        ? 'No expenses recorded yet. Scanned expenses will appear here automatically.'
                                        : '${expenses.length} expense record${expenses.length == 1 ? '' : 's'} included.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.subtitle,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  buildCategoryProgress(
                                    category: 'Food',
                                    icon: Icons.restaurant,
                                    budget: getAmount(foodController),
                                  ),
                                  buildCategoryProgress(
                                    category: 'Rent',
                                    icon: Icons.home,
                                    budget: getAmount(rentController),
                                  ),
                                  buildCategoryProgress(
                                    category: 'Travel',
                                    icon: Icons.directions_bus,
                                    budget: getAmount(travelController),
                                  ),
                                  buildCategoryProgress(
                                    category: 'Shopping',
                                    icon: Icons.shopping_bag,
                                    budget: getAmount(shoppingController),
                                  ),
                                  buildCategoryProgress(
                                    category: 'Bills',
                                    icon: Icons.receipt_long,
                                    budget: getAmount(billsController),
                                  ),
                                  buildCategoryProgress(
                                    category: 'Entertainment',
                                    icon: Icons.movie,
                                    budget: getAmount(entertainmentController),
                                  ),
                                  buildCategoryProgress(
                                    category: 'Other',
                                    icon: Icons.more_horiz,
                                    budget: getAmount(otherController),
                                  ),
                                ],
                              ),
                            ),
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
}