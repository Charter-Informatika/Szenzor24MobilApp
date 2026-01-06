
import 'package:flutter/services.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance = NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  static const MethodChannel _channel = MethodChannel('hutomero/notifications');

  Future<void> init() async {
    try {
      await _channel.invokeMethod('init');
    } catch (_) {}
  }

  Future<bool> showWarningChanged({required int id, required String title, required String body}) async {
    try {
      final res = await _channel.invokeMethod('show', {'id': id, 'title': title, 'body': body});
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
