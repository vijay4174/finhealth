import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    loadProfile();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'FinHealth Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            onPressed: showEditProfileDialog,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                Colors.blue.shade100,
                            child: Icon(
                              isPremium
                                  ? Icons
                                      .workspace_premium
                                  : Icons.person,
                              size: 55,
                              color: Colors.blue,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Chip(
                            avatar: Icon(
                              isPremium
                                  ? Icons
                                      .workspace_premium
                                  : Icons.person_outline,
                            ),
                            label: Text(
                              isPremium
                                  ? 'Premium Member'
                                  : 'Free Member',
                            ),
                          ),

                          const SizedBox(height: 20),

                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.cake_outlined,
                              ),
                            ),
                            title:
                                const Text('Age'),
                            subtitle: Text(age),
                          ),

                          const Divider(),

                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.work_outline,
                              ),
                            ),
                            title: const Text(
                                'Occupation'),
                            subtitle:
                                Text(occupation),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child:
                                ElevatedButton.icon(
                              onPressed:
                                  showEditProfileDialog,
                              icon: const Icon(
                                  Icons.edit),
                              label: const Text(
                                'Edit Profile',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (!isPremium)
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons
                                  .workspace_premium,
                              size: 50,
                              color: Colors.amber,
                            ),

                            const SizedBox(
                                height: 12),

                            const Text(
                              'Upgrade to FinHealth Premium',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                              textAlign:
                                  TextAlign.center,
                            ),

                            const SizedBox(
                                height: 10),

                            const Text(
                              'Unlock unlimited tracking, advanced analytics, AI insights, cloud backup and premium financial tools.',
                              textAlign:
                                  TextAlign.center,
                            ),

                            const SizedBox(
                                height: 20),

                            SizedBox(
                              width:
                                  double.infinity,
                              child:
                                  ElevatedButton.icon(
                                onPressed:
                                    openPremiumPage,
                                icon: const Icon(
                                  Icons
                                      .workspace_premium,
                                ),
                                label: const Text(
                                  'View Premium',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  const Center(
                    child: Text(
                      'FinHealth v1.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}