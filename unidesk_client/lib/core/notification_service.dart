import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    // Request permissions for Android 13+ and iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    _initialized = true;
    _startListening();
  }

  void _startListening() {
    if (kIsWeb) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription?.cancel();
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isSeen', isEqualTo: false) // Only listen for unseen
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final createdAt = data['createdAt'] as Timestamp?;
            // Show system notification if created recently (e.g., last 10 seconds)
            if (createdAt != null &&
                DateTime.now().difference(createdAt.toDate()).inSeconds < 10) {
              _showLocalNotification(data, change.doc.id);
            }
          }
        }
      }
    });
  }

  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  Future<void> _showLocalNotification(
      Map<String, dynamic> data, String docId) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'unidesk_service_updates', // channel id
      'Service Updates', // channel name
      channelDescription: 'Notifications for service ticket updates',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final title = data['title'] ?? 'Ticket Update';
    final body = data['body'] ?? 'Your service ticket has been updated.';

    await _flutterLocalNotificationsPlugin.show(
      docId.hashCode, // unique id, using hashcode of docId
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
