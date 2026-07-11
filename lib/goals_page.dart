import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
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

    final int activeGoals = goals.where((goal) {
      final double targetAmount = (goal['targetAmount'] as num).toDouble();
      final double savedAmount = (goal['savedAmount'] as num).toDouble();
      final double progress = targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;
      return progress < 1;
    }).length;

    final int completedGoals = goals.length - activeGoals;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 84,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Goals', style: TextStyle(color: AppTheme.text, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Achieve your financial dreams', style: TextStyle(color: AppTheme.subtitle, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.warning]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.16), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: const Center(child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : goals.isEmpty
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
                            ),
                            child: const Icon(Icons.flag_circle_rounded, size: 72, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 20),
                          const Text('No financial goals yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.text)),
                          const SizedBox(height: 8),
                          const Text('Create your first goal and start tracking your financial progress.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.subtitle, height: 1.4)),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: tryCreateGoal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.add_circle_rounded),
                            label: const Text('Create First Goal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: RefreshIndicator(
                      onRefresh: loadGoals,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          _buildAnimatedSection(
                            index: 0,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 22, offset: const Offset(0, 10))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Overall progress', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                                            const SizedBox(height: 4),
                                            TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0.0, end: overallProgress * 100),
                                              duration: const Duration(milliseconds: 900),
                                              curve: Curves.easeOutCubic,
                                              builder: (context, animatedValue, _) {
                                                return Text('${animatedValue.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800));
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(999)),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text('Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 110,
                                        height: 110,
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: overallProgress),
                                          duration: const Duration(milliseconds: 900),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, animatedValue, _) {
                                            return CircularProgressIndicator(
                                              value: animatedValue,
                                              strokeWidth: 10,
                                              backgroundColor: Colors.white.withOpacity(0.18),
                                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                            );
                                          },
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          const Text('Saved', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 2),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: totalSaved),
                                            duration: const Duration(milliseconds: 900),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, animatedValue, _) {
                                              return Text('₹${animatedValue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16));
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(child: _buildSummaryMetric('Active', activeGoals.toDouble(), Icons.trending_up_rounded)),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildSummaryMetric('Completed', completedGoals.toDouble(), Icons.check_circle_rounded)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(child: _buildSummaryMetric('Target', totalTarget, Icons.savings_rounded)),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildSummaryMetric('Saved', totalSaved, Icons.account_balance_wallet_rounded)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Text('My goals', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text))),
                              Text('${goals.length} goal${goals.length == 1 ? '' : 's'}', style: const TextStyle(color: AppTheme.subtitle, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...goals.map((goal) {
                            final double targetAmount = (goal['targetAmount'] as num).toDouble();
                            final double savedAmount = (goal['savedAmount'] as num).toDouble();
                            final double progress = targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;
                            final bool isCompleted = progress >= 1;

                            return _buildAnimatedSection(
                              index: goals.indexOf(goal) + 1,
                              child: _buildGoalCard(goal, progress, isCompleted),
                            );
                          }),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: tryCreateGoal,
              icon: const Icon(Icons.add_circle_rounded),
              label: const Text('New Goal'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 550 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: childWidget),
        );
      },
      child: child,
    );
  }

  Widget _buildSummaryMetric(String label, double value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: value),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return Text('₹${animatedValue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, double progress, bool isCompleted) {
    final double targetAmount = (goal['targetAmount'] as num).toDouble();
    final double savedAmount = (goal['savedAmount'] as num).toDouble();
    final String status = isCompleted ? 'Completed' : 'In Progress';
    final Color statusColor = isCompleted ? AppTheme.success : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary, isCompleted ? AppTheme.success : const Color(0xFF38BDF8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(getGoalIcon(goal['goalName'].toString()), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal['goalName'].toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.text)),
                    const SizedBox(height: 4),
                    Text(isCompleted ? 'Goal completed' : '${(progress * 100).toStringAsFixed(0)}% completed', style: const TextStyle(fontSize: 13, color: AppTheme.subtitle)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => showGoalDialog(existingGoal: goal),
                      tooltip: 'Edit Goal',
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      onPressed: () => deleteGoal(goal),
                      tooltip: 'Delete Goal',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppTheme.success : AppTheme.primary),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGoalMetric('Saved', savedAmount)),
              const SizedBox(width: 8),
              Expanded(child: _buildGoalMetric('Remaining', (targetAmount - savedAmount).clamp(0, targetAmount))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildGoalMetric('Target', targetAmount)),
              const SizedBox(width: 8),
              Expanded(child: _buildGoalMetric('Progress', progress * 100)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Target date: ${goal['targetDate'] is String && (goal['targetDate'] as String).isNotEmpty ? goal['targetDate'] : 'Flexible'}', style: const TextStyle(color: AppTheme.subtitle, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _buildGoalMetric(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.subtitle, fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label == 'Progress' ? '${value.toStringAsFixed(0)}%' : '₹${value.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }
}
