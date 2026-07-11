import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_page.dart';
import 'debt_service.dart';
import 'financial_details.dart';
import 'goals_page.dart';
import 'history_page.dart';
import 'internet_service.dart';
import 'notification_service.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'theme_provider.dart';
import 'splash_screen.dart';
import 'app_theme.dart';
import 'home_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await InternetService.startMonitoring();

  if (!kIsWeb) {
    await NotificationService.initialize();

    await DebtService.syncAllEmiReminders();
  }

 runApp(const FinancialHealthApp());
}

class FinancialHealthApp extends StatefulWidget {
  const FinancialHealthApp({super.key});

  @override
  State<FinancialHealthApp> createState() =>
      _FinancialHealthAppState();
}

class _FinancialHealthAppState
    extends State<FinancialHealthApp> {
  final ThemeProvider themeProvider =
      ThemeProvider();

  @override
  void dispose() {
    themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FinHealth',
          theme: ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppTheme.background,

  colorScheme: ColorScheme.fromSeed(
    seedColor: AppTheme.primary,
    brightness: Brightness.light,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppTheme.background,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppTheme.text,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(
      color: AppTheme.text,
    ),
  ),


  cardTheme: CardThemeData(
    color: AppTheme.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
    ),
  ),
),
darkTheme: ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0F172A),
),
          themeMode: themeProvider.themeMode,
          home: SplashScreen(
  nextPage: MainNavigationPage(
    themeProvider: themeProvider,
  ),
),
        );
      },
    );
  }
}

