import 'package:app_usage_tracker/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/stats_screen.dart';
import 'screens/command_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/parent_dashboard_screen.dart';
import 'screens/child_usage_view_screen.dart';
import 'services/fcm_service.dart';
import 'services/role_service.dart';
import 'services/child_usage_tracking_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // Initialize theme service
  await ThemeService().initializeTheme();

  // Initialize Firebase only on mobile platforms (requires config files)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize FCM after Firebase
      await FCMService.initialize();

      // Start listening for commands if in child mode
      final role = await RoleService.getRole();
      if (role == AppRole.child) {
        await FCMService.startListeningForCommands();
        // Start child usage tracking and syncing
        await ChildUsageTrackingService.startChildModeTracking();
      }
    } catch (e) {
      // Handle Firebase/FCM initialization errors gracefully
      debugPrint('Firebase/FCM initialization failed: $e');
    }
  } else {
    debugPrint('Running in web mode - Firebase features disabled');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'App Usage Tracker',
          theme: ThemeService().lightTheme,
          darkTheme: ThemeService().darkTheme,
          themeMode: ThemeService().isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          routes: {
            '/child-usage-view': (context) => const ChildUsageViewScreen(),
          },
          home: DefaultTabController(
            length: 5,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('App Usage Tracker'),
                actions: [
                  FutureBuilder<AppRole>(
                    future: RoleService.getRole(),
                    builder: (context, snapshot) {
                      final isParent = snapshot.data == AppRole.parent;
                      return isParent
                          ? IconButton(
                              icon: const Icon(Icons.family_restroom),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ParentDashboardScreen(),
                                  ),
                                );
                              },
                              tooltip: 'Parent Dashboard',
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.calendar_today)),
                    Tab(icon: Icon(Icons.home_filled)),
                    Tab(icon: Icon(Icons.notifications)),
                    Tab(icon: Icon(Icons.control_camera)),
                    Tab(icon: Icon(Icons.settings)),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  StatsScreen(),
                  HomeScreen(),
                  Icon(Icons.notifications),
                  CommandScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
