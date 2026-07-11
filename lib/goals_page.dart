import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'goal_service.dart';
import 'premium_page.dart';
import 'subscription_service.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<Map<String, dynamic>> goals = [];
  bool isLoading = true;

  final List<String> goalTypes = [
    'Emergency Fund',
    'Laptop',
    'Bike',
    'Car',
    'Trip',
    'Education',
    'Marriage',
    'House',
    'Retirement',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    final savedGoals = await GoalService.getGoals();

    if (!mounted) return;

    setState(() {
      goals = savedGoals;
      isLoading = false;
    });
  }

  Future<void> tryCreateGoal() async {
    final canAdd = await SubscriptionService.canAddGoal(
      goals.length,
    );

    if (!mounted) return;

    if (canAdd) {
      await showGoalDialog();
      return;
    }

    await showGoalLimitDialog();
  }

  Future<void> showGoalLimitDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.workspace_premium,
            size: 45,
          ),
          title: const Text(
            'Free Goal Limit Reached',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Free users can create up to 3 financial goals. '
            'Upgrade to Premium to create unlimited goals.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Not Now'),
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

  IconData getGoalIcon(String goalName) {
    switch (goalName) {
      case 'Emergency Fund':
        return Icons.health_and_safety;

      case 'Laptop':
        return Icons.laptop;

      case 'Bike':
        return Icons.two_wheeler;

      case 'Car':
        return Icons.directions_car;

      case 'Trip':
        return Icons.flight_takeoff;

      case 'Education':
        return Icons.school;

      case 'Marriage':
        return Icons.favorite;

      case 'House':
        return Icons.home;

      case 'Retirement':
        return Icons.beach_access;

      default:
        return Icons.flag;
    }
  }

  Future<void> showGoalDialog({
    Map<String, dynamic>? existingGoal,
  }) async {
    String? selectedGoal = existingGoal?['goalName'];

    if (!goalTypes.contains(selectedGoal)) {
      selectedGoal = 'Other';
    }

    final targetController = TextEditingController(
      text: existingGoal == null
          ? ''
          : (existingGoal['targetAmount'] as num)
              .toStringAsFixed(0),
    );

    final savedController = TextEditingController(
      text: existingGoal == null
          ? ''
          : (existingGoal['savedAmount'] as num)
              .toStringAsFixed(0),
    );

    final bool isEditing = existingGoal != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Update Financial Goal'
                    : 'Create Financial Goal',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedGoal,
                      decoration: const InputDecoration(
                        labelText: 'Goal',
                        border: OutlineInputBorder(),
                      ),
                      items: goalTypes.map((goal) {
                        return DropdownMenuItem<String>(
                          value: goal,
                          child: Text(goal),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGoal = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Target Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: savedController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Saved Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
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
                    final double targetAmount =
                        double.tryParse(
                              targetController.text,
                            ) ??
                            0;

                    final double savedAmount =
                        double.tryParse(
                              savedController.text,
                            ) ??
                            0;

                    if (selectedGoal == null) {
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a goal',
                          ),
                        ),
                      );
                      return;
                    }

                    if (targetAmount <= 0) {
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Target amount must be greater than 0',
                          ),
                        ),
                      );
                      return;
                    }

                    if (savedAmount > targetAmount) {
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Saved amount cannot be greater than target amount',
                          ),
                        ),
                      );
                      return;
                    }

                    if (isEditing) {
                      await GoalService.updateGoal(
                        id: existingGoal['id'].toString(),
                        goalName: selectedGoal!,
                        targetAmount: targetAmount,
                        savedAmount: savedAmount,
                      );
                    } else {
                      await GoalService.addGoal(
                        goalName: selectedGoal!,
                        targetAmount: targetAmount,
                        savedAmount: savedAmount,
                      );
                    }

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    await loadGoals();
                  },
                  child: Text(
                    isEditing ? 'Update' : 'Create',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    targetController.dispose();
    savedController.dispose();
  }

  Future<void> deleteGoal(
    Map<String, dynamic> goal,
  ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: Text(
            'Are you sure you want to delete "${goal['goalName']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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

    await GoalService.deleteGoal(
      goal['id'].toString(),
    );

    await loadGoals();
  }

  double getTotalTarget() {
    return goals.fold<double>(
      0,
      (total, goal) =>
          total +
          (goal['targetAmount'] as num).toDouble(),
    );
  }

  double getTotalSaved() {
    return goals.fold<double>(
      0,
      (total, goal) =>
          total +
          (goal['savedAmount'] as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalTarget = getTotalTarget();
    final double totalSaved = getTotalSaved();

    final double overallProgress = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : goals.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 80,
                          color: Colors.deepPurple,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'No Financial Goals Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Create your first goal and start tracking your financial progress.',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 25),

                        ElevatedButton.icon(
                          onPressed: tryCreateGoal,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Create First Goal',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadGoals,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        elevation: 8,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'Overall Goal Progress',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 15),

                              Text(
                                '${(overallProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 15),

                              LinearProgressIndicator(
                                value: overallProgress,
                                minHeight: 12,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),

                              const SizedBox(height: 15),

                              Text(
                                '₹${totalSaved.toStringAsFixed(0)} saved of ₹${totalTarget.toStringAsFixed(0)}',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'My Goals',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${goals.length} goal${goals.length == 1 ? '' : 's'}',
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      ...goals.map((goal) {
                        final double targetAmount =
                            (goal['targetAmount'] as num)
                                .toDouble();

                        final double savedAmount =
                            (goal['savedAmount'] as num)
                                .toDouble();

                        final double progress =
                            targetAmount > 0
                                ? (savedAmount /
                                        targetAmount)
                                    .clamp(0.0, 1.0)
                                : 0;

                        final bool isCompleted =
                            progress >= 1;

                        return Card(
                          elevation: 5,
                          margin:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        getGoalIcon(
                                          goal['goalName']
                                              .toString(),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            goal['goalName']
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
                                            height: 4,
                                          ),

                                          Text(
                                            isCompleted
                                                ? 'Goal Completed 🎉'
                                                : '${(progress * 100).toStringAsFixed(0)}% completed',
                                          ),
                                        ],
                                      ),
                                    ),

                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          showGoalDialog(
                                            existingGoal: goal,
                                          );
                                        }

                                        if (value == 'delete') {
                                          deleteGoal(goal);
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
                                              Text('Edit'),
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

                                const SizedBox(height: 20),

                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                ),

                                const SizedBox(height: 15),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Text(
                                      'Saved\n₹${savedAmount.toStringAsFixed(0)}',
                                    ),

                                    Text(
                                      'Remaining\n₹${(targetAmount - savedAmount).clamp(0, targetAmount).toStringAsFixed(0)}',
                                      textAlign:
                                          TextAlign.center,
                                    ),

                                    Text(
                                      'Target\n₹${targetAmount.toStringAsFixed(0)}',
                                      textAlign:
                                          TextAlign.end,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: tryCreateGoal,
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
            ),
    );
  }
}