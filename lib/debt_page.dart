import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

@override
void initState() {
  super.initState();
  initializeDebtPage();
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

  double getDouble(
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

  int getInt(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime? getDate(
    Map<String, dynamic> data,
    String key,
  ) {
    return DateTime.tryParse(
      data[key]?.toString() ?? '',
    );
  }

  List<Map<String, dynamic>> getPaymentHistory(
    Map<String, dynamic> debt,
  ) {
    final rawHistory = debt['paymentHistory'];

    if (rawHistory is! List) {
      return [];
    }

    return rawHistory
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Not Available';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  double get totalOriginalDebt {
    return debts.fold<double>(
      0,
      (total, debt) =>
          total + getDouble(debt, 'totalAmount'),
    );
  }

  double get totalRemainingDebt {
    return debts.fold<double>(
      0,
      (total, debt) =>
          total +
          getDouble(debt, 'remainingBalance'),
    );
  }

  double get totalMonthlyEmi {
    return debts
        .where(
          (debt) =>
              getDouble(
                debt,
                'remainingBalance',
              ) >
              0,
        )
        .fold<double>(
          0,
          (total, debt) =>
              total +
              getDouble(debt, 'monthlyEmi'),
        );
  }

  double get totalRepaid {
    return totalOriginalDebt - totalRemainingDebt;
  }

  double get overallProgress {
    if (totalOriginalDebt <= 0) {
      return 0;
    }

    return (totalRepaid / totalOriginalDebt)
        .clamp(0.0, 1.0);
  }

  int get totalRemainingEmis {
    return debts.fold<int>(
      0,
      (total, debt) =>
          total + getInt(debt, 'remainingEmis'),
    );
  }

  Future<void> showPremiumDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Colors.amber,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Premium Feature'),
              ),
            ],
          ),
          content: const Text(
            'Free plan supports up to 3 loans. Upgrade to Premium to track unlimited loans.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PremiumPage(),
                  ),
                );

                if (!mounted) return;

                isPremium =
                    await SubscriptionService.isPremium();

                setState(() {});
              },
              icon: const Icon(
                Icons.workspace_premium,
              ),
              label: const Text(
                'Upgrade to Premium',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> tryOpenDebtForm({
    Map<String, dynamic>? existingDebt,
  }) async {
    if (existingDebt != null) {
      await openDebtForm(existingDebt: existingDebt);
      return;
    }

    final canAddDebt =
        await SubscriptionService.canAddDebt(
      debts.length,
    );

    if (!mounted) return;

    if (!canAddDebt) {
      await showPremiumDialog();
      return;
    }

    await openDebtForm();
  }

  Future<void> openDebtForm({
    Map<String, dynamic>? existingDebt,
  }) async {
    final loanNameController =
        TextEditingController(
      text:
          existingDebt?['loanName']?.toString() ?? '',
    );

    final totalAmountController =
        TextEditingController(
      text: existingDebt == null
          ? ''
          : getDouble(
              existingDebt,
              'totalAmount',
            ).toStringAsFixed(0),
    );

    final remainingBalanceController =
        TextEditingController(
      text: existingDebt == null
          ? ''
          : getDouble(
              existingDebt,
              'remainingBalance',
            ).toStringAsFixed(0),
    );

    final monthlyEmiController =
        TextEditingController(
      text: existingDebt == null
          ? ''
          : getDouble(
              existingDebt,
              'monthlyEmi',
            ).toStringAsFixed(0),
    );

    final interestRateController =
        TextEditingController(
      text: existingDebt == null
          ? ''
          : getDouble(
              existingDebt,
              'interestRate',
            ).toString(),
    );

    final totalEmisController =
        TextEditingController(
      text: existingDebt == null
          ? ''
          : getInt(
              existingDebt,
              'totalEmis',
            ).toString(),
    );

    final paidEmisController =
        TextEditingController(
      text: existingDebt == null
          ? '0'
          : getInt(
              existingDebt,
              'paidEmis',
            ).toString(),
    );

    DateTime loanStartDate =
        getDate(
          existingDebt ?? {},
          'loanStartDate',
        ) ??
        DateTime.now();

    DateTime nextDueDate =
        getDate(
          existingDebt ?? {},
          'nextDueDate',
        ) ??
        DateTime.now().add(
          const Duration(days: 30),
        );

    final bool? saved =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            Future<void> selectLoanStartDate()
                async {
              final selectedDate =
                  await showDatePicker(
                context: dialogContext,
                initialDate: loanStartDate,
                firstDate: DateTime(1950),
                lastDate: DateTime(2100),
              );

              if (selectedDate != null) {
                setDialogState(() {
                  loanStartDate = selectedDate;
                });
              }
            }

            Future<void> selectNextDueDate()
                async {
              final selectedDate =
                  await showDatePicker(
                context: dialogContext,
                initialDate: nextDueDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (selectedDate != null) {
                setDialogState(() {
                  nextDueDate = selectedDate;
                });
              }
            }

            return AlertDialog(
              title: Text(
                existingDebt == null
                    ? 'Add Smart EMI Loan'
                    : 'Edit Loan',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      TextField(
                        controller:
                            loanNameController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Loan Name',
                          hintText:
                              'Example: Bike Loan',
                          prefixIcon: Icon(
                            Icons.account_balance,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      buildDialogNumberField(
                        controller:
                            totalAmountController,
                        label:
                            'Total Loan Amount',
                        icon:
                            Icons.currency_rupee,
                      ),

                      const SizedBox(height: 15),

                      buildDialogNumberField(
                        controller:
                            remainingBalanceController,
                        label:
                            'Current Remaining Balance',
                        icon: Icons
                            .account_balance_wallet_outlined,
                      ),

                      const SizedBox(height: 15),

                      buildDialogNumberField(
                        controller:
                            monthlyEmiController,
                        label: 'Monthly EMI',
                        icon:
                            Icons.calendar_month,
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller:
                            interestRateController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .allow(
                            RegExp(
                              r'^\d*\.?\d{0,2}',
                            ),
                          ),
                        ],
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Interest Rate',
                          suffixText: '%',
                          prefixIcon:
                              Icon(Icons.percent),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      buildDialogIntegerField(
                        controller:
                            totalEmisController,
                        label:
                            'Total Loan EMIs',
                        icon:
                            Icons.format_list_numbered,
                      ),

                      const SizedBox(height: 15),

                      buildDialogIntegerField(
                        controller:
                            paidEmisController,
                        label:
                            'Already Paid EMIs',
                        icon: Icons
                            .check_circle_outline,
                      ),

                      const SizedBox(height: 15),

                      ListTile(
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            4,
                          ),
                        ),
                        leading: const Icon(
                          Icons.event_available,
                        ),
                        title: const Text(
                          'Loan Start Date',
                        ),
                        subtitle: Text(
                          formatDate(
                            loanStartDate,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.calendar_month,
                        ),
                        onTap:
                            selectLoanStartDate,
                      ),

                      const SizedBox(height: 15),

                      ListTile(
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            4,
                          ),
                        ),
                        leading: const Icon(
                          Icons.notifications_active,
                        ),
                        title: const Text(
                          'Next EMI Due Date',
                        ),
                        subtitle: Text(
                          formatDate(
                            nextDueDate,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.calendar_month,
                        ),
                        onTap: selectNextDueDate,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final loanName =
                        loanNameController.text
                            .trim();

                    final totalAmount =
                        double.tryParse(
                              totalAmountController
                                  .text,
                            ) ??
                            0;

                    final remainingBalance =
                        double.tryParse(
                              remainingBalanceController
                                  .text,
                            ) ??
                            0;

                    final monthlyEmi =
                        double.tryParse(
                              monthlyEmiController
                                  .text,
                            ) ??
                            0;

                    final interestRate =
                        double.tryParse(
                              interestRateController
                                  .text,
                            ) ??
                            0;

                    final totalEmis =
                        int.tryParse(
                              totalEmisController
                                  .text,
                            ) ??
                            0;

                    final paidEmis =
                        int.tryParse(
                              paidEmisController
                                  .text,
                            ) ??
                            0;

                    if (loanName.isEmpty ||
                        totalAmount <= 0 ||
                        remainingBalance < 0 ||
                        monthlyEmi <= 0 ||
                        totalEmis <= 0 ||
                        paidEmis < 0) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter valid loan details',
                          ),
                        ),
                      );

                      return;
                    }

                    if (remainingBalance >
                        totalAmount) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Remaining balance cannot exceed total loan amount',
                          ),
                        ),
                      );

                      return;
                    }

                    if (paidEmis > totalEmis) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Paid EMIs cannot exceed total EMIs',
                          ),
                        ),
                      );

                      return;
                    }

                    final remainingEmis =
                        totalEmis - paidEmis;

                    if (remainingEmis > 0 &&
                        remainingBalance <= 0) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Remaining balance must be greater than ₹0 when EMIs are still remaining',
                          ),
                        ),
                      );

                      return;
                    }

                    if (paidEmis == totalEmis &&
                        remainingBalance != 0) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Remaining balance must be ₹0 when all EMIs are paid',
                          ),
                        ),
                      );

                      return;
                    }

                    if (existingDebt == null) {
                      await DebtService.saveDebt(
                        loanName: loanName,
                        totalAmount: totalAmount,
                        remainingBalance:
                            remainingBalance,
                        monthlyEmi: monthlyEmi,
                        interestRate:
                            interestRate,
                        totalEmis: totalEmis,
                        paidEmis: paidEmis,
                        loanStartDate:
                            loanStartDate,
                        nextDueDate:
                            nextDueDate,
                      );
                    } else {
                      await DebtService.updateDebt(
                        id: existingDebt['id']
                            .toString(),
                        loanName: loanName,
                        totalAmount: totalAmount,
                        remainingBalance:
                            remainingBalance,
                        monthlyEmi: monthlyEmi,
                        interestRate:
                            interestRate,
                        totalEmis: totalEmis,
                        paidEmis: paidEmis,
                        loanStartDate:
                            loanStartDate,
                        nextDueDate:
                            nextDueDate,
                      );
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child: Text(
                    existingDebt == null
                        ? 'Add Loan'
                        : 'Update',
                  ),
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

    if (saved == true) {
      await loadDebts();
    }
  }

  Widget buildDialogNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget buildDialogIntegerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
        border: const OutlineInputBorder(),
      ),
    );
  }

  String getDueStatus(
    Map<String, dynamic> debt,
  ) {
    final remainingBalance =
        getDouble(
      debt,
      'remainingBalance',
    );

    final remainingEmis =
        getInt(
      debt,
      'remainingEmis',
    );

    if (remainingBalance <= 0 ||
        remainingEmis <= 0) {
      return 'Completed';
    }

    final nextDueDate =
        getDate(debt, 'nextDueDate');

    if (nextDueDate == null) {
      return 'Due Date Missing';
    }

    final today = DateTime.now();

    final currentDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final dueDate = DateTime(
      nextDueDate.year,
      nextDueDate.month,
      nextDueDate.day,
    );

    final difference =
        dueDate.difference(currentDate).inDays;

    if (difference < 0) {
      return 'Overdue';
    }

    if (difference == 0) {
      return 'Due Today';
    }

    if (difference <= 3) {
      return 'Due Soon';
    }

    return 'Upcoming';
  }

  Color getDueStatusColor(
    String status,
  ) {
    switch (status) {
      case 'Completed':
        return Colors.green;

      case 'Overdue':
        return Colors.red;

      case 'Due Today':
        return Colors.deepOrange;

      case 'Due Soon':
        return Colors.orange;

      default:
        return Colors.blue;
    }
  }

  Future<void> markEmiPaid(
    Map<String, dynamic> debt,
  ) async {
    final monthlyEmi =
        getDouble(debt, 'monthlyEmi');

    final shouldPay =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm EMI Payment',
          ),
          content: Text(
            'Mark EMI of ₹${monthlyEmi.toStringAsFixed(0)} for ${debt['loanName']} as paid?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Mark as Paid',
              ),
            ),
          ],
        );
      },
    );

    if (shouldPay != true) return;

    setState(() {
      isProcessing = true;
    });

    await DebtService.markEmiAsPaid(
      id: debt['id'].toString(),
    );

    await loadDebts();

    if (!mounted) return;

    setState(() {
      isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'EMI marked as paid successfully',
        ),
      ),
    );
  }

  Future<void> undoLastPayment(
    Map<String, dynamic> debt,
  ) async {
    final shouldUndo =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Undo Last Payment',
          ),
          content: const Text(
            'This will restore the last EMI payment and remaining balance.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Undo'),
            ),
          ],
        );
      },
    );

    if (shouldUndo != true) return;

    await DebtService.undoLastEmiPayment(
      id: debt['id'].toString(),
    );

    await loadDebts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Last EMI payment restored',
        ),
      ),
    );
  }

  void showPaymentHistory(
    Map<String, dynamic> debt,
  ) {
    final history = getPaymentHistory(debt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.7,
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${debt['loanName']} Payment History',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (history.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No EMI payments recorded yet',
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: history.length,
                        separatorBuilder:
                            (context, index) =>
                                const Divider(),
                        itemBuilder:
                            (context, index) {
                          final payment =
                              history[index];

                          final amount =
                              getDouble(
                            payment,
                            'amount',
                          );

                          final paidDate =
                              getDate(
                            payment,
                            'paidDate',
                          );

                          final dueDate =
                              getDate(
                            payment,
                            'dueDate',
                          );

                          final emiNumber =
                              getInt(
                            payment,
                            'emiNumber',
                          );

                          return ListTile(
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons.check,
                              ),
                            ),
                            title: Text(
                              'EMI #$emiNumber - ₹${amount.toStringAsFixed(0)}',
                            ),
                            subtitle: Text(
                              'Paid: ${formatDate(paidDate)}\n'
                              'Due: ${formatDate(dueDate)}',
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ),

                  if (history.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(
                            sheetContext,
                          );

                          await undoLastPayment(
                            debt,
                          );
                        },
                        icon: const Icon(
                          Icons.undo,
                        ),
                        label: const Text(
                          'Undo Last Payment',
                        ),
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

  Future<void> deleteDebt(
    Map<String, dynamic> debt,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Loan'),
          content: Text(
            'Delete ${debt['loanName']} and its payment history?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
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

    await DebtService.deleteDebt(
      debt['id'].toString(),
    );

    await loadDebts();
  }

  Widget buildDebtCard(
    Map<String, dynamic> debt,
  ) {
    final totalAmount =
        getDouble(debt, 'totalAmount');

    final remainingBalance =
        getDouble(debt, 'remainingBalance');

    final monthlyEmi =
        getDouble(debt, 'monthlyEmi');

    final interestRate =
        getDouble(debt, 'interestRate');

    final totalEmis =
        getInt(debt, 'totalEmis');

    final paidEmis =
        getInt(debt, 'paidEmis');

    final remainingEmis =
        getInt(debt, 'remainingEmis');

    final nextDueDate =
        getDate(debt, 'nextDueDate');

    final paymentHistory =
        getPaymentHistory(debt);

    final repaid =
        totalAmount - remainingBalance;

    final progress = totalAmount > 0
        ? (repaid / totalAmount)
            .clamp(0.0, 1.0)
        : 0.0;

    final status = getDueStatus(debt);

    final statusColor =
        getDueStatusColor(status);

    final isCompleted =
        remainingBalance <= 0 ||
        remainingEmis <= 0;

    return Card(
      elevation: 5,
      margin:
          const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    isCompleted
                        ? Icons.check
                        : Icons.credit_card,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt['loanName'].toString(),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor
                              .withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      tryOpenDebtForm(
                        existingDebt: debt,
                      );
                    }

                    if (value == 'history') {
                      showPaymentHistory(debt);
                    }

                    if (value == 'delete') {
                      deleteDebt(debt);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Loan'),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child:
                          Text('Payment History'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Loan'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              borderRadius:
                  BorderRadius.circular(10),
            ),

            const SizedBox(height: 8),

            Text(
              '${(progress * 100).toStringAsFixed(0)}% repaid',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(height: 30),

            buildDebtRow(
              title: 'Original Loan',
              value:
                  '₹${totalAmount.toStringAsFixed(0)}',
            ),

            buildDebtRow(
              title: 'Remaining Balance',
              value:
                  '₹${remainingBalance.toStringAsFixed(0)}',
            ),

            buildDebtRow(
              title: 'Monthly EMI',
              value:
                  '₹${monthlyEmi.toStringAsFixed(0)}',
            ),

            buildDebtRow(
              title: 'Interest Rate',
              value:
                  '${interestRate.toStringAsFixed(2)}%',
            ),

            const Divider(height: 25),

            Row(
              children: [
                buildEmiCount(
                  title: 'Total',
                  value: totalEmis,
                ),
                buildEmiCount(
                  title: 'Paid',
                  value: paidEmis,
                ),
                buildEmiCount(
                  title: 'Remaining',
                  value: remainingEmis,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: statusColor,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next EMI Due',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Text(
                          isCompleted
                              ? 'Loan Completed'
                              : formatDate(
                                  nextDueDate,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            if (!isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () {
                          markEmiPaid(debt);
                        },
                  icon: const Icon(
                    Icons.check_circle,
                  ),
                  label: Text(
                    'Mark EMI ₹${monthlyEmi.toStringAsFixed(0)} as Paid',
                  ),
                ),
              ),

            if (paymentHistory.isNotEmpty) ...[
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    showPaymentHistory(debt);
                  },
                  icon:
                      const Icon(Icons.history),
                  label: Text(
                    'View Payment History (${paymentHistory.length})',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildEmiCount({
    required String title,
    required int value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget buildDebtRow({
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
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
          'Smart Debt & EMI Tracker',
        ),
        centerTitle: true,
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          tryOpenDebtForm();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadDebts,
              child: debts.isEmpty
                  ? ListView(
                      padding:
                          const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 100),
                        const Icon(
                          Icons
                              .account_balance_outlined,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Loans Added',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Add your first loan to track EMIs, due dates, remaining balance and payment history.',
                          textAlign:
                              TextAlign.center,
                        ),
                        const SizedBox(height: 25),
                        ElevatedButton.icon(
                          onPressed: () {
                            tryOpenDebtForm();
                          },
                          icon:
                              const Icon(Icons.add),
                          label: const Text(
                            'Add Your First Loan',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding:
                          const EdgeInsets.all(16),
                      children: [
                        Card(
                          elevation: 7,
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              20,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Debt Overview',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  children: [
                                    buildSummaryItem(
                                      title:
                                          'Remaining',
                                      value:
                                          '₹${totalRemainingDebt.toStringAsFixed(0)}',
                                      icon: Icons
                                          .account_balance_wallet_outlined,
                                    ),
                                    buildSummaryItem(
                                      title:
                                          'Monthly EMI',
                                      value:
                                          '₹${totalMonthlyEmi.toStringAsFixed(0)}',
                                      icon: Icons
                                          .calendar_month,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  children: [
                                    buildSummaryItem(
                                      title:
                                          'Remaining EMIs',
                                      value:
                                          '$totalRemainingEmis',
                                      icon: Icons
                                          .format_list_numbered,
                                    ),
                                    buildSummaryItem(
                                      title:
                                          'Active Loans',
                                      value:
                                          '${debts.where((debt) => getDouble(debt, 'remainingBalance') > 0).length}',
                                      icon: Icons
                                          .credit_card,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                LinearProgressIndicator(
                                  value:
                                      overallProgress,
                                  minHeight: 12,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  '${(overallProgress * 100).toStringAsFixed(0)}% of total debt repaid',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          'Your Loans (${debts.length})',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...debts.map(buildDebtCard),
                        const SizedBox(height: 90),
                      ],
                    ),
            ),
    );
  }
}