class MainNavigationPage
    extends StatefulWidget {
  final ThemeProvider themeProvider;

  const MainNavigationPage({
    super.key,
    required this.themeProvider,
  });

  @override
  State<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState
    extends State<MainNavigationPage> {
  int selectedIndex = 0;

  int dashboardRefreshKey = 0;
  int historyRefreshKey = 0;
  int goalsRefreshKey = 0;
  int profileRefreshKey = 0;

  bool isCheckingProfile = true;
  bool isProfileCompleted = false;

  @override
  void initState() {
    super.initState();
    checkProfile();
  }

  Future<void> checkProfile() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? dateOfBirth =
        prefs.getString('dateOfBirth');

    final String? occupation =
        prefs.getString('occupation');

    if (!mounted) return;

    setState(() {
      isProfileCompleted =
          dateOfBirth != null &&
          dateOfBirth.isNotEmpty &&
          occupation != null &&
          occupation.isNotEmpty;

      isCheckingProfile = false;
    });
  }

  void profileCompleted() {
    setState(() {
      isProfileCompleted = true;
      dashboardRefreshKey++;
    });
  }

  void changePage(int index) {
    setState(() {
      selectedIndex = index;

      if (index == 0) {
        dashboardRefreshKey++;
      }

      if (index == 1) {
        historyRefreshKey++;
      }

      if (index == 2) {
        goalsRefreshKey++;
      }

      if (index == 3) {
        profileRefreshKey++;
      }
    });
  }

  Widget buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      color: Colors.red,
      child: const SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
    if (isCheckingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<bool>(
      stream:
          InternetService.internetStatusStream,
      initialData:
          InternetService.isConnected,
      builder: (context, snapshot) {
        final bool isConnected =
            snapshot.data ?? true;

        return Scaffold(
          body: Column(
            children: [
              if (!isConnected)
                buildOfflineBanner(),

              Expanded(
                child: IndexedStack(
                  index: selectedIndex,
                  children: [
                    isProfileCompleted
                        ? DashboardPage(
                            key: ValueKey(
                              dashboardRefreshKey,
                            ),
                          )
                        : ProfileSetupPage(
                            themeProvider:
                                widget.themeProvider,
                            onProfileCompleted:
                                profileCompleted,
                          ),

                    HistoryPage(
                      key: ValueKey(
                        historyRefreshKey,
                      ),
                    ),

                    GoalsPage(
                      key: ValueKey(
                        goalsRefreshKey,
                      ),
                    ),

                    ProfilePage(
                      key: ValueKey(
                        profileRefreshKey,
                      ),
                    ),

                    SettingsPage(
                      themeProvider:
                          widget.themeProvider,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: changePage,
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                ),
                selectedIcon: Icon(
                  Icons.home,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.history_outlined,
                ),
                selectedIcon: Icon(
                  Icons.history,
                ),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.flag_outlined,
                ),
                selectedIcon: Icon(
                  Icons.flag,
                ),
                label: 'Goals',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                ),
                selectedIcon: Icon(
                  Icons.person,
                ),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.settings_outlined,
                ),
                selectedIcon: Icon(
                  Icons.settings,
                ),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileSetupPage
    extends StatefulWidget {
  final ThemeProvider themeProvider;
  final VoidCallback onProfileCompleted;

  const ProfileSetupPage({
    super.key,
    required this.themeProvider,
    required this.onProfileCompleted,
  });

  @override
  State<ProfileSetupPage> createState() =>
      _ProfileSetupPageState();
}

class _ProfileSetupPageState
    extends State<ProfileSetupPage> {
  DateTime? selectedDate;
  String? selectedOccupation;

  final List<String> occupations = [
    'Student',
    'Employed',
    'Self-Employed',
    'Business Owner',
    'Freelancer',
    'Unemployed',
    'Retired',
    'Other',
  ];

  int calculateAge(DateTime birthDate) {
    final today = DateTime.now();

    int age =
        today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month &&
            today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  Future<void> selectDateOfBirth() async {
    final pickedDate =
        await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> saveProfile() async {
    final prefs =
        await SharedPreferences.getInstance();

    final int age =
        calculateAge(selectedDate!);

    await prefs.setString(
      'age',
      age.toString(),
    );

    await prefs.setString(
      'occupation',
      selectedOccupation!,
    );

    await prefs.setString(
      'dateOfBirth',
      selectedDate!.toIso8601String(),
    );
  }

  Future<void>
      continueToFinancialDetails() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your Date of Birth',
          ),
        ),
      );

      return;
    }

    if (selectedOccupation == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your Occupation',
          ),
        ),
      );

      return;
    }

    await saveProfile();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const FinancialDetailsPage(),
      ),
    );

    if (!mounted) return;

    widget.onProfileCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final int? age =
        selectedDate == null
            ? null
            : calculateAge(
                selectedDate!,
              );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Health Monitor',
        ),
        actions: [
          IconButton(
            tooltip:
                widget.themeProvider.isDarkMode
                    ? 'Light Mode'
                    : 'Dark Mode',
            onPressed: () {
              widget.themeProvider.toggleTheme(
                !widget
                    .themeProvider.isDarkMode,
              );
            },
            icon: Icon(
              widget.themeProvider.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 15),

            const Text(
              'Create Your Financial Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            const Text(
              'Enter your basic details to start your financial health journey.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            InkWell(
              onTap: selectDateOfBirth,
              child: InputDecorator(
                decoration:
                    const InputDecoration(
                  labelText:
                      'Date of Birth',
                  border:
                      OutlineInputBorder(),
                  suffixIcon: Icon(
                    Icons.calendar_month,
                  ),
                ),
                child: Text(
                  selectedDate == null
                      ? 'Select from calendar'
                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
              ),
            ),

            if (age != null) ...[
              const SizedBox(height: 10),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Age: $age years',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue:
                  selectedOccupation,
              decoration:
                  const InputDecoration(
                labelText: 'Occupation',
                border:
                    OutlineInputBorder(),
              ),
              items: occupations
                  .map(
                    (occupation) =>
                        DropdownMenuItem<
                            String>(
                      value: occupation,
                      child:
                          Text(occupation),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedOccupation =
                      value;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    continueToFinancialDetails,
                icon: const Icon(
                  Icons.arrow_forward,
                ),
                label: const Text(
                  'Start Financial Assessment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}