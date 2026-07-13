import 'dart:ui';

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
  final Map<String, bool> _sectionVisible = {};

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
        toolbarHeight: 96,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Goals', style: TextStyle(color: AppTheme.text, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Turn your dreams into achievements', style: TextStyle(color: AppTheme.subtitle, fontSize: 12.5)),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppTheme.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: const Center(child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : goals.isEmpty
              ? _buildEmptyState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: RefreshIndicator(
                      onRefresh: loadGoals,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          _buildAnimatedSection(index: 0, child: _buildHeroCard(overallProgress, totalTarget, totalSaved, activeGoals, completedGoals)),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(index: 1, child: _buildQuickActions()),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(index: 2, child: _buildInsightsCard(activeGoals, completedGoals, goals)),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 3,
                            child: Row(
                              children: [
                                Expanded(child: Text('My goals', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text))),
                                Text('${goals.length} goal${goals.length == 1 ? '' : 's'}', style: const TextStyle(color: AppTheme.subtitle, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...goals.map((goal) {
                            final double targetAmount = (goal['targetAmount'] as num).toDouble();
                            final double savedAmount = (goal['savedAmount'] as num).toDouble();
                            final double progress = targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;
                            final bool isCompleted = progress >= 1;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildAnimatedSection(
                                index: goals.indexOf(goal) + 4,
                                child: _buildGoalCard(goal, progress, isCompleted),
                              ),
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

  Widget _buildEmptyState() {
    return Center(
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
                  gradient: const LinearGradient(colors: [Color(0xFF081B3A), Color(0xFF1E4ACB), Color(0xFF5A8EFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.28), blurRadius: 32, offset: const Offset(0, 18))],
                ),
                child: const Icon(Icons.flag_circle_rounded, size: 72, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('No goals created yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.text)),
              const SizedBox(height: 8),
              const Text('Set meaningful financial goals and track your progress every step of the way.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.subtitle, height: 1.4)),
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
                label: const Text('Create Your First Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(double overallProgress, double totalTarget, double totalSaved, int activeGoals, int completedGoals) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF081B3A), Color(0xFF1E4ACB), Color(0xFF5A8EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.28), blurRadius: 32, offset: const Offset(0, 18)),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'Goal Overview',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
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
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 96,
                                height: 96,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: overallProgress),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animatedValue, _) {
                                    return CircularProgressIndicator(
                                      value: animatedValue,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.16),
                                ),
                                child: Center(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: overallProgress * 100),
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, animatedValue, _) {
                                      return Text('${animatedValue.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800));
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Overall Progress', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(
                                  '${goals.length} goal${goals.length == 1 ? '' : 's'} tracked with dedication.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 13, height: 1.45),
                                ),
                                const SizedBox(height: 10),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: overallProgress),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animatedValue, _) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: animatedValue,
                                        minHeight: 8,
                                        backgroundColor: Colors.white24,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: tryCreateGoal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Goal', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (goals.isNotEmpty) {
                  showGoalDialog(existingGoal: goals.first);
                }
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Savings', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.text, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(int activeGoals, int completedGoals, List<Map<String, dynamic>> goalsList) {
    String insightText;
    IconData insightIcon;
    Color insightColor;

    if (completedGoals >= 3) {
      insightText = '🔥 Great! You have completed $completedGoals of your goals.';
      insightIcon = Icons.emoji_events_rounded;
      insightColor = const Color(0xFFF59E0B);
    } else if (activeGoals > 0 && goalsList.isNotEmpty) {
      final firstGoal = goalsList.firstWhere(
        (g) => (g['targetAmount'] as num).toDouble() > (g['savedAmount'] as num).toDouble(),
        orElse: () => goalsList.first,
      );
      final remaining = (firstGoal['targetAmount'] as num).toDouble() - (firstGoal['savedAmount'] as num).toDouble();
      if (remaining > 0 && remaining < 10000) {
        insightText = '🎯 You are only ₹${remaining.toStringAsFixed(0)} away from your ${firstGoal['goalName']} Goal.';
        insightIcon = Icons.trending_up_rounded;
        insightColor = const Color(0xFF22C55E);
      } else {
        insightText = '💪 Saving consistently helps you achieve goals faster.';
        insightIcon = Icons.lightbulb_rounded;
        insightColor = AppTheme.primary;
      }
    } else {
      insightText = '💪 Saving consistently helps you achieve goals faster.';
      insightIcon = Icons.lightbulb_rounded;
      insightColor = AppTheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [insightColor.withOpacity(0.10), insightColor.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: insightColor.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: insightColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(insightIcon, color: insightColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insightText,
              style: TextStyle(color: AppTheme.text, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
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
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                onSelected: (value) {
                  if (value == 'add') {
                    showGoalDialog(existingGoal: goal);
                  } else if (value == 'edit') {
                    showGoalDialog(existingGoal: goal);
                  } else if (value == 'delete') {
                    deleteGoal(goal);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'add', child: Row(children: [Icon(Icons.savings_rounded, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text('Add Savings')])),
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text('Edit Goal')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger), SizedBox(width: 8), Text('Delete Goal')])),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.more_vert_rounded, color: AppTheme.subtitle, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(999)),
                child: Text(goal['goalName'].toString(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ],
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