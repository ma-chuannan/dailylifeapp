// Habit 数据模型 unit test
//
// 覆盖行为：
//   - 构造默认值（currentStreak 默认 0）
//   - toMap 把 DateTime 转 ISO8601
//   - fromMap 把 ISO8601 转 DateTime；缺失 currentStreak 时用 0
//   - toMap → fromMap 往返一致性
//   - copyWith 局部修改

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/habit.dart';

void main() {
  final created = DateTime.utc(2026, 7, 1, 8, 0, 0);

  group('Habit 构造', () {
    test('currentStreak 默认 0', () {
      final h = Habit(
        id: 'h1',
        name: '晨跑',
        targetFrequency: 3,
        createdAt: created,
      );
      expect(h.currentStreak, 0);
    });

    test('必填字段保留', () {
      final h = Habit(
        id: 'h1',
        name: '晨跑',
        targetFrequency: 5,
        createdAt: created,
      );
      expect(h.id, 'h1');
      expect(h.name, '晨跑');
      expect(h.targetFrequency, 5);
      expect(h.createdAt, created);
    });
  });

  group('Habit.toMap', () {
    test('createdAt 转 ISO8601 字符串', () {
      final h = Habit(
        id: 'h1',
        name: '晨跑',
        targetFrequency: 3,
        createdAt: created,
      );
      expect(h.toMap()['createdAt'], '2026-07-01T08:00:00.000Z');
    });

    test('currentStreak 序列化为 int', () {
      final h = Habit(
        id: 'h1',
        name: '晨跑',
        targetFrequency: 3,
        currentStreak: 7,
        createdAt: created,
      );
      expect(h.toMap()['currentStreak'], 7);
    });
  });

  group('Habit.fromMap', () {
    test('createdAt 从 ISO8601 转回 DateTime', () {
      final h = Habit.fromMap({
        'id': 'h1',
        'name': '晨跑',
        'targetFrequency': 3,
        'currentStreak': 5,
        'createdAt': '2026-07-01T08:00:00.000Z',
      });
      expect(h.createdAt, created);
    });

    test('currentStreak 缺失时默认为 0', () {
      final h = Habit.fromMap({
        'id': 'h1',
        'name': '晨跑',
        'targetFrequency': 3,
        'createdAt': '2026-07-01T08:00:00.000Z',
      });
      expect(h.currentStreak, 0);
    });
  });

  group('Habit roundtrip', () {
    test('toMap -> fromMap 后字段一致', () {
      final original = Habit(
        id: 'h-99',
        name: '冥想',
        targetFrequency: 7,
        currentStreak: 14,
        createdAt: created,
      );
      final restored = Habit.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.targetFrequency, original.targetFrequency);
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('Habit.copyWith', () {
    final base = Habit(
      id: 'h1',
      name: '晨跑',
      targetFrequency: 3,
      currentStreak: 5,
      createdAt: created,
    );

    test('只改 name', () {
      final c = base.copyWith(name: '夜跑');
      expect(c.name, '夜跑');
      expect(c.targetFrequency, base.targetFrequency);
      expect(c.currentStreak, base.currentStreak);
    });

    test('只改 streak', () {
      final c = base.copyWith(currentStreak: 6);
      expect(c.currentStreak, 6);
      expect(c.name, base.name);
    });

    test('不改任何字段', () {
      final c = base.copyWith();
      expect(c.id, base.id);
      expect(c.name, base.name);
      expect(c.targetFrequency, base.targetFrequency);
      expect(c.currentStreak, base.currentStreak);
      expect(c.createdAt, base.createdAt);
    });
  });
}
