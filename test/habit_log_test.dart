// HabitLog 数据模型 unit test
//
// 覆盖行为：
//   - toMap completed=true → 1, completed=false → 0
//   - fromMap 反向解码
//   - roundtrip 一致性
//   - 注意：本 model 没有 copyWith（Dart 实现里没提供）

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/habit_log.dart';

void main() {
  group('HabitLog 构造', () {
    test('必填字段保留', () {
      final l = HabitLog(
        id: 'l1',
        habitId: 'h1',
        date: '2026-07-16',
        completed: true,
      );
      expect(l.id, 'l1');
      expect(l.habitId, 'h1');
      expect(l.date, '2026-07-16');
      expect(l.completed, isTrue);
    });
  });

  group('HabitLog.toMap', () {
    test('completed=true 序列化为 1', () {
      final l = HabitLog(
        id: 'l1',
        habitId: 'h1',
        date: '2026-07-16',
        completed: true,
      );
      expect(l.toMap()['completed'], 1);
    });

    test('completed=false 序列化为 0', () {
      final l = HabitLog(
        id: 'l1',
        habitId: 'h1',
        date: '2026-07-16',
        completed: false,
      );
      expect(l.toMap()['completed'], 0);
    });
  });

  group('HabitLog.fromMap', () {
    test('completed=1 → true', () {
      final l = HabitLog.fromMap({
        'id': 'l1',
        'habitId': 'h1',
        'date': '2026-07-16',
        'completed': 1,
      });
      expect(l.completed, isTrue);
    });

    test('completed=0 → false', () {
      final l = HabitLog.fromMap({
        'id': 'l1',
        'habitId': 'h1',
        'date': '2026-07-16',
        'completed': 0,
      });
      expect(l.completed, isFalse);
    });
  });

  group('HabitLog roundtrip', () {
    test('true 任务往返', () {
      final original = HabitLog(
        id: 'l-99',
        habitId: 'h-1',
        date: '2026-07-16',
        completed: true,
      );
      final restored = HabitLog.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.habitId, original.habitId);
      expect(restored.date, original.date);
      expect(restored.completed, original.completed);
    });

    test('false 任务往返', () {
      final original = HabitLog(
        id: 'l-100',
        habitId: 'h-1',
        date: '2026-07-16',
        completed: false,
      );
      final restored = HabitLog.fromMap(original.toMap());
      expect(restored.completed, isFalse);
    });
  });
}
