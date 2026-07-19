// NotificationService 占位测试
//
// 现状（2026-07-16）：
//   - notification_service.dart 是 stub，所有方法都是 `if (kIsWeb) return;` 早返回
//   - 真正的通知逻辑（flutter_local_notifications）还没接进来
//   - 这些测试只验证"调用不抛错"，等真实现时再加业务测试

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/services/notification_service.dart';

void main() {
  group('NotificationService 基础', () {
    test('instance 是单例', () {
      expect(NotificationService.instance, isNotNull);
      expect(NotificationService.instance, same(NotificationService.instance));
    });

    test('initialize 调用不抛错（多次调用也安全）', () async {
      await NotificationService.instance.initialize();
      await NotificationService.instance.initialize(); // 第二次不重复初始化
    });
  });

  group('NotificationService 通知方法（早返回，不抛错）', () {
    test('showHabitReminder 不抛错', () async {
      await NotificationService.instance.showHabitReminder(1, '晨跑');
    });

    test('scheduleDailyReminder 不抛错', () async {
      await NotificationService.instance.scheduleDailyReminder(1, 9, 0);
    });

    test('cancelNotification 不抛错', () async {
      await NotificationService.instance.cancelNotification(1);
    });

    test('cancelAllNotifications 不抛错', () async {
      await NotificationService.instance.cancelAllNotifications();
    });
  });
}