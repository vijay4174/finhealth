import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'results_page.dart';

class FinancialDetailsPage extends StatefulWidget {
  const FinancialDetailsPage({super.key});

  @override
  State<FinancialDetailsPage> createState() =>
      _FinancialDetailsPageState();
}

class _FinancialDetailsPageState
    extends State<FinancialDetailsPage> {
  final TextEditingController incomeController =
      TextEditingController();

  final TextEditingController fundingController =
      TextEditingController();

  final TextEditingController expensesController =
      TextEditingController();

  final TextEditingController savingsController =
      TextEditingController();

  final TextEditingController fdController =
      TextEditingController();

  final TextEditingController rdController =
      TextEditingController();

  final TextEditingController sipController =
      TextEditingController();

  final TextEditingController mfController =
      TextEditingController();

  bool healthInsurance = false;
  bool termInsurance = false;

  String fundingSource = 'None';

  final List<String> fundingSources = const [
    'None',
    'Family Support',
    'Scholarship',
    'Past Savings',
    'Other',
  ];

  double getValue(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  Widget buildNumberField({
    required String label,
    required TextEditingController controller,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixText: '₹ ',
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  void dispose() {
    incomeController.dispose();
    fundingController.dispose();
    expensesController.dispose();
    savingsController.dispose();
    fdController.dispose();
    rdController.dispose();
    sipController.dispose();
    mfController.dispose();

    super.dispose();
  }

  void calculateScore() {
    final double income =
        getValue(incomeController);

    final double otherFunding =
        getValue(fundingController);

    final double expenses =
        getValue(expensesController);

    final double savings =
        getValue(savingsController);

    final double fd =
        getValue(fdController);

    final double rd =
        getValue(rdController);

    final double sip =
        getValue(sipController);

    final double mf =
        getValue(mfController);

    if (income <= 0 && otherFunding <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter monthly income or another source of monthly funding.',
          ),
        ),
      );
      return;
    }

    if (otherFunding > 0 &&
        fundingSource == 'None') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your funding source.',
          ),
        ),
      );
      return;
    }

    final double investments =
        fd + rd + sip + mf;

    final double availableMoney =
        income + otherFunding;

    final double totalAllocated =
        expenses + savings + investments;

    final double balance =
        availableMoney - totalAllocated;

    if (totalAllocated > availableMoney) {
      final double excess =
          totalAllocated - availableMoney;

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.red,
            ),
            title: const Text(
              'Financial Tally Mismatch',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildTallyRow(
                  'Available Money',
                  availableMoney,
                ),
                buildTallyRow(
                  'Total Allocated',
                  totalAllocated,
                ),
                const Divider(),
                buildTallyRow(
                  'Exceeded By',
                  excess,
                  isWarning: true,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your expenses, savings and investments cannot exceed your available money. Please correct the amounts.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Correct Amounts'),
              ),
            ],
          );
        },
      );

      return;
    }

    final double expenseRatio =
        (expenses / availableMoney) * 100;

    final double savingsRate =
        (savings / availableMoney) * 100;

    final double investmentRate =
        (investments / availableMoney) * 100;

    int score = 0;

    // EXPENSE MANAGEMENT - MAX 30 POINTS

    if (expenseRatio <= 50) {
      score += 30;
    } else if (expenseRatio <= 60) {
      score += 25;
    } else if (expenseRatio <= 70) {
      score += 20;
    } else if (expenseRatio <= 80) {
      score += 10;
    }

    // SAVINGS RATE - MAX 25 POINTS

    if (savingsRate >= 30) {
      score += 25;
    } else if (savingsRate >= 20) {
      score += 20;
    } else if (savingsRate >= 10) {
      score += 15;
    } else if (savingsRate > 0) {
      score += 5;
    }

    // INVESTMENT RATE - MAX 25 POINTS

    if (investmentRate >= 30) {
      score += 25;
    } else if (investmentRate >= 20) {
      score += 20;
    } else if (investmentRate >= 10) {
      score += 15;
    } else if (investmentRate > 0) {
      score += 5;
    }

    // INSURANCE PROTECTION - MAX 20 POINTS

    if (healthInsurance) {
      score += 10;
    }

    if (termInsurance) {
      score += 10;
    }

    if (score > 100) {
      score = 100;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsPage(
          score: score,
          income: availableMoney,
          expenses: expenses,
          savings: savings,
          investments: investments,
          healthInsurance: healthInsurance,
          termInsurance: termInsurance,
        ),
      ),
    );

    if (balance > 0) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '₹${balance.toStringAsFixed(0)} remains unallocated.',
              ),
            ),
          );
        },
      );
    }
  }

  Widget buildTallyRow(
    String title,
    double amount, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  isWarning ? Colors.red : null,
            ),
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
          'Financial Details',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildNumberField(
              label: 'Monthly Income',
              controller: incomeController,
              helperText:
                  'Enter 0 if you currently have no income',
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: fundingSource,
              decoration: const InputDecoration(
                labelText:
                    'Additional Funding Source',
                prefixIcon:
                    Icon(Icons.add_card_outlined),
                border: OutlineInputBorder(),
              ),
              items: fundingSources.map((source) {
                return DropdownMenuItem<String>(
                  value: source,
                  child: Text(source),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  fundingSource = value;

                  if (fundingSource == 'None') {
                    fundingController.clear();
                  }
                });
              },
            ),

            if (fundingSource != 'None') ...[
              const SizedBox(height: 15),

              buildNumberField(
                label: 'Monthly Funding Amount',
                controller: fundingController,
                helperText:
                    'Money available from $fundingSource',
              ),
            ],

            const SizedBox(height: 22),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Monthly Money Allocation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            buildNumberField(
              label: 'Monthly Expenses',
              controller: expensesController,
            ),

            const SizedBox(height: 15),

            buildNumberField(
              label: 'Monthly Savings',
              controller: savingsController,
            ),

            const SizedBox(height: 15),

            buildNumberField(
              label: 'FD Amount',
              controller: fdController,
            ),

            const SizedBox(height: 15),

            buildNumberField(
              label: 'RD Amount',
              controller: rdController,
            ),

            const SizedBox(height: 15),

            buildNumberField(
              label: 'Monthly SIP Amount',
              controller: sipController,
            ),

            const SizedBox(height: 15),

            buildNumberField(
              label: 'Mutual Fund Amount',
              controller: mfController,
            ),

            const SizedBox(height: 20),

            CheckboxListTile(
              title: const Text(
                'Health Insurance',
              ),
              subtitle: const Text(
                'Do you currently have health insurance?',
              ),
              value: healthInsurance,
              onChanged: (value) {
                setState(() {
                  healthInsurance =
                      value ?? false;
                });
              },
            ),

            CheckboxListTile(
              title: const Text(
                'Term Insurance',
              ),
              subtitle: const Text(
                'Do you currently have term insurance?',
              ),
              value: termInsurance,
              onChanged: (value) {
                setState(() {
                  termInsurance =
                      value ?? false;
                });
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: calculateScore,
                icon: const Icon(
                  Icons.calculate_outlined,
                ),
                label: const Text(
                  'Calculate Smart Score',
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}