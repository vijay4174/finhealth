import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          icon: const Icon(
            Icons.warning_amber_rounded,
            size: 50,
            color: Colors.red,
          ),
          title: const Text(
            'Budget Tally Mismatch',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
              ),
              buildTallyRow(
                title: 'Exceeded By',
                amount: excess,
                isWarning: true,
                isBold: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your total category budget cannot exceed your monthly income. Please reduce one or more category limits.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Correct Budget',
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
        const SnackBar(
          content: Text(
            'Please enter your monthly income',
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
      const SnackBar(
        content: Text(
          'Budget saved successfully',
        ),
      ),
    );
  }

  Future<void> clearBudget() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear Budget',
          ),
          content: const Text(
            'This will delete your budget limits. Saved expenses will not be deleted.',
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
                'Clear',
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
      const SnackBar(
        content: Text(
          'Budget cleared',
        ),
      ),
    );
  }

  Color getBudgetColor() {
    if (monthlyIncome <= 0) {
      return Colors.grey;
    }

    if (budgetUsage > 1) {
      return Colors.red;
    }

    if (budgetUsage >= 0.8) {
      return Colors.orange;
    }

    return Colors.green;
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

  Widget buildNumberField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: '₹ ',
        border: const OutlineInputBorder(),
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
                    isWarning ? Colors.red : null,
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
                  isWarning ? Colors.red : null,
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
      progressColor = Colors.red;
    } else if (usage >= 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  '₹${spent.toStringAsFixed(0)} / '
                  '₹${budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius:
                  BorderRadius.circular(10),
              color: progressColor,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    budget <= 0
                        ? 'No budget set'
                        : '${(usage * 100).toStringAsFixed(0)}% used',
                  ),
                ),

                Text(
                  isOverBudget
                      ? 'Over by ₹${remaining.abs().toStringAsFixed(0)}'
                      : 'Remaining ₹${remaining < 0 ? 0 : remaining.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverBudget
                        ? Colors.red
                        : progressColor,
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
            child: Text(title),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
              Icons.lock_outline,
              size: 55,
            ),

            const SizedBox(height: 15),

            const Text(
              'Advanced Budget Insights Locked',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Upgrade to Premium to compare your budget with actual spending and track every category.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.compare_arrows,
              ),
              title: Text(
                'Budget vs Actual Spending',
              ),
            ),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.category_outlined,
              ),
              title: Text(
                'Category-wise Spending Tracking',
              ),
            ),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.warning_amber_outlined,
              ),
              title: Text(
                'Over-Budget Warnings',
              ),
            ),

            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.insights_outlined,
              ),
              title: Text(
                'Advanced Budget Progress',
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
                  'Unlock Advanced Budget Insights',
                ),
              ),
            ),
          ],
        ),
      ),
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
      appBar: AppBar(
        title: const Text(
          'Smart Budget Planner',
        ),
        centerTitle: true,
        actions: [
          if (isPremium)
            const Padding(
              padding: EdgeInsets.only(
                right: 8,
              ),
              child: Icon(
                Icons.workspace_premium,
              ),
            ),

          IconButton(
            onPressed: loadPageData,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh Expenses',
          ),

          if (hasSavedBudget)
            IconButton(
              onPressed: clearBudget,
              icon: const Icon(
                Icons.delete_outline,
              ),
              tooltip: 'Clear Budget',
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadPageData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 6,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const Icon(
                            Icons
                                .document_scanner_outlined,
                            size: 50,
                            color: Colors.deepPurple,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Smart Expense Scanner',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Scan a receipt or ticket to automatically detect the amount and expense category.',
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 15),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  openExpenseScanner,
                              icon: const Icon(
                                Icons.document_scanner,
                              ),
                              label: const Text(
                                'Scan Receipt / Ticket',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Budget Planning',
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

                  buildNumberField(
                    label: 'Monthly Income',
                    icon: Icons
                        .account_balance_wallet,
                    controller:
                        incomeController,
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Category Budget Limits',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Set the maximum amount you want to spend in each category.',
                  ),

                  const SizedBox(height: 18),

                  buildNumberField(
                    label: 'Food',
                    icon: Icons.restaurant,
                    controller:
                        foodController,
                  ),

                  const SizedBox(height: 15),

                  buildNumberField(
                    label: 'Rent',
                    icon: Icons.home,
                    controller:
                        rentController,
                  ),

                  const SizedBox(height: 15),

                  buildNumberField(
                    label: 'Travel',
                    icon:
                        Icons.directions_bus,
                    controller:
                        travelController,
                  ),

                  const SizedBox(height: 15),

                  buildNumberField(
                    label: 'Shopping',
                    icon:
                        Icons.shopping_bag,
                    controller:
                        shoppingController,
                  ),

                  const SizedBox(height: 15),

                  buildNumberField(
                    label: 'Bills',
                    icon:
                        Icons.receipt_long,
                    controller:
                        billsController,
                  ),

                  const SizedBox(height: 15),

                  buildNumberField(
                    label: 'Entertainment',
                    icon: Icons.movie,
                    controller:
                        entertainmentController,
                  ),

                  const SizedBox(height: 15),

                  buildNumberField(
                    label: 'Other',
                    icon:
                        Icons.more_horiz,
                    controller:
                        otherController,
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saveBudget,
                      icon: const Icon(
                        Icons.save,
                      ),
                      label: Text(
                        hasSavedBudget
                            ? 'Update Budget'
                            : 'Save Budget',
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Card(
                    elevation: 6,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const Text(
                            'Budget Summary',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 18),

                          buildSummaryRow(
                            title: 'Monthly Income',
                            amount: monthlyIncome,
                          ),

                          buildSummaryRow(
                            title:
                                'Total Planned Budget',
                            amount: totalBudget,
                          ),

                          buildSummaryRow(
                            title: 'Actual Expenses',
                            amount:
                                totalActualSpent,
                          ),

                          buildSummaryRow(
                            title:
                                remainingIncome >= 0
                                    ? 'Unallocated Income'
                                    : 'Planned Over Budget',
                            amount:
                                remainingIncome.abs(),
                          ),

                          const SizedBox(height: 15),

                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                            color: getBudgetColor(),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            monthlyIncome <= 0
                                ? '0%'
                                : '${(budgetUsage * 100).toStringAsFixed(0)}% of income planned',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              color: getBudgetColor(),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                budgetUsage > 1
                                    ? Icons.warning_amber
                                    : Icons
                                        .check_circle_outline,
                                color: getBudgetColor(),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  getBudgetMessage(),
                                  style: TextStyle(
                                    color:
                                        getBudgetColor(),
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (!isPremium)
                    buildPremiumLockCard(),

                  if (isPremium) ...[
                    const Text(
                      'Budget vs Actual Spending',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      expenses.isEmpty
                          ? 'No expenses recorded yet. Scanned expenses will appear here automatically.'
                          : '${expenses.length} expense record${expenses.length == 1 ? '' : 's'} included.',
                    ),

                    const SizedBox(height: 15),

                    buildCategoryProgress(
                      category: 'Food',
                      icon: Icons.restaurant,
                      budget: getAmount(
                        foodController,
                      ),
                    ),

                    buildCategoryProgress(
                      category: 'Rent',
                      icon: Icons.home,
                      budget: getAmount(
                        rentController,
                      ),
                    ),

                    buildCategoryProgress(
                      category: 'Travel',
                      icon:
                          Icons.directions_bus,
                      budget: getAmount(
                        travelController,
                      ),
                    ),

                    buildCategoryProgress(
                      category: 'Shopping',
                      icon:
                          Icons.shopping_bag,
                      budget: getAmount(
                        shoppingController,
                      ),
                    ),

                    buildCategoryProgress(
                      category: 'Bills',
                      icon:
                          Icons.receipt_long,
                      budget: getAmount(
                        billsController,
                      ),
                    ),

                    buildCategoryProgress(
                      category: 'Entertainment',
                      icon: Icons.movie,
                      budget: getAmount(
                        entertainmentController,
                      ),
                    ),

                    buildCategoryProgress(
                      category: 'Other',
                      icon:
                          Icons.more_horiz,
                      budget: getAmount(
                        otherController,
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}