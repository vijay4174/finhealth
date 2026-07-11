import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'emergency_fund_service.dart';
import 'goal_service.dart';
import 'wallet_service.dart';

class SavingsWalletPage extends StatefulWidget {
  const SavingsWalletPage({super.key});

  @override
  State<SavingsWalletPage> createState() =>
      _SavingsWalletPageState();
}

class _SavingsWalletPageState
    extends State<SavingsWalletPage> {
  bool isLoading = true;

  double walletBalance = 0;
  double totalAdded = 0;
  double totalAllocated = 0;

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> goals = [];

  Map<String, dynamic>? emergencyFund;

  @override
  void initState() {
    super.initState();
    loadWallet();
  }

  Future<void> loadWallet() async {
    final savedTransactions =
        await WalletService.getTransactions();

    final balance =
        await WalletService.getWalletBalance();

    final added =
        await WalletService.getTotalAddedMoney();

    final allocated =
        await WalletService.getTotalAllocatedMoney();

    final savedGoals =
        await GoalService.getGoals();

    final savedEmergencyFund =
        await EmergencyFundService.getEmergencyFund();

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

  double getDoubleValue(
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

  int getIntValue(
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

  List<Map<String, dynamic>>
      get incompleteGoals {
    return goals.where((goal) {
      final double targetAmount =
          getDoubleValue(
        goal,
        'targetAmount',
      );

      final double savedAmount =
          getDoubleValue(
        goal,
        'savedAmount',
      );

      return targetAmount > 0 &&
          savedAmount < targetAmount;
    }).toList();
  }

  double get emergencyFundTarget {
    if (emergencyFund == null) {
      return 0;
    }

    final double monthlyExpenses =
        getDoubleValue(
      emergencyFund!,
      'monthlyEssentialExpenses',
    );

    final int targetMonths =
        getIntValue(
      emergencyFund!,
      'targetMonths',
    );

    return monthlyExpenses * targetMonths;
  }

  double get emergencyFundCurrent {
    if (emergencyFund == null) {
      return 0;
    }

    return getDoubleValue(
      emergencyFund!,
      'currentFund',
    );
  }

  double get emergencyFundRemaining {
    final double remaining =
        emergencyFundTarget -
            emergencyFundCurrent;

    return remaining > 0 ? remaining : 0;
  }

  bool get hasIncompleteEmergencyFund {
    return emergencyFund != null &&
        emergencyFundTarget > 0 &&
        emergencyFundCurrent <
            emergencyFundTarget;
  }

  Future<void> showAddMoneyDialog() async {
    final amountController =
        TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add Money',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'For now, this is a manual test transaction. Real UPI payment will be connected next.',
              ),

              const SizedBox(height: 18),

              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType:
                    TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                ],
                decoration:
                    const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixIcon: Icon(
                    Icons.currency_rupee,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final double amount =
                    double.tryParse(
                          amountController.text
                              .trim(),
                        ) ??
                        0;

                if (amount <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter an amount greater than 0',
                      ),
                    ),
                  );

                  return;
                }

                await WalletService.addMoney(
                  amount: amount,
                  paymentMethod: 'Manual Test',
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                await loadWallet();

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      '₹${amount.toStringAsFixed(0)} added successfully',
                    ),
                  ),
                );
              },
              child: const Text(
                'Add Money',
              ),
            ),
          ],
        );
      },
    );

    amountController.dispose();
  }

  Future<void>
      showAllocateMoneyDialog() async {
    if (walletBalance <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Add money to your wallet before allocating',
          ),
        ),
      );

      return;
    }

    String selectedDestination =
        'General Savings';

    Map<String, dynamic>? selectedGoal;

    final amountController =
        TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final double? goalTarget =
                selectedGoal == null
                    ? null
                    : getDoubleValue(
                        selectedGoal!,
                        'targetAmount',
                      );

            final double? goalSaved =
                selectedGoal == null
                    ? null
                    : getDoubleValue(
                        selectedGoal!,
                        'savedAmount',
                      );

            final double? goalRemaining =
                goalTarget == null ||
                        goalSaved == null
                    ? null
                    : goalTarget -
                        goalSaved;

            return AlertDialog(
              title: const Text(
                'Allocate Money',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      size: 50,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Available Balance: ₹${walletBalance.toStringAsFixed(0)}',
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          selectedDestination,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Allocate To',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value:
                              'General Savings',
                          child: Text(
                            'General Savings',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'Financial Goal',
                          child: Text(
                            'Financial Goal',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'Emergency Fund',
                          child: Text(
                            'Emergency Fund',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDestination =
                              value;

                          selectedGoal = null;

                          amountController
                              .clear();
                        });
                      },
                    ),

                    if (selectedDestination ==
                        'Financial Goal') ...[
                      const SizedBox(
                        height: 15,
                      ),

                      if (incompleteGoals
                          .isEmpty)
                        const Card(
                          child: Padding(
                            padding:
                                EdgeInsets.all(
                              16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .info_outline,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    'No incomplete financial goals available.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              selectedGoal?[
                                      'id']
                                  ?.toString(),
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Select Goal',
                            border:
                                OutlineInputBorder(),
                          ),
                          items:
                              incompleteGoals
                                  .map(
                            (goal) {
                              final double
                                  targetAmount =
                                  getDoubleValue(
                                goal,
                                'targetAmount',
                              );

                              final double
                                  savedAmount =
                                  getDoubleValue(
                                goal,
                                'savedAmount',
                              );

                              final double
                                  remaining =
                                  targetAmount -
                                      savedAmount;

                              return DropdownMenuItem<
                                  String>(
                                value:
                                    goal['id']
                                        .toString(),
                                child: Text(
                                  '${goal['goalName']} - ₹${remaining.toStringAsFixed(0)} left',
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setDialogState(
                              () {
                                selectedGoal =
                                    incompleteGoals
                                        .firstWhere(
                                  (goal) =>
                                      goal['id']
                                          .toString() ==
                                      value,
                                );

                                amountController
                                    .clear();
                              },
                            );
                          },
                        ),

                      if (selectedGoal !=
                          null) ...[
                        const SizedBox(
                          height: 12,
                        ),

                        Card(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(
                              14,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  selectedGoal![
                                          'goalName']
                                      .toString(),
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  'Saved: ₹${goalSaved!.toStringAsFixed(0)}',
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Remaining: ₹${goalRemaining!.toStringAsFixed(0)}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],

                    if (selectedDestination ==
                        'Emergency Fund') ...[
                      const SizedBox(
                        height: 15,
                      ),

                      if (emergencyFund == null)
                        const Card(
                          child: Padding(
                            padding:
                                EdgeInsets.all(
                              16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .info_outline,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    'Create an emergency fund plan before allocating money.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (!hasIncompleteEmergencyFund)
                        const Card(
                          child: Padding(
                            padding:
                                EdgeInsets.all(
                              16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .verified,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    'Your emergency fund target is already completed.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(
                              14,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Emergency Fund',
                                  style:
                                      TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                Text(
                                  'Current Fund: ₹${emergencyFundCurrent.toStringAsFixed(0)}',
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Target: ₹${emergencyFundTarget.toStringAsFixed(0)}',
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Remaining: ₹${emergencyFundRemaining.toStringAsFixed(0)}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 18),

                    TextField(
                      controller:
                          amountController,
                      keyboardType:
                          TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                      ],
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Allocation Amount',
                        prefixText: '₹ ',
                        prefixIcon: Icon(
                          Icons.savings,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final double amount =
                        double.tryParse(
                              amountController
                                  .text
                                  .trim(),
                            ) ??
                            0;

                    if (amount <= 0) {
                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter an amount greater than 0',
                          ),
                        ),
                      );

                      return;
                    }

                    final double
                        currentBalance =
                        await WalletService
                            .getWalletBalance();

                    if (amount >
                        currentBalance) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Insufficient balance. Available balance is ₹${currentBalance.toStringAsFixed(0)}',
                          ),
                        ),
                      );

                      return;
                    }

                    String destinationName =
                        'General Savings';

                    if (selectedDestination ==
                        'Financial Goal') {
                      if (selectedGoal ==
                          null) {
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a financial goal',
                            ),
                          ),
                        );

                        return;
                      }

                      final double
                          targetAmount =
                          getDoubleValue(
                        selectedGoal!,
                        'targetAmount',
                      );

                      final double
                          savedAmount =
                          getDoubleValue(
                        selectedGoal!,
                        'savedAmount',
                      );

                      final double
                          remainingAmount =
                          targetAmount -
                              savedAmount;

                      if (remainingAmount <=
                          0) {
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This goal is already completed',
                            ),
                          ),
                        );

                        return;
                      }

                      if (amount >
                          remainingAmount) {
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You can allocate only up to ₹${remainingAmount.toStringAsFixed(0)} to this goal',
                            ),
                          ),
                        );

                        return;
                      }

                      destinationName =
                          selectedGoal![
                                  'goalName']
                              .toString();

                      try {
                        await WalletService.allocateToGoalSafely(
  amount: amount,
  goalId: selectedGoal!['id'].toString(),
);
                      } catch (error) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString(),
                            ),
                          ),
                        );

                        return;
                      }
                    } else if (selectedDestination ==
                        'Emergency Fund') {
                      if (emergencyFund ==
                          null) {
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Create an emergency fund plan first',
                            ),
                          ),
                        );

                        return;
                      }

                      if (!hasIncompleteEmergencyFund) {
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Emergency fund target is already completed',
                            ),
                          ),
                        );

                        return;
                      }

                      if (amount >
                          emergencyFundRemaining) {
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You can allocate only up to ₹${emergencyFundRemaining.toStringAsFixed(0)} to the emergency fund',
                            ),
                          ),
                        );

                        return;
                      }

                      destinationName =
                          'Emergency Fund';

                      try {
                        await WalletService
    .allocateToEmergencyFundSafely(
  amount: amount,
);
                      } catch (error) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString(),
                            ),
                          ),
                        );

                        return;
                      }
                    } else {
                      try {
                        await WalletService
                            .allocateMoney(
                          amount: amount,
                          destination:
                              'General Savings',
                        );
                      } catch (error) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString(),
                            ),
                          ),
                        );

                        return;
                      }
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                    );

                    await loadWallet();

                    if (!mounted) return;

                    ScaffoldMessenger.of(
                      this.context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          '₹${amount.toStringAsFixed(0)} allocated to $destinationName',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Allocate',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  String formatDate(
    String? dateText,
  ) {
    final date = DateTime.tryParse(
      dateText ?? '',
    );

    if (date == null) {
      return '';
    }

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    return '${date.day}/${date.month}/${date.year}  $hour:$minute $period';
  }

  IconData getTransactionIcon(
    Map<String, dynamic> transaction,
  ) {
    final type =
        transaction['type']?.toString();

    if (type == 'credit') {
      return Icons.add_circle_outline;
    }

    final destination =
        transaction['destination']
            ?.toString();

    if (destination ==
        'General Savings') {
      return Icons.savings_outlined;
    }

    if (destination ==
        'Emergency Fund') {
      return Icons.shield_outlined;
    }

    return Icons.flag_outlined;
  }

  Color getTransactionColor(
    Map<String, dynamic> transaction,
  ) {
    final type =
        transaction['type']?.toString();

    if (type == 'credit') {
      return Colors.green;
    }

    return Colors.orange;
  }

  String getTransactionTitle(
    Map<String, dynamic> transaction,
  ) {
    final type =
        transaction['type']?.toString();

    if (type == 'credit') {
      return 'Money Added';
    }

    return 'Money Allocated';
  }

  String getTransactionSubtitle(
    Map<String, dynamic> transaction,
  ) {
    final type =
        transaction['type']?.toString();

    if (type == 'credit') {
      return transaction['paymentMethod']
              ?.toString() ??
          'Wallet';
    }

    return transaction['destination']
            ?.toString() ??
        'Allocation';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Savings Wallet',
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadWallet,
              child: ListView(
                padding:
                    const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 8,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            child: Icon(
                              Icons
                                  .account_balance_wallet,
                              size: 34,
                            ),
                          ),

                          const SizedBox(height: 15),

                          const Text(
                            'Available Balance',
                            style: TextStyle(
                              fontSize: 17,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '₹${walletBalance.toStringAsFixed(0)}',
                            style:
                                const TextStyle(
                              fontSize: 40,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child:
                                    ElevatedButton.icon(
                                  onPressed:
                                      showAddMoneyDialog,
                                  icon: const Icon(
                                    Icons.add,
                                  ),
                                  label: const Text(
                                    'Add Money',
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child:
                                    OutlinedButton.icon(
                                  onPressed:
                                      showAllocateMoneyDialog,
                                  icon: const Icon(
                                    Icons
                                        .north_east,
                                  ),
                                  label: const Text(
                                    'Allocate',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryCard(
                          title: 'Total Added',
                          amount: totalAdded,
                          icon:
                              Icons.south_west,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: buildSummaryCard(
                          title:
                              'Total Allocated',
                          amount:
                              totalAllocated,
                          icon:
                              Icons.north_east,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (transactions.isEmpty)
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          30,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons
                                  .receipt_long_outlined,
                              size: 55,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            const Text(
                              'No Transactions Yet',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            const Text(
                              'Add money to start your savings wallet.',
                              textAlign:
                                  TextAlign.center,
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            OutlinedButton.icon(
                              onPressed:
                                  showAddMoneyDialog,
                              icon: const Icon(
                                Icons.add,
                              ),
                              label: const Text(
                                'Add First Amount',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...transactions.map(
                      buildTransactionCard,
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              '₹${amount.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTransactionCard(
    Map<String, dynamic> transaction,
  ) {
    final double amount =
        (transaction['amount'] as num?)
                ?.toDouble() ??
            0;

    final bool isCredit =
        transaction['type'] == 'credit';

    final color =
        getTransactionColor(transaction);

    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            getTransactionIcon(
              transaction,
            ),
          ),
        ),
        title: Text(
          getTransactionTitle(
            transaction,
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${getTransactionSubtitle(transaction)}\n${formatDate(transaction['createdAt']?.toString())}',
        ),
        isThreeLine: true,
        trailing: Text(
          '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}