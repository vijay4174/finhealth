import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'debt_service.dart';
import 'history_service.dart';
import 'monthly_service.dart';
import 'premium_page.dart';
import 'subscription_service.dart';
import 'theme_provider.dart';

class SettingsPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SettingsPage({
    super.key,
    required this.themeProvider,
  });

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {
  bool isLoading = true;
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final premiumStatus =
        await SubscriptionService.isPremium();

    if (!mounted) return;

    setState(() {
      isPremium = premiumStatus;
      isLoading = false;
    });
  }

  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
              child: Text(
                confirmText,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> clearHistory() async {
    final shouldClear =
        await showConfirmationDialog(
      title: 'Clear History',
      message:
          'Are you sure you want to delete all saved financial assessment reports?',
      confirmText: 'Clear History',
    );

    if (!shouldClear) return;

    await HistoryService.clearHistory();

    showMessage(
      'Financial history cleared',
    );
  }

  Future<void> clearMonthlyRecords() async {
    final shouldClear =
        await showConfirmationDialog(
      title: 'Clear Monthly Records',
      message:
          'Are you sure you want to delete all monthly financial records?',
      confirmText: 'Clear Records',
    );

    if (!shouldClear) return;

    await MonthlyService.clearMonthlyRecords();

    showMessage(
      'Monthly records cleared',
    );
  }

  Future<void> clearGoals() async {
    final shouldClear =
        await showConfirmationDialog(
      title: 'Clear Financial Goals',
      message:
          'Are you sure you want to delete all financial goals and their progress?',
      confirmText: 'Clear Goals',
    );

    if (!shouldClear) return;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('goals');

    showMessage(
      'Financial goals cleared',
    );
  }

  Future<void> clearDebts() async {
    final shouldClear =
        await showConfirmationDialog(
      title: 'Clear Debts',
      message:
          'Are you sure you want to delete all debts, EMI progress and payment history?',
      confirmText: 'Clear Debts',
    );

    if (!shouldClear) return;

    await DebtService.clearDebts();

    showMessage(
      'Debt records cleared',
    );
  }

  Future<void> resetAllAppData() async {
    final shouldReset =
        await showConfirmationDialog(
      title: 'Reset All App Data',
      message:
          'This will permanently delete your profile, assessments, history, monthly records, goals, debts and all other locally saved app data. This action cannot be undone.',
      confirmText: 'Reset Everything',
    );

    if (!shouldReset) return;

    await DebtService.clearDebts();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.clear();

    if (!mounted) return;

    setState(() {
      isPremium = false;
    });

    showMessage(
      'All app data has been reset',
    );
  }

  Future<void> openPremiumPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PremiumPage(),
      ),
    );

    await loadSettings();
  }

  void showAboutApp() {
    showAboutDialog(
      context: context,
      applicationName:
          'Financial Health Monitor',
      applicationVersion: '1.5.0',
      applicationIcon: const Icon(
        Icons.account_balance_wallet,
        size: 50,
      ),
      children: const [
        Text(
          'Financial Health Monitor helps you assess your financial health, track monthly progress, manage goals, plan budgets, build an emergency fund, manage debts and receive personalized recommendations.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadSettings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 6,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          isPremium
                              ? Icons
                                  .workspace_premium
                              : Icons.person_outline,
                        ),
                      ),
                      title: Text(
                        isPremium
                            ? 'Premium Member'
                            : 'Free Member',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        isPremium
                            ? 'All premium features are unlocked'
                            : 'Upgrade to unlock advanced features',
                      ),
                      trailing: isPremium
                          ? const Icon(
                              Icons.verified,
                            )
                          : const Icon(
                              Icons
                                  .arrow_forward_ios,
                              size: 18,
                            ),
                      onTap: isPremium
                          ? null
                          : openPremiumPage,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: SwitchListTile(
                      secondary: Icon(
                        widget.themeProvider
                                .isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      title: const Text(
                        'Dark Mode',
                      ),
                      subtitle: const Text(
                        'Change app appearance',
                      ),
                      value: widget
                          .themeProvider.isDarkMode,
                      onChanged: (value) {
                        widget.themeProvider
                            .toggleTheme(value);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Data Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons
                                .history_outlined,
                          ),
                          title: const Text(
                            'Clear History',
                          ),
                          subtitle: const Text(
                            'Delete all assessment reports',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: clearHistory,
                        ),

                        const Divider(height: 1),

                        ListTile(
                          leading: const Icon(
                            Icons
                                .calendar_month_outlined,
                          ),
                          title: const Text(
                            'Clear Monthly Records',
                          ),
                          subtitle: const Text(
                            'Delete all monthly tracking data',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap:
                              clearMonthlyRecords,
                        ),

                        const Divider(height: 1),

                        ListTile(
                          leading: const Icon(
                            Icons.flag_outlined,
                          ),
                          title: const Text(
                            'Clear Goals',
                          ),
                          subtitle: const Text(
                            'Delete all financial goals',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: clearGoals,
                        ),

                        const Divider(height: 1),

                        ListTile(
                          leading: const Icon(
                            Icons
                                .credit_card_outlined,
                          ),
                          title: const Text(
                            'Clear Debts',
                          ),
                          subtitle: const Text(
                            'Delete debts and EMI history',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: clearDebts,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons
                            .delete_forever_outlined,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Reset All App Data',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Permanently delete all locally saved data',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.red,
                      ),
                      onTap: resetAllAppData,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                          ),
                          title: const Text(
                            'About App',
                          ),
                          subtitle: const Text(
                            'Financial Health Monitor',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: showAboutApp,
                        ),

                        const Divider(height: 1),

                        const ListTile(
                          leading: Icon(
                            Icons.apps,
                          ),
                          title: Text(
                            'App Version',
                          ),
                          trailing: Text(
                            '1.5.0',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}