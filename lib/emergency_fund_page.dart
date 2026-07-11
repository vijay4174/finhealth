import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'emergency_fund_service.dart';

class EmergencyFundPage extends StatefulWidget {
  const EmergencyFundPage({super.key});

  @override
  State<EmergencyFundPage> createState() =>
      _EmergencyFundPageState();
}

class _EmergencyFundPageState
    extends State<EmergencyFundPage> {
  final TextEditingController
      expensesController =
      TextEditingController();

  final TextEditingController
      currentFundController =
      TextEditingController();

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

  @override
  void initState() {
    super.initState();

    expensesController.addListener(
      refreshCalculations,
    );

    currentFundController.addListener(
      refreshCalculations,
    );

    loadEmergencyFund();
  }

  void refreshCalculations() {
    if (mounted) {
      setState(() {});
    }
  }

  double getAmount(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  double get monthlyEssentialExpenses =>
      getAmount(expensesController);

  double get currentFund =>
      getAmount(currentFundController);

  double get targetAmount =>
      monthlyEssentialExpenses *
      selectedTargetMonths;

  double get remainingAmount {
    final remaining =
        targetAmount - currentFund;

    return remaining > 0 ? remaining : 0;
  }

  double get exceededAmount {
    final exceeded =
        currentFund - targetAmount;

    return exceeded > 0 ? exceeded : 0;
  }

  double get actualProgress {
    if (targetAmount <= 0) {
      return 0;
    }

    return currentFund / targetAmount;
  }

  double get progress {
    return actualProgress.clamp(
      0.0,
      1.0,
    );
  }

  bool get isTargetCompleted {
    return targetAmount > 0 &&
        currentFund >= targetAmount;
  }

  bool get isTargetExceeded {
    return targetAmount > 0 &&
        currentFund > targetAmount;
  }

  Future<void> loadEmergencyFund() async {
    final data = await EmergencyFundService
        .getEmergencyFund();

    if (data != null) {
      final expenses =
          (data['monthlyEssentialExpenses']
                      as num?)
                  ?.toDouble() ??
              0;

      final fund =
          (data['currentFund'] as num?)
                  ?.toDouble() ??
              0;

      final months =
          (data['targetMonths'] as num?)
                  ?.toInt() ??
              6;

      expensesController.text =
          expenses.toStringAsFixed(0);

      currentFundController.text =
          fund.toStringAsFixed(0);

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

    if (expensesController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your monthly essential expenses',
          ),
        ),
      );

      return;
    }

    if (monthlyEssentialExpenses <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Monthly essential expenses must be greater than ₹0',
          ),
        ),
      );

      return;
    }

    if (selectedTargetMonths <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a valid target duration',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await EmergencyFundService
          .saveEmergencyFund(
        monthlyEssentialExpenses:
            monthlyEssentialExpenses,
        targetMonths:
            selectedTargetMonths,
        currentFund: currentFund,
      );

      if (!mounted) return;

      setState(() {
        hasSavedFund = true;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            isTargetExceeded
                ? 'Emergency fund saved. Your target is exceeded by ₹${exceededAmount.toStringAsFixed(0)}'
                : isTargetCompleted
                    ? 'Emergency fund saved. Target completed successfully!'
                    : 'Emergency fund saved successfully',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> clearEmergencyFund() async {
    final shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear Emergency Fund',
          ),
          content: const Text(
            'Are you sure you want to delete your saved emergency fund plan?',
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

    if (shouldClear != true) {
      return;
    }

    await EmergencyFundService
        .clearEmergencyFund();

    expensesController.clear();
    currentFundController.clear();

    if (!mounted) return;

    setState(() {
      selectedTargetMonths = 6;
      hasSavedFund = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Emergency fund plan cleared',
        ),
      ),
    );
  }

  Color getProgressColor() {
    final percentage =
        actualProgress * 100;

    if (percentage >= 100) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else if (percentage > 0) {
      return Colors.deepOrange;
    }

    return Colors.grey;
  }

  String getProgressMessage() {
    final percentage =
        actualProgress * 100;

    if (targetAmount <= 0) {
      return 'Enter your essential expenses to calculate your target.';
    }

    if (isTargetExceeded) {
      return 'Excellent! You have exceeded your emergency fund target by ₹${exceededAmount.toStringAsFixed(0)}.';
    }

    if (percentage >= 100) {
      return 'Your emergency fund target is complete.';
    }

    if (percentage >= 75) {
      return 'You are close to completing your emergency fund target.';
    }

    if (percentage >= 50) {
      return 'You have completed half of your emergency fund target.';
    }

    if (percentage > 0) {
      return 'Continue building your emergency fund consistently.';
    }

    return 'Start building your emergency fund as soon as possible.';
  }

  String getProgressText() {
    if (targetAmount <= 0) {
      return '0% Complete';
    }

    if (isTargetExceeded) {
      return 'Target Exceeded';
    }

    if (isTargetCompleted) {
      return '100% Complete';
    }

    return '${(actualProgress * 100).toStringAsFixed(0)}% Complete';
  }

  Widget buildNumberField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter
            .digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: '₹ ',
        border:
            const OutlineInputBorder(),
      ),
    );
  }

  Widget buildSummaryRow({
    required String title,
    required double amount,
    Color? amountColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    expensesController.removeListener(
      refreshCalculations,
    );

    currentFundController.removeListener(
      refreshCalculations,
    );

    expensesController.dispose();
    currentFundController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Fund',
        ),
        centerTitle: true,
        actions: [
          if (hasSavedFund)
            IconButton(
              onPressed:
                  clearEmergencyFund,
              icon: const Icon(
                Icons.delete_outline,
              ),
              tooltip:
                  'Clear Emergency Fund',
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 70,
                    color:
                        Colors.deepPurple,
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  const Text(
                    'Build Your Financial Safety Net',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Plan enough savings to cover your essential expenses during unexpected situations.',
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  buildNumberField(
                    label:
                        'Monthly Essential Expenses',
                    icon:
                        Icons.receipt_long,
                    controller:
                        expensesController,
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  const Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      'Select Target Duration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        targetMonths.map(
                      (months) {
                        return ChoiceChip(
                          label: Text(
                            '$months Months',
                          ),
                          selected:
                              selectedTargetMonths ==
                                  months,
                          onSelected:
                              (selected) {
                            if (selected) {
                              setState(() {
                                selectedTargetMonths =
                                    months;
                              });
                            }
                          },
                        );
                      },
                    ).toList(),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  buildNumberField(
                    label:
                        'Current Emergency Fund',
                    icon: Icons.savings,
                    controller:
                        currentFundController,
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  Card(
                    elevation: 6,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Emergency Fund Summary',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          buildSummaryRow(
                            title:
                                'Monthly Essential Expenses',
                            amount:
                                monthlyEssentialExpenses,
                          ),

                          buildSummaryRow(
                            title:
                                '$selectedTargetMonths-Month Target',
                            amount:
                                targetAmount,
                          ),

                          buildSummaryRow(
                            title:
                                'Current Fund',
                            amount:
                                currentFund,
                          ),

                          if (!isTargetExceeded)
                            buildSummaryRow(
                              title:
                                  'Remaining Amount',
                              amount:
                                  remainingAmount,
                            ),

                          if (isTargetExceeded)
                            buildSummaryRow(
                              title:
                                  'Target Exceeded By',
                              amount:
                                  exceededAmount,
                              amountColor:
                                  Colors.green,
                            ),

                          const SizedBox(
                            height: 18,
                          ),

                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                            color:
                                getProgressColor(),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            getProgressText(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  getProgressColor(),
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Icon(
                                isTargetCompleted
                                    ? Icons.verified
                                    : Icons
                                        .info_outline,
                                color:
                                    getProgressColor(),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child: Text(
                                  getProgressMessage(),
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        getProgressColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : saveEmergencyFund,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.save,
                            ),
                      label: Text(
                        isSaving
                            ? 'Saving...'
                            : hasSavedFund
                                ? 'Update Emergency Fund'
                                : 'Save Emergency Fund',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
    );
  }
}