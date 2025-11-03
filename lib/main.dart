import 'package:app_usage_tracker/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/stats_screen.dart';
import 'screens/command_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/parent_dashboard_screen.dart';
import 'screens/child_usage_view_screen.dart';
import 'services/fcm_service.dart';
import 'services/role_service.dart';
import 'services/child_usage_tracking_service.dart';
import 'services/theme_service.dart';
import 'services/app_limit_service.dart';
import 'services/family_link_service.dart';
import 'utils/app_theme.dart';

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
      // Always try to initialize Firebase, handle duplicate app gracefully
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');

      // Initialize FCM after Firebase
      await FCMService.initialize();

      // Update FCM tokens in linking database
      await _updateFCMTokens();

      // Start listening for commands if in child mode
      final role = await RoleService.getRole();
      if (role == AppRole.child) {
        await FCMService.startListeningForCommands();
        // Start child usage tracking and syncing
        await ChildUsageTrackingService.startChildModeTracking();
      }
    } catch (e) {
      // If Firebase is already initialized, that's fine
      if (e.toString().contains('duplicate-app')) {
        debugPrint('Firebase already initialized, continuing...');
      } else {
        debugPrint('Firebase/FCM initialization failed: $e');
        debugPrint('App will continue with limited functionality');
        // Continue app initialization even if FCM fails
      }
    }
  } else {
    debugPrint('Running in web mode - Firebase features disabled');
  }

  // Initialize app limit service for notifications
  try {
    await AppLimitService().initialize();
    debugPrint('AppLimitService initialized');
  } catch (e) {
    debugPrint('AppLimitService initialization failed: $e');
  }

  runApp(const MyApp());
}

/// Update FCM tokens for existing links
Future<void> _updateFCMTokens() async {
  try {
    final role = await RoleService.getRole();
    if (role == AppRole.child) {
      await FamilyLinkService.updateChildFCMToken();
    } else if (role == AppRole.parent) {
      await FamilyLinkService.updateParentFCMToken();
    }
  } catch (e) {
    debugPrint('Error updating FCM tokens: $e');
  }
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
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
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
                  NotificationScreen(),
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
