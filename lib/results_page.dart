import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'history_service.dart';

class ResultsPage extends StatefulWidget {
  final int score;
  final double income;
  final double expenses;
  final double savings;
  final double investments;
  final bool healthInsurance;
  final bool termInsurance;

  const ResultsPage({
    super.key,
    required this.score,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.investments,
    required this.healthInsurance,
    required this.termInsurance,
  });

  @override
  State<ResultsPage> createState() =>
      _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveResultToHistory();
    });
  }

  Future<void> _saveResultToHistory() async {
    String savedStatus;

    if (widget.score >= 80) {
      savedStatus = "Excellent";
    } else if (widget.score >= 60) {
      savedStatus = "Good";
    } else if (widget.score >= 40) {
      savedStatus = "Average";
    } else {
      savedStatus = "Weak";
    }

    await HistoryService.saveHistory(
      score: widget.score,
      status: savedStatus,
      income: widget.income,
      expenses: widget.expenses,
      savings: widget.savings,
      investments: widget.investments,
    );
  }

  String getStatus() {
    if (widget.score >= 80) {
      return "Excellent";
    } else if (widget.score >= 60) {
      return "Good";
    } else if (widget.score >= 40) {
      return "Average";
    } else {
      return "Weak";
    }
  }

  Color getStatusColor() {
    if (widget.score >= 80) {
      return Colors.green;
    } else if (widget.score >= 60) {
      return Colors.orange;
    } else if (widget.score >= 40) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  List<String> getPersonalizedRecommendations({
    required double expenseRatio,
    required double savingsRate,
    required double investmentRatio,
  }) {
    final List<String> recommendations = [];

    if (expenseRatio > 80) {
      recommendations.add(
        "Your expenses are very high. Reduce non-essential spending immediately.",
      );
    } else if (expenseRatio > 60) {
      recommendations.add(
        "Your expense ratio is above the recommended level. Try to keep expenses below 60% of income.",
      );
    } else if (expenseRatio <= 50) {
      recommendations.add(
        "Your expense management is strong. Continue maintaining this spending discipline.",
      );
    }

    if (savingsRate == 0) {
      recommendations.add(
        "You are not saving currently. Start by saving at least 10% of your monthly income.",
      );
    } else if (savingsRate < 10) {
      recommendations.add(
        "Your savings rate is low. Gradually increase it to at least 10–20% of income.",
      );
    } else if (savingsRate < 20) {
      recommendations.add(
        "Your savings habit is improving. Aim for a 20% monthly savings rate.",
      );
    } else {
      recommendations.add(
        "Your savings rate is healthy. Continue building your emergency fund.",
      );
    }

    if (investmentRatio == 0) {
      recommendations.add(
        "You currently have no investments. Consider starting with a suitable long-term investment plan.",
      );
    } else if (investmentRatio < 10) {
      recommendations.add(
        "Your investment rate is low. Consider gradually increasing long-term investments.",
      );
    } else if (investmentRatio < 20) {
      recommendations.add(
        "Your investment habit is good. Aim to invest around 20% or more when affordable.",
      );
    } else {
      recommendations.add(
        "Your investment rate is strong. Continue investing consistently for long-term growth.",
      );
    }

    if (!widget.healthInsurance) {
      recommendations.add(
        "Health insurance protection is missing. Consider getting suitable health coverage.",
      );
    }

    if (!widget.termInsurance) {
      recommendations.add(
        "Term insurance protection is missing. Consider it if you have financial dependents.",
      );
    }

    return recommendations;
  }

  String getNextBestAction({
    required double expenseRatio,
    required double savingsRate,
    required double investmentRatio,
  }) {
    if (expenseRatio > 80) {
      return "Reduce Expenses Immediately";
    }

    if (savingsRate < 10) {
      return "Increase Monthly Savings";
    }

    if (investmentRatio == 0) {
      return "Start Your First Investment";
    }

    if (!widget.healthInsurance) {
      return "Review Health Insurance Options";
    }

    if (!widget.termInsurance) {
      return "Review Term Insurance Need";
    }

    if (savingsRate < 20) {
      return "Build Stronger Savings";
    }

    if (investmentRatio < 20) {
      return "Increase Investments Gradually";
    }

    return "Continue Your Financial Plan";
  }

  @override
  Widget build(BuildContext context) {
    final String status = getStatus();
    final Color statusColor = getStatusColor();

    final double savingsRate = widget.income > 0
        ? (widget.savings / widget.income) * 100
        : 0;

    final double expenseRatio = widget.income > 0
        ? (widget.expenses / widget.income) * 100
        : 0;

    final double investmentRatio = widget.income > 0
        ? (widget.investments / widget.income) * 100
        : 0;

    final List<String> recommendations =
        getPersonalizedRecommendations(
      expenseRatio: expenseRatio,
      savingsRate: savingsRate,
      investmentRatio: investmentRatio,
    );

    final String nextAction = getNextBestAction(
      expenseRatio: expenseRatio,
      savingsRate: savingsRate,
      investmentRatio: investmentRatio,
    );

    final Map<String, double> chartData = {
      "Expenses": expenseRatio,
      "Savings": savingsRate,
      "Investments": investmentRatio,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Financial Health Monitor",
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: 350,
                  child: Card(
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "Financial Health Score",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "${widget.score}/100",
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          LinearProgressIndicator(
                            value: widget.score / 100,
                            minHeight: 12,
                            borderRadius:
                                BorderRadius.circular(10),
                            color: statusColor,
                            backgroundColor:
                                Colors.grey.shade300,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${widget.score}%",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Status : $status",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 500,
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Personalized Recommendations",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ...recommendations.map(
                            (recommendation) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      recommendation,
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 350,
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Next Best Action",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            nextAction,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 500,
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Income Distribution",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            height: 260,
                            child: PieChart(
                              dataMap: chartData,
                              chartType: ChartType.ring,
                              ringStrokeWidth: 32,
                              chartRadius: 150,
                              legendOptions:
                                  const LegendOptions(
                                showLegends: false,
                              ),
                              chartValuesOptions:
                                  const ChartValuesOptions(
                                showChartValues: true,
                                showChartValuesInPercentage:
                                    true,
                                decimalPlaces: 0,
                              ),
                            ),
                          ),

                          const Divider(height: 30),

                          ListTile(
                            leading: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.deepPurple,
                            ),
                            title: const Text("Income"),
                            trailing: Text(
                              "₹${widget.income.toStringAsFixed(0)}",
                            ),
                          ),

                          ListTile(
                            leading: const Icon(
                              Icons.money_off,
                              color: Colors.red,
                            ),
                            title: const Text("Expenses"),
                            trailing: Text(
                              "₹${widget.expenses.toStringAsFixed(0)} "
                              "(${expenseRatio.toStringAsFixed(0)}%)",
                            ),
                          ),

                          ListTile(
                            leading: const Icon(
                              Icons.savings,
                              color: Colors.blue,
                            ),
                            title: const Text("Savings"),
                            trailing: Text(
                              "₹${widget.savings.toStringAsFixed(0)} "
                              "(${savingsRate.toStringAsFixed(0)}%)",
                            ),
                          ),

                          ListTile(
                            leading: const Icon(
                              Icons.trending_up,
                              color: Colors.green,
                            ),
                            title: const Text("Investments"),
                            trailing: Text(
                              "₹${widget.investments.toStringAsFixed(0)} "
                              "(${investmentRatio.toStringAsFixed(0)}%)",
                            ),
                          ),

                          const Divider(height: 30),

                          ListTile(
                            leading: Icon(
                              widget.healthInsurance
                                  ? Icons.verified
                                  : Icons.warning_amber,
                              color: widget.healthInsurance
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            title: const Text(
                              "Health Insurance",
                            ),
                            trailing: Text(
                              widget.healthInsurance
                                  ? "Protected"
                                  : "Not Protected",
                            ),
                          ),

                          ListTile(
                            leading: Icon(
                              widget.termInsurance
                                  ? Icons.verified
                                  : Icons.warning_amber,
                              color: widget.termInsurance
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            title: const Text(
                              "Term Insurance",
                            ),
                            trailing: Text(
                              widget.termInsurance
                                  ? "Protected"
                                  : "Not Protected",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: 350,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      "Calculate Again",
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}