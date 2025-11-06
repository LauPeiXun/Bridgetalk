import 'package:bridgetalk/Insfrastructure/firebase_services/firebase_auth_service.dart';
import 'package:bridgetalk/presentation/screens/auth/onboarding_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/firebase_options.dart';
import 'package:bridgetalk/presentation/screens/chat/chat_lobby_screen.dart';
import 'package:bridgetalk/presentation/screens/auth/login_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('sound'),
  );

  // Initialize the channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseAuthService authService = FirebaseAuthService();

  final bool loggedIn = authService.currentUser != null;
  final bool firstTime = await checkFirstTime();

  runApp(
    MyApp(
      loggedIn: loggedIn,
      firstTime: firstTime,
      flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle your background message here (e.g., show notifications)
}

// Function to check if it's first time
Future<bool> checkFirstTime() async {
  final prefs = await SharedPreferences.getInstance();
  final bool? onboardingCompleted = prefs.getBool('onboarding_completed');
  return onboardingCompleted == null || onboardingCompleted == false;
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  final bool firstTime;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const MyApp({
    super.key,
    required this.loggedIn,
    required this.firstTime,
    required this.flutterLocalNotificationsPlugin,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BridgeTalk',
      theme: ThemeData(fontFamily: 'PlayfairDisplay'),
      home:
          firstTime
              ? const OnboardingScreen()
              : loggedIn
              ? const ChatLobbyScreen()
              : const LoginScreen(),
    );
  }
}
