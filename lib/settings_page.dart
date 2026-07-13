import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
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
  final Map<String, bool> _sectionVisible = {};

  @override
  void initState() {
    super.initState();
    loadSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int index = 0; index < 18; index++) {
        Future.delayed(Duration(milliseconds: 100 + (index * 70)), () {
          if (!mounted) return;
          setState(() {
            _sectionVisible['section_$index'] = true;
          });
        });
      }
    });
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.subtitle,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(dialogContext, false);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.subtitle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(dialogContext, true);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            confirmText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 3),
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

  Widget _buildAnimatedSection({required Widget child, required int index}) {
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

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.subtitle,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF081B3A), Color(0xFF1E4ACB), Color(0xFF5A8EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.28),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white.withOpacity(0.95)),
                              const SizedBox(width: 6),
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.white.withOpacity(0.95)),
                                    const SizedBox(width: 6),
                                    Text(
                                      isPremium ? 'Premium Active' : 'Free Plan',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildStatusRow(Icons.info_outline, 'Version 1.5.0'),
                                const SizedBox(height: 6),
                                _buildStatusRow(
                                  Icons.sync_rounded,
                                  isPremium ? 'Auto-sync enabled' : 'Manual sync only',
                                ),
                                const SizedBox(height: 6),
                                _buildStatusRow(
                                  Icons.notifications_active_rounded,
                                  isPremium ? 'All notifications active' : 'Limited notifications',
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPremium ? const Color(0xFF22C55E).withOpacity(0.2) : Colors.white.withOpacity(0.16),
                            ),
                            child: Icon(
                              isPremium ? Icons.verified_rounded : Icons.person_outline_rounded,
                              color: isPremium ? const Color(0xFF22C55E) : Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.text,
                letterSpacing: -0.2,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.text,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.subtitle,
                  ),
                )
              : null,
          trailing: trailing ??
              (onTap != null
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.primary),
                    )
                  : null),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: SwitchListTile(
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.text,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.subtitle,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        activeTrackColor: AppTheme.primary.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  Widget _buildPremiumCard() {
    if (isPremium) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF5B8CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Active',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'All features unlocked',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 20),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF081B3A), Color(0xFF1E4ACB), Color(0xFF5A8EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.28),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: openPremiumPage,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.16),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unlock all features & insights',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_forever_outlined, color: AppTheme.danger, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reset App Data',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Permanently delete all locally saved data',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtitle,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_right_rounded, color: AppTheme.danger, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About App',
            subtitle: 'Financial Health Monitor',
            onTap: showAboutApp,
            iconColor: AppTheme.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildSettingsTile(
            icon: Icons.apps_rounded,
            title: 'App Version',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '1.5.0',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.primary,
                ),
              ),
            ),
            iconColor: const Color(0xFF8B5CF6),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildSettingsTile(
            icon: Icons.developer_mode_rounded,
            title: 'Developer',
            subtitle: 'FinHealth Team',
            iconColor: const Color(0xFFF59E0B),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy Policy',
            iconColor: const Color(0xFF22C55E),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildSettingsTile(
            icon: Icons.description_rounded,
            title: 'Terms & Conditions',
            iconColor: const Color(0xFFEC4899),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildSettingsTile(
            icon: Icons.article_rounded,
            title: 'Licenses',
            iconColor: const Color(0xFF14B8A6),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildSettingsTile(
            icon: Icons.headset_mic_rounded,
            title: 'Contact Support',
            iconColor: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 96,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Customize your FinHealth experience',
              style: TextStyle(
                color: AppTheme.subtitle,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadSettings,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAnimatedSection(
                            index: 0,
                            child: _buildHeroCard(),
                          ),
                          const SizedBox(height: 20),
                          _buildAnimatedSection(
                            index: 1,
                            child: _buildSectionTitle('General', 'App preferences'),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(
                            index: 2,
                            child: _buildSettingsCard(
                              title: 'Appearance & Region',
                              children: [
                                _buildSwitchTile(
                                  icon: widget.themeProvider.isDarkMode
                                      ? Icons.dark_mode_rounded
                                      : Icons.light_mode_rounded,
                                  title: 'Dark Mode',
                                  subtitle: 'Change app appearance',
                                  value: widget.themeProvider.isDarkMode,
                                  onChanged: (value) {
                                    widget.themeProvider.toggleTheme(value);
                                  },
                                  iconColor: const Color(0xFFF59E0B),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.currency_exchange_rounded,
                                  title: 'Currency',
                                  subtitle: 'Indian Rupee (₹)',
                                  iconColor: const Color(0xFF22C55E),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.language_rounded,
                                  title: 'Language',
                                  subtitle: 'English (US)',
                                  iconColor: const Color(0xFF8B5CF6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 3,
                            child: _buildSectionTitle('Notifications', 'Manage your alerts'),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(
                            index: 4,
                            child: _buildSettingsCard(
                              title: 'Reminders',
                              children: [
                                _buildSwitchTile(
                                  icon: Icons.notifications_active_rounded,
                                  title: 'Daily Reminder',
                                  subtitle: 'Get daily financial check-in',
                                  value: true,
                                  onChanged: (value) {},
                                  iconColor: AppTheme.primary,
                                ),
                                _buildSwitchTile(
                                  icon: Icons.flag_rounded,
                                  title: 'Goal Reminder',
                                  subtitle: 'Track your financial goals',
                                  value: true,
                                  onChanged: (value) {},
                                  iconColor: const Color(0xFF22C55E),
                                ),
                                _buildSwitchTile(
                                  icon: Icons.credit_card_rounded,
                                  title: 'EMI Reminder',
                                  subtitle: 'Never miss an EMI payment',
                                  value: true,
                                  onChanged: (value) {},
                                  iconColor: const Color(0xFFF59E0B),
                                ),
                                _buildSwitchTile(
                                  icon: Icons.receipt_long_rounded,
                                  title: 'Bill Reminder',
                                  subtitle: 'Stay on top of your bills',
                                  value: true,
                                  onChanged: (value) {},
                                  iconColor: const Color(0xFFEC4899),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 5,
                            child: _buildSectionTitle('Data & Backup', 'Manage your data'),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(
                            index: 6,
                            child: _buildSettingsCard(
                              title: 'Data Management',
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.cloud_upload_rounded,
                                  title: 'Backup Data',
                                  subtitle: 'Save your data to cloud',
                                  iconColor: AppTheme.primary,
                                ),
                                _buildSettingsTile(
                                  icon: Icons.cloud_download_rounded,
                                  title: 'Restore Data',
                                  subtitle: 'Recover from backup',
                                  iconColor: const Color(0xFF22C55E),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.file_download_rounded,
                                  title: 'Export Data',
                                  subtitle: 'Download as CSV/PDF',
                                  iconColor: const Color(0xFFF59E0B),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.file_upload_rounded,
                                  title: 'Import Data',
                                  subtitle: 'Import from external source',
                                  iconColor: const Color(0xFF8B5CF6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 7,
                            child: _buildSectionTitle('Security', 'Protect your data'),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(
                            index: 8,
                            child: _buildSettingsCard(
                              title: 'Security Settings',
                              children: [
                                _buildSwitchTile(
                                  icon: Icons.lock_rounded,
                                  title: 'App Lock',
                                  subtitle: 'Secure app with passcode',
                                  value: false,
                                  onChanged: (value) {},
                                  iconColor: AppTheme.primary,
                                ),
                                _buildSwitchTile(
                                  icon: Icons.visibility_rounded,
                                  title: 'Privacy',
                                  subtitle: 'Hide sensitive amounts',
                                  value: false,
                                  onChanged: (value) {},
                                  iconColor: const Color(0xFF22C55E),
                                ),
                                _buildSwitchTile(
                                  icon: Icons.fingerprint_rounded,
                                  title: 'Biometric Authentication',
                                  subtitle: 'Use fingerprint or face ID',
                                  value: false,
                                  onChanged: (value) {},
                                  iconColor: const Color(0xFF8B5CF6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 9,
                            child: _buildSectionTitle('Premium', 'Membership'),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(
                            index: 10,
                            child: _buildPremiumCard(),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 11,
                            child: _buildSectionTitle('Data Cleanup', 'Clear app data'),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(
                            index: 12,
                            child: _buildSettingsCard(
                              title: 'Clear Data',
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.history_rounded,
                                  title: 'Clear History',
                                  subtitle: 'Delete all assessment reports',
                                  onTap: clearHistory,
                                  iconColor: AppTheme.primary,
                                ),
                                _buildSettingsTile(
                                  icon: Icons.calendar_month_rounded,
                                  title: 'Clear Monthly Records',
                                  subtitle: 'Delete all monthly tracking data',
                                  onTap: clearMonthlyRecords,
                                  iconColor: const Color(0xFFF59E0B),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.flag_rounded,
                                  title: 'Clear Goals',
                                  subtitle: 'Delete all financial goals',
                                  onTap: clearGoals,
                                  iconColor: const Color(0xFF22C55E),
                                ),
                                _buildSettingsTile(
                                  icon: Icons.credit_card_rounded,
                                  title: 'Clear Debts',
                                  subtitle: 'Delete debts and EMI history',
                                  onTap: clearDebts,
                                  iconColor: const Color(0xFFEC4899),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 13,
                            child: _buildSectionTitle('Reset', 'Danger zone'),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(
                            index: 14,
                            child: InkWell(
                              onTap: resetAllAppData,
                              borderRadius: BorderRadius.circular(28),
                              child: _buildResetCard(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedSection(
                            index: 15,
                            child: _buildSectionTitle('About', 'App information'),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedSection(
                            index: 16,
                            child: _buildAboutCard(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
