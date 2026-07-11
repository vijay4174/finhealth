import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'monthly_service.dart';
import 'premium_page.dart';
import 'subscription_service.dart';

class MonthlyTrackingPage extends StatefulWidget {
  const MonthlyTrackingPage({super.key});

  @override
  State<MonthlyTrackingPage> createState() =>
      _MonthlyTrackingPageState();
}

class _MonthlyTrackingPageState
    extends State<MonthlyTrackingPage> {
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  final List<String> monthNames = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    final savedRecords =
        await MonthlyService.getMonthlyRecords();

    if (!mounted) return;

    setState(() {
      records = savedRecords;
      isLoading = false;
    });
  }

  Future<void> tryAddMonthlyRecord() async {
    final canAdd =
        await SubscriptionService.canAddMonthlyRecord(
      records.length,
    );

    if (!mounted) return;

    if (canAdd) {
      await showRecordDialog();
      return;
    }

    await showMonthlyLimitDialog();
  }

  Future<void> showMonthlyLimitDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.workspace_premium,
            size: 45,
          ),
          title: const Text(
            'Free Monthly Limit Reached',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Free users can track up to 6 monthly records. '
            'Upgrade to Premium to track unlimited months.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Not Now',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PremiumPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.workspace_premium,
              ),
              label: const Text(
                'View Premium',
              ),
            ),
          ],
        );
      },
    );
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

  Future<void> showTallyMismatchDialog({
    required double income,
    required double expenses,
    required double savings,
    required double investments,
  }) async {
    final totalAllocated =
        expenses + savings + investments;

    final excess =
        totalAllocated - income;

    await showDialog<void>(
      context: context,
      builder: (tallyDialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            size: 50,
            color: Colors.red,
          ),
          title: const Text(
            'Financial Tally Mismatch',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTallyRow(
                title: 'Monthly Income',
                amount: income,
              ),
              buildTallyRow(
                title: 'Expenses',
                amount: expenses,
              ),
              buildTallyRow(
                title: 'Savings',
                amount: savings,
              ),
              buildTallyRow(
                title: 'Investments',
                amount: investments,
              ),
              const Divider(
                height: 24,
              ),
              buildTallyRow(
                title: 'Total Allocated',
                amount: totalAllocated,
                isBold: true,
              ),
              const SizedBox(height: 8),
              buildTallyRow(
                title: 'Exceeded By',
                amount: excess,
                isWarning: true,
                isBold: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Expenses, savings and investments cannot exceed your monthly income. Please correct the amounts.',
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
                    tallyDialogContext,
                  );
                },
                child: const Text(
                  'Correct Amounts',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showRecordDialog({
    Map<String, dynamic>? existingRecord,
  }) async {
    final now = DateTime.now();

    int selectedMonth = existingRecord == null
        ? now.month
        : (existingRecord['month'] as num).toInt();

    int selectedYear = existingRecord == null
        ? now.year
        : (existingRecord['year'] as num).toInt();

    final incomeController = TextEditingController(
      text: existingRecord == null
          ? ''
          : getAmount(
              existingRecord,
              'income',
            ).toStringAsFixed(0),
    );

    final expensesController =
        TextEditingController(
      text: existingRecord == null
          ? ''
          : getAmount(
              existingRecord,
              'expenses',
            ).toStringAsFixed(0),
    );

    final savingsController = TextEditingController(
      text: existingRecord == null
          ? ''
          : getAmount(
              existingRecord,
              'savings',
            ).toStringAsFixed(0),
    );

    final investmentsController =
        TextEditingController(
      text: existingRecord == null
          ? ''
          : getAmount(
              existingRecord,
              'investments',
            ).toStringAsFixed(0),
    );

    final List<int> years = List.generate(
      11,
      (index) => now.year - 5 + index,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existingRecord == null
                    ? 'Add Monthly Record'
                    : 'Update Monthly Record',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        12,
                        (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(
                              monthNames[index],
                            ),
                          );
                        },
                      ),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedMonth = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      items: years.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year.toString(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedYear = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    buildAmountField(
                      label: 'Income',
                      controller: incomeController,
                    ),

                    const SizedBox(height: 15),

                    buildAmountField(
                      label: 'Expenses',
                      controller: expensesController,
                    ),

                    const SizedBox(height: 15),

                    buildAmountField(
                      label: 'Savings',
                      controller: savingsController,
                    ),

                    const SizedBox(height: 15),

                    buildAmountField(
                      label: 'Investments',
                      controller:
                          investmentsController,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final income = double.tryParse(
                          incomeController.text,
                        ) ??
                        0;

                    final expenses = double.tryParse(
                          expensesController.text,
                        ) ??
                        0;

                    final savings = double.tryParse(
                          savingsController.text,
                        ) ??
                        0;

                    final investments =
                        double.tryParse(
                              investmentsController.text,
                            ) ??
                            0;

                    if (income <= 0) {
                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Income must be greater than 0',
                          ),
                        ),
                      );

                      return;
                    }

                    final double totalAllocated =
                        expenses +
                            savings +
                            investments;

                    if (totalAllocated > income) {
                      await showTallyMismatchDialog(
                        income: income,
                        expenses: expenses,
                        savings: savings,
                        investments: investments,
                      );

                      return;
                    }

                    await MonthlyService
                        .saveMonthlyRecord(
                      year: selectedYear,
                      month: selectedMonth,
                      income: income,
                      expenses: expenses,
                      savings: savings,
                      investments: investments,
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    await loadRecords();

                    if (!mounted) return;

                    ScaffoldMessenger.of(
                      this.context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          existingRecord == null
                              ? 'Monthly record saved successfully'
                              : 'Monthly record updated successfully',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    existingRecord == null
                        ? 'Save'
                        : 'Update',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    incomeController.dispose();
    expensesController.dispose();
    savingsController.dispose();
    investmentsController.dispose();
  }

  Widget buildAmountField({
    required String label,
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
        vertical: 6,
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

  Future<void> deleteRecord(
    Map<String, dynamic> record,
  ) async {
    final int month =
        (record['month'] as num).toInt();

    final int year =
        (record['year'] as num).toInt();

    final bool? shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Monthly Record',
          ),
          content: Text(
            'Delete ${monthNames[month - 1]} $year record?',
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

    await MonthlyService.deleteMonthlyRecord(
      record['id'].toString(),
    );

    await loadRecords();
  }

  Future<void> clearAllRecords() async {
    final bool? shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear Monthly Records',
          ),
          content: const Text(
            'Are you sure you want to delete all monthly financial records?',
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

    await MonthlyService.clearMonthlyRecords();

    await loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Tracking',
        ),
        centerTitle: true,
        actions: [
          if (records.isNotEmpty)
            IconButton(
              onPressed: clearAllRecords,
              tooltip: 'Clear All',
              icon: const Icon(
                Icons.delete_sweep_outlined,
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
                          Icons.calendar_month_outlined,
                          size: 80,
                          color: Colors.deepPurple,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'No Monthly Records Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Add your monthly income, expenses, savings and investments to track progress over time.',
                          textAlign:
                              TextAlign.center,
                        ),

                        const SizedBox(height: 25),

                        ElevatedButton.icon(
                          onPressed:
                              tryAddMonthlyRecord,
                          icon: const Icon(
                            Icons.add,
                          ),
                          label: const Text(
                            'Add First Record',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadRecords,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      90,
                    ),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record =
                          records[index];

                      final int month =
                          (record['month'] as num)
                              .toInt();

                      final int year =
                          (record['year'] as num)
                              .toInt();

                      final double income =
                          getAmount(
                        record,
                        'income',
                      );

                      final double expenses =
                          getAmount(
                        record,
                        'expenses',
                      );

                      final double savings =
                          getAmount(
                        record,
                        'savings',
                      );

                      final double investments =
                          getAmount(
                        record,
                        'investments',
                      );

                      final double expenseRatio =
                          income > 0
                              ? (expenses / income) *
                                  100
                              : 0;

                      final double savingsRate =
                          income > 0
                              ? (savings / income) *
                                  100
                              : 0;

                      final double investmentRate =
                          income > 0
                              ? (investments /
                                      income) *
                                  100
                              : 0;

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
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    child: Icon(
                                      Icons
                                          .calendar_month,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child: Text(
                                      '${monthNames[month - 1]} $year',
                                      style:
                                          const TextStyle(
                                        fontSize: 20,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),

                                  PopupMenuButton<
                                      String>(
                                    onSelected:
                                        (value) {
                                      if (value ==
                                          'edit') {
                                        showRecordDialog(
                                          existingRecord:
                                              record,
                                        );
                                      }

                                      if (value ==
                                          'delete') {
                                        deleteRecord(
                                          record,
                                        );
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              'Edit',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              color:
                                                  Colors.red,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              'Delete',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const Divider(
                                height: 30,
                              ),

                              buildRecordRow(
                                icon: Icons
                                    .account_balance_wallet,
                                title: 'Income',
                                value:
                                    '₹${income.toStringAsFixed(0)}',
                              ),

                              buildRecordRow(
                                icon:
                                    Icons.money_off,
                                title: 'Expenses',
                                value:
                                    '₹${expenses.toStringAsFixed(0)} (${expenseRatio.toStringAsFixed(0)}%)',
                              ),

                              buildRecordRow(
                                icon: Icons.savings,
                                title: 'Savings',
                                value:
                                    '₹${savings.toStringAsFixed(0)} (${savingsRate.toStringAsFixed(0)}%)',
                              ),

                              buildRecordRow(
                                icon:
                                    Icons.trending_up,
                                title:
                                    'Investments',
                                value:
                                    '₹${investments.toStringAsFixed(0)} (${investmentRate.toStringAsFixed(0)}%)',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: records.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: tryAddMonthlyRecord,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Add Month',
              ),
            ),
    );
  }

  Widget buildRecordRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        textAlign: TextAlign.end,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}