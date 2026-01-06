import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'api_client.dart';
import '../models/mobile_alert.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Timer? _pollTimer;
  List<int> _previousAlertIds = [];

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings);
  }

  /// Start monitoring for new alerts. Call this from your main app.
  void startMonitoring(ApiClient api, String sessionCookie,
      {Duration pollInterval = const Duration(minutes: 1)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) async {
      await _checkForNewAlerts(api, sessionCookie);
    });
  }

  /// Stop monitoring for alerts
  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkForNewAlerts(ApiClient api, String sessionCookie) async {
    try {
      final alerts = await api.getAlerts(sessionCookie);
      final currentAlertIds = alerts.map((a) => a.id).toList();

      // Find new alerts
      final newAlerts = alerts
          .where((alert) => !_previousAlertIds.contains(alert.id))
          .toList();

      if (newAlerts.isNotEmpty) {
        for (final alert in newAlerts) {
          await _showNotification(alert);
        }
      }

      _previousAlertIds = currentAlertIds;
    } catch (e) {
      print('Error checking for alerts: $e');
    }
  }

  Future<void> _showNotification(MobileAlert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'alert_channel',
      'Riasztások',
      channelDescription: 'Új riasztások értesítése',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      alert.id,
      '⚠️ Új riasztás',
      '${alert.sensorName}: ${alert.value} (${alert.type})',
      notificationDetails,
    );
  }
}
