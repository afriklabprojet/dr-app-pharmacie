import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp(); // Valid only if you init Firebase here too
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      print("Firebase not initialized. NotificationService disabled.");
      return;
    }
    
    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      // 1. Request Permission
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // 2. Initialize Local Notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle notification tap
          print("Notification tapped with payload: ${response.payload}");
        },
      );

      // Create the high importance channel ensuring sound is enabled
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'orders_channel',
            'Commandes Reçues',
            description: 'Notifications pour les nouvelles commandes',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      // 3. Setup Foreground Handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          _showLocalNotification(message);
        }
      });

      // 4. Setup Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // 5. Get Token
      final token = await getToken();
      print("FCM Token: $token");
      
    } catch (e) {
      print("Error initializing NotificationService: $e");
    }
  }

  Future<String?> getToken() async {
    if (_firebaseMessaging == null) return null;
    try {
      return await _firebaseMessaging!.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'orders_channel', // id
            'Commandes Reçues', // title
            channelDescription: 'Notifications pour les nouvelles commandes',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}
