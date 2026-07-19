// MoodEntry 业务约束测试
//
// 覆盖行为：
//   - energyLevel 必须在 1-5 之间（不在范围抛 AssertionError）
//   - mood 必须是 happy/neutral/sad/angry 之一（非法值抛 AssertionError）
//   - 合法值正常构造

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/mood_entry.dart';

void main() {
  MoodEntry valid({String mood = 'happy', int energyLevel = 3}) => MoodEntry(
        id: 'me1',
        date: '2026-07-16',
        mood: mood,
        energyLevel: energyLevel,
      );

  group('MoodEntry.energyLevel 范围约束 (1-5)', () {
    test('合法: energyLevel=1 → OK', () {
      expect(valid(energyLevel: 1).energyLevel, 1);
    });

    test('合法: energyLevel=3 → OK', () {
      expect(valid(energyLevel: 3).energyLevel, 3);
    });

    test('合法: energyLevel=5 → OK', () {
      expect(valid(energyLevel: 5).energyLevel, 5);
    });

    test('非法: energyLevel=0 → 抛 AssertionError', () {
      expect(() => valid(energyLevel: 0), throwsA(isA<AssertionError>()));
    });

    test('非法: energyLevel=6 → 抛 AssertionError', () {
      expect(() => valid(energyLevel: 6), throwsA(isA<AssertionError>()));
    });

    test('非法: energyLevel=-1 → 抛 AssertionError', () {
      expect(() => valid(energyLevel: -1), throwsA(isA<AssertionError>()));
    });

    test('非法: energyLevel=100 → 抛 AssertionError', () {
      expect(() => valid(energyLevel: 100), throwsA(isA<AssertionError>()));
    });
  });

  group('MoodEntry.mood 枚举约束 (happy/neutral/sad/angry)', () {
    test('合法: mood=happy → OK', () {
      expect(valid(mood: 'happy').mood, 'happy');
    });

    test('合法: mood=neutral → OK', () {
      expect(valid(mood: 'neutral').mood, 'neutral');
    });

    test('合法: mood=sad → OK', () {
      expect(valid(mood: 'sad').mood, 'sad');
    });

    test('合法: mood=angry → OK', () {
      expect(valid(mood: 'angry').mood, 'angry');
    });

    test('非法: mood=banana → 抛 AssertionError', () {
      expect(() => valid(mood: 'banana'), throwsA(isA<AssertionError>()));
    });

    test('非法: mood=空字符串 → 抛 AssertionError', () {
      expect(() => valid(mood: ''), throwsA(isA<AssertionError>()));
    });

    test('非法: mood=HAPPY (大写) → 抛 AssertionError（区分大小写）', () {
      expect(() => valid(mood: 'HAPPY'), throwsA(isA<AssertionError>()));
    });
  });

  group('MoodEntry roundtrip 与约束交互', () {
    test('合法 MoodEntry roundtrip 一致', () {
      final m = valid(mood: 'sad', energyLevel: 2);
      final restored = MoodEntry.fromMap(m.toMap());
      expect(restored.mood, 'sad');
      expect(restored.energyLevel, 2);
    });
  });
}
