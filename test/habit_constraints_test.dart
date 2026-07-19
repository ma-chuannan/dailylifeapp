// Habit 业务约束测试
//
// 覆盖行为：
//   - targetFrequency 必须 > 0
//   - currentStreak 必须 >= 0
//   - 合法值正常构造

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/habit.dart';

void main() {
  Habit valid({int targetFrequency = 3, int currentStreak = 0}) => Habit(
        id: 'h1',
        name: '晨跑',
        targetFrequency: targetFrequency,
        currentStreak: currentStreak,
        createdAt: DateTime.utc(2026, 7, 1),
      );

  group('Habit.targetFrequency 范围约束 (>0)', () {
    test('合法: targetFrequency=1 → OK', () {
      expect(valid(targetFrequency: 1).targetFrequency, 1);
    });

    test('合法: targetFrequency=7 → OK', () {
      expect(valid(targetFrequency: 7).targetFrequency, 7);
    });

    test('合法: targetFrequency=100 → OK', () {
      expect(valid(targetFrequency: 100).targetFrequency, 100);
    });

    test('非法: targetFrequency=0 → 抛 AssertionError', () {
      expect(() => valid(targetFrequency: 0), throwsA(isA<AssertionError>()));
    });

    test('非法: targetFrequency=-1 → 抛 AssertionError', () {
      expect(() => valid(targetFrequency: -1), throwsA(isA<AssertionError>()));
    });

    test('非法: targetFrequency=-100 → 抛 AssertionError', () {
      expect(() => valid(targetFrequency: -100), throwsA(isA<AssertionError>()));
    });
  });

  group('Habit.currentStreak 范围约束 (>=0)', () {
    test('合法: currentStreak=0 (默认值) → OK', () {
      final h = Habit(
        id: 'h1',
        name: 'x',
        targetFrequency: 3,
        createdAt: DateTime.utc(2026, 7, 1),
        // 不传 currentStreak，应该默认 0
      );
      expect(h.currentStreak, 0);
    });

    test('合法: currentStreak=5 → OK', () {
      expect(valid(currentStreak: 5).currentStreak, 5);
    });

    test('合法: currentStreak=1000 → OK', () {
      expect(valid(currentStreak: 1000).currentStreak, 1000);
    });

    test('非法: currentStreak=-1 → 抛 AssertionError', () {
      expect(() => valid(currentStreak: -1), throwsA(isA<AssertionError>()));
    });

    test('非法: currentStreak=-100 → 抛 AssertionError', () {
      expect(() => valid(currentStreak: -100), throwsA(isA<AssertionError>()));
    });
  });

  group('Habit 双重约束', () {
    test('同时违反两个约束（targetFrequency=0, currentStreak=-1）→ 抛 assert', () {
      expect(
        () => Habit(
          id: 'h1',
          name: 'x',
          targetFrequency: 0,
          currentStreak: -1,
          createdAt: DateTime.utc(2026, 7, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Habit roundtrip 与约束交互', () {
    test('合法 Habit roundtrip 一致', () {
      final h = valid(targetFrequency: 7, currentStreak: 14);
      final restored = Habit.fromMap(h.toMap());
      expect(restored.targetFrequency, 7);
      expect(restored.currentStreak, 14);
    });

    test('toMap 输出不包含负值 (因为 roundtrip 一致)', () {
      final h = valid(targetFrequency: 5, currentStreak: 0);
      final m = h.toMap();
      expect(m['targetFrequency'], 5);
      expect(m['currentStreak'], 0);
    });
  });
}
