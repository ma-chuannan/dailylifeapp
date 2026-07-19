import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<void> showHabitReminder(int id, String habitName) async {
    // Notifications only work on mobile, skip on web
    if (kIsWeb) return;
  }

  Future<void> scheduleDailyReminder(int id, int hour, int minute) async {
    // Notifications only work on mobile, skip on web
    if (kIsWeb) return;
  }

  Future<void> cancelNotification(int id) async {
    // Notifications only work on mobile, skip on web
    if (kIsWeb) return;
  }

  Future<void> cancelAllNotifications() async {
    // Notifications only work on mobile, skip on web
    if (kIsWeb) return;
  }
}