class RecommendationService {
  static List<Map<String, dynamic>> generateRecommendations({
    required double income,
    required double expenses,
    required double savings,
    required double investments,
    required double emergencyFund,
    required double totalDebt,
    required bool hasHealthInsurance,
    required bool hasTermInsurance,
    required bool isPremium,
  }) {
    final List<Map<String, dynamic>> recommendations = [];

    final double expenseRatio =
        income > 0 ? (expenses / income) * 100 : 0;

    final double savingsRate =
        income > 0 ? (savings / income) * 100 : 0;

    final double investmentRate =
        income > 0 ? (investments / income) * 100 : 0;

    final double emergencyFundTarget = expenses * 6;

    if (income <= 0) {
      recommendations.add({
        'priority': 'High',
        'title': 'Build a Stable Income Source',
        'message':
            'Your first financial priority should be creating a stable source of income.',
        'icon': 'income',
      });
    }

    if (income > 0 && expenseRatio > 80) {
      recommendations.add({
        'priority': 'High',
        'title': 'Reduce Monthly Expenses',
        'message':
            'Your expenses are ${expenseRatio.toStringAsFixed(0)}% of income. Try to keep them below 70%.',
        'icon': 'expenses',
      });
    }

    if (income > 0 && savingsRate < 10) {
      recommendations.add({
        'priority': 'High',
        'title': 'Increase Your Savings',
        'message':
            'Your savings rate is ${savingsRate.toStringAsFixed(0)}%. Aim to save at least 10–20% of your income.',
        'icon': 'savings',
      });
    }

    if (income > 0 &&
        savingsRate >= 10 &&
        savingsRate < 20) {
      recommendations.add({
        'priority': 'Medium',
        'title': 'Improve Your Savings Rate',
        'message':
            'You are saving ${savingsRate.toStringAsFixed(0)}% of income. Try to gradually reach 20%.',
        'icon': 'savings',
      });
    }

    if (income > 0 && investmentRate < 10) {
      recommendations.add({
        'priority': 'Medium',
        'title': 'Start or Increase Investments',
        'message':
            'Consider investing at least 10–15% of income for long-term wealth creation.',
        'icon': 'investment',
      });
    }

    if (expenses > 0 &&
        emergencyFund < emergencyFundTarget) {
      final remaining =
          emergencyFundTarget - emergencyFund;

      recommendations.add({
        'priority': 'High',
        'title': 'Build Your Emergency Fund',
        'message':
            'You need about ₹${remaining.toStringAsFixed(0)} more to reach a 6-month emergency fund.',
        'icon': 'emergency',
      });
    }

    if (totalDebt > 0) {
      recommendations.add({
        'priority': 'High',
        'title': 'Focus on Debt Repayment',
        'message':
            'You currently have ₹${totalDebt.toStringAsFixed(0)} in debt. Prioritize high-interest loans first.',
        'icon': 'debt',
      });
    }

    if (!hasHealthInsurance) {
      recommendations.add({
        'priority': 'High',
        'title': 'Get Health Insurance',
        'message':
            'Health insurance can protect your savings from unexpected medical expenses.',
        'icon': 'insurance',
      });
    }

    if (income > 0 && !hasTermInsurance) {
      recommendations.add({
        'priority': 'Medium',
        'title': 'Review Term Insurance Need',
        'message':
            'If your family depends on your income, consider adequate term life insurance.',
        'icon': 'insurance',
      });
    }

    if (isPremium) {
      if (expenseRatio > 70) {
        recommendations.add({
          'priority': 'Premium',
          'title': 'Create a Spending Reduction Plan',
          'message':
              'Reduce non-essential spending gradually and redirect the difference toward savings or debt repayment.',
          'icon': 'premium',
        });
      }

      if (savingsRate >= 20 &&
          investmentRate < 15) {
        recommendations.add({
          'priority': 'Premium',
          'title': 'Optimize Excess Savings',
          'message':
              'Your savings rate is healthy. Consider moving part of long-term surplus toward suitable investments.',
          'icon': 'premium',
        });
      }

      if (totalDebt == 0 &&
          emergencyFund >= emergencyFundTarget &&
          investmentRate >= 15) {
        recommendations.add({
          'priority': 'Premium',
          'title': 'Focus on Wealth Growth',
          'message':
              'Your financial foundation is strong. Focus on diversification and long-term goal-based investing.',
          'icon': 'premium',
        });
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'priority': 'Good',
        'title': 'Keep Maintaining Your Progress',
        'message':
            'Your current financial habits look healthy. Continue tracking and reviewing your finances regularly.',
        'icon': 'success',
      });
    }

    recommendations.sort((a, b) {
      return _priorityValue(
        a['priority'].toString(),
      ).compareTo(
        _priorityValue(
          b['priority'].toString(),
        ),
      );
    });

    return recommendations;
  }

  static int _priorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 1;

      case 'Medium':
        return 2;

      case 'Premium':
        return 3;

      case 'Good':
        return 4;

      default:
        return 5;
    }
  }
}