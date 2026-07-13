import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

import 'premium_page.dart';
import 'subscription_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String age = 'Not Added';
  String occupation = 'Not Added';

  bool isLoading = true;
  bool isPremium = false;
  final Map<String, bool> _sectionVisible = {};

  @override
  void initState() {
    super.initState();
    loadProfile();
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

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final premiumStatus =
        await SubscriptionService.isPremium();

    if (!mounted) return;

    setState(() {
      age = prefs.getString('age') ?? 'Not Added';
      occupation =
          prefs.getString('occupation') ?? 'Not Added';

      isPremium = premiumStatus;
      isLoading = false;
    });
  }
    Future<void> showEditProfileDialog() async {
    final ageController = TextEditingController(
      text: age == 'Not Added' ? '' : age,
    );

    final occupationController = TextEditingController(
      text: occupation == 'Not Added'
          ? ''
          : occupation,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Profile',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: occupationController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    prefixIcon: Icon(Icons.work_outline),
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
                final enteredAge =
                    ageController.text.trim();

                final enteredOccupation =
                    occupationController.text.trim();

                final parsedAge =
                    int.tryParse(enteredAge);

                if (parsedAge == null ||
                    parsedAge < 13 ||
                    parsedAge > 100) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid age between 13 and 100',
                      ),
                    ),
                  );
                  return;
                }

                if (enteredOccupation.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter your occupation',
                      ),
                    ),
                  );
                  return;
                }

                final prefs =
                    await SharedPreferences.getInstance();

                await prefs.setString(
                  'age',
                  enteredAge,
                );

                await prefs.setString(
                  'occupation',
                  enteredOccupation,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                await loadProfile();

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Profile updated successfully',
                    ),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    ageController.dispose();
    occupationController.dispose();
  }
    Future<void> openPremiumPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumPage(),
      ),
    );

    await loadProfile();
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.subtitle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                                'Profile',
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
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white.withOpacity(0.20),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        child: Icon(
                          isPremium ? Icons.workspace_premium : Icons.person,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isPremium)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, size: 16, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPremium ? Icons.workspace_premium : Icons.person_outline,
                            size: 16,
                            color: isPremium ? const Color(0xFFFCD34D) : Colors.white.withOpacity(0.90),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPremium ? 'Premium Member' : 'Free Member',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.cake_outlined, 'Age', age),
                          const SizedBox(height: 10),
                          Divider(color: Colors.white.withOpacity(0.15), height: 1),
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.work_outline, 'Occupation', occupation),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: showEditProfileDialog,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.80)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.80),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSummary() {
    final accountItems = <Map<String, dynamic>>[
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Income', 'value': '₹0', 'color': const Color(0xFF22C55E)},
      {'icon': Icons.payments_rounded, 'label': 'Expenses', 'value': '₹0', 'color': const Color(0xFFEF4444)},
      {'icon': Icons.savings_rounded, 'label': 'Savings', 'value': '₹0', 'color': AppTheme.primary},
      {'icon': Icons.trending_up_rounded, 'label': 'Investments', 'value': '₹0', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.shield_rounded, 'label': 'Emergency Fund', 'value': '₹0', 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.flag_rounded, 'label': 'Active Goals', 'value': '0', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.warning_rounded, 'label': 'Active Debts', 'value': '0', 'color': const Color(0xFFF97316)},
    ];

    return Column(
      children: [
        _buildAnimatedSection(
          index: 1,
          child: _buildSectionTitle('Account Summary', 'Your financial overview at a glance'),
        ),
        const SizedBox(height: 12),
        _buildAnimatedSection(
          index: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: accountItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item['icon'] as IconData, size: 20, color: item['color'] as Color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item['label'] as String,
                          style: const TextStyle(fontSize: 14, color: AppTheme.subtitle, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Text(
                            item['value'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.text,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActions() {
    final actions = <Map<String, dynamic>>[
      {'icon': Icons.edit_rounded, 'label': 'Edit Profile', 'color': AppTheme.primary},
      {'icon': Icons.account_balance_rounded, 'label': 'Financial Details', 'color': const Color(0xFF22C55E)},
      {'icon': Icons.workspace_premium, 'label': 'Premium Membership', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.notifications_rounded, 'label': 'Notifications', 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.lock_rounded, 'label': 'Privacy', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.security_rounded, 'label': 'Security', 'color': const Color(0xFFF97316)},
      {'icon': Icons.backup_rounded, 'label': 'Backup & Restore', 'color': const Color(0xFF06B6D4)},
      {'icon': Icons.help_rounded, 'label': 'Help & Support', 'color': const Color(0xFF6366F1)},
      {'icon': Icons.info_rounded, 'label': 'About App', 'color': const Color(0xFF14B8A6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(
          index: 3,
          child: _buildSectionTitle('Profile Actions', 'Manage your account settings'),
        ),
        const SizedBox(height: 12),
        ...actions.asMap().entries.map((entry) {
          final idx = entry.key;
          final action = entry.value;
          return _buildAnimatedSection(
            index: 4 + idx,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(action['icon'] as IconData, size: 22, color: action['color'] as Color),
                  ),
                  title: Text(
                    action['label'] as String,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.subtitle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onTap: () {
                    if (action['label'] == 'Edit Profile') {
                      showEditProfileDialog();
                    } else if (action['label'] == 'Premium Membership') {
                      openPremiumPage();
                    }
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPremiumCard() {
    if (isPremium) {
      final benefits = <String>[
        'Unlimited financial tracking',
        'Advanced AI analytics',
        'Cloud backup & sync',
        'Priority support',
        'Ad-free experience',
        'Custom financial insights',
      ];

      return _buildAnimatedSection(
        index: 13,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF081B3A), Color(0xFF1E4ACB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.20),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.workspace_premium, size: 28, color: Color(0xFFFCD34D)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Premium Active',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All premium features unlocked',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Color(0xFF22C55E)),
                        SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF22C55E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 12),
              ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 18, color: const Color(0xFF22C55E)),
                    const SizedBox(width: 10),
                    Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.90),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      );
    }

    return _buildAnimatedSection(
      index: 13,
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium, size: 40, color: Color(0xFFFCD34D)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock unlimited tracking, advanced analytics, AI insights, cloud backup and premium financial tools.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: openPremiumPage,
                      icon: const Icon(Icons.workspace_premium, size: 20),
                      label: const Text('Unlock Premium'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No commitment • Cancel anytime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.60),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final accountInfo = <Map<String, dynamic>>[
      {'icon': Icons.info_outline, 'label': 'App Version', 'value': '1.0.0'},
      {'icon': Icons.calendar_today, 'label': 'Joined Date', 'value': 'Member since 2025'},
      {'icon': Icons.cloud_upload_rounded, 'label': 'Last Backup', 'value': 'Not backed up'},
      {'icon': Icons.storage_rounded, 'label': 'Storage Used', 'value': '0 MB'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedSection(
          index: 14,
          child: _buildSectionTitle('Account', 'Your account information'),
        ),
        const SizedBox(height: 12),
        _buildAnimatedSection(
          index: 15,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: accountInfo.map((info) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(info['icon'] as IconData, size: 18, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          info['label'] as String,
                          style: const TextStyle(fontSize: 14, color: AppTheme.subtitle, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        info['value'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.text),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.danger, size: 24),
              SizedBox(width: 10),
              Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? Your data will remain saved on this device.',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  Widget _buildLogoutSection() {
    return _buildAnimatedSection(
      index: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.logout_rounded, size: 28, color: AppTheme.danger),
            ),
            const SizedBox(height: 12),
            const Text(
              'Account Logout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.text),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign out of your account. Your data stays safe on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.subtitle, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showLogoutConfirmation,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
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
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
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
              child: Icon(
                isPremium ? Icons.workspace_premium : Icons.person,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your financial identity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.subtitle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
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
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAnimatedSection(index: 0, child: _buildProfileHeader()),
                          const SizedBox(height: 20),
                          _buildAccountSummary(),
                          const SizedBox(height: 24),
                          _buildProfileActions(),
                          const SizedBox(height: 24),
                          _buildPremiumCard(),
                          const SizedBox(height: 24),
                          _buildAccountSection(),
                          const SizedBox(height: 24),
                          _buildLogoutSection(),
                          const SizedBox(height: 24),
                          _buildAnimatedSection(
                            index: 17,
                            child: const Center(
                              child: Text(
                                'FinHealth v1.0',
                                style: TextStyle(
                                  color: AppTheme.subtitle,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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