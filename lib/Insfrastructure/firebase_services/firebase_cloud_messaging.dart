import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
    print("Background message data: ${message.data}");
    print("Background notification: ${message.notification?.title}");
  }

  // This is critical: we need to create the notification channel here too
  // for Android background notifications to work properly
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  if (message.notification != null) {
    final androidNotificationDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }
}

class FirebaseCloudMessagingService {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Add this channel variable at class level
  AndroidNotificationChannel? channel;

  // Initialize everything needed for notifications
  Future<void> initialize(BuildContext context) async {
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create notification channel for Android
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // Register the channel with the system
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel!);

    // Update FCM settings
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Initialize local notifications
    await initLocalNotifications(context);

    // Setup message listeners for different app states
    initializeFirebaseMessaging();

    // Request permissions
    requestNotificationPermission();
  }

  Future<String> getToken() async {
    String? token = await firebaseMessaging.getToken();
    return token!;
  }

  void listenForTokenRefresh(Function(String) onTokenRefresh) {
    firebaseMessaging.onTokenRefresh.listen((newToken) {
      onTokenRefresh(newToken);
      if (kDebugMode) {
        print("New Token: $newToken");
      }
    });
  }

  Future<void> sendNotification({
    required String targetFcmToken,
    required String title,
    required String body,
  }) async {
    final url = Uri.parse(
      'https://testpushnotification-ljs2nswqra-an.a.run.app',
    );

    final payload = {"FCM_Token": targetFcmToken, "title": title, "body": body};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("✅ Notification sent successfully");
        }
      } else {
        if (kDebugMode) {
          print("❌ Failed to send notification: ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Error calling function: $e");
      }
    }
  }

  void requestNotificationPermission() async {
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('User granted provisional permission');
      }
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
      AppSettings.openAppSettings();
    }
  }

  Future<void> initLocalNotifications(BuildContext context) async {
    var androidInitializationSettings = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    var iosInitializationSettings = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    var initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        _handleNotificationTap(details, context);
      },
    );
  }

  void _handleNotificationTap(
    NotificationResponse details,
    BuildContext context,
  ) {
    // Handle notification tap based on payload if needed
    if (kDebugMode) {
      print("Notification tapped: ${details.payload}");
    }
    // Navigate to specific screen based on notification if needed
  }

  void initializeFirebaseMessaging() {
    // 1. Foreground messages (app is open and in use)
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print("Foreground message received: ${message.notification?.title}");
      }
      showNotication(message);
    });

    // 2. When app is in background but opened and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        print("Background notification tapped: ${message.notification?.title}");
      }
      // Handle navigation or specific action based on notification
    });

    // 3. Check for initial message (app was terminated)
    firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        if (kDebugMode) {
          print(
            "App opened from terminated state via notification: ${message.notification?.title}",
          );
        }
        // Handle navigation or specific action based on notification
      }
    });
  }

  Future<void> showNotication(RemoteMessage message) async {
    // Ensure we have a channel created
    if (channel == null) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel!);
    }

    // Android-specific notification details
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel!.id,
          channel!.name,
          channelDescription: channel!.description,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@mipmap/ic_launcher',
          sound: RawResourceAndroidNotificationSound('sound'),
        );

    // iOS-specific notification details
    DarwinNotificationDetails darwinNotificationDetails =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // Build payload if needed for when notification is tapped
    String payload = jsonEncode({
      'type': message.data['type'] ?? 'default',
      'id': message.data['id'] ?? '',
    });

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      notificationDetails,
      payload: payload,
    );
  }
}
