// MoodEntry 数据模型 unit test
//
// 覆盖行为：
//   - 构造（mood 字符串枚举, energyLevel 1-5）
//   - toMap / fromMap
//   - roundtrip
//   - copyWith
//   - 边界：energyLevel 边界值 1 和 5
//
// 注意：本 model 没有运行时校验 energyLevel 范围，测试只验证它能正确序列化

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/mood_entry.dart';

void main() {
  group('MoodEntry 构造', () {
    test('必填字段保留', () {
      final m = MoodEntry(
        id: 'me1',
        date: '2026-07-16',
        mood: 'happy',
        energyLevel: 4,
      );
      expect(m.id, 'me1');
      expect(m.date, '2026-07-16');
      expect(m.mood, 'happy');
      expect(m.energyLevel, 4);
    });

    test('支持所有约定的 mood 取值', () {
      for (final mood in ['happy', 'neutral', 'sad', 'angry']) {
        final m = MoodEntry(
          id: 'me1',
          date: '2026-07-16',
          mood: mood,
          energyLevel: 3,
        );
        expect(m.mood, mood);
      }
    });
  });

  group('MoodEntry.toMap', () {
    test('所有字段被序列化', () {
      final m = MoodEntry(
        id: 'me1',
        date: '2026-07-16',
        mood: 'happy',
        energyLevel: 4,
      );
      final mp = m.toMap();
      expect(mp['id'], 'me1');
      expect(mp['date'], '2026-07-16');
      expect(mp['mood'], 'happy');
      expect(mp['energyLevel'], 4);
    });
  });

  group('MoodEntry.fromMap', () {
    test('所有字段被反序列化', () {
      final m = MoodEntry.fromMap({
        'id': 'me1',
        'date': '2026-07-16',
        'mood': 'sad',
        'energyLevel': 2,
      });
      expect(m.id, 'me1');
      expect(m.date, '2026-07-16');
      expect(m.mood, 'sad');
      expect(m.energyLevel, 2);
    });
  });

  group('MoodEntry roundtrip', () {
    test('典型 happy 高能量往返', () {
      final original = MoodEntry(
        id: 'me-99',
        date: '2026-07-16',
        mood: 'happy',
        energyLevel: 5,
      );
      final restored = MoodEntry.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.date, original.date);
      expect(restored.mood, original.mood);
      expect(restored.energyLevel, original.energyLevel);
    });

    test('energyLevel 边界 1 往返', () {
      final original = MoodEntry(
        id: 'me-1',
        date: '2026-07-16',
        mood: 'sad',
        energyLevel: 1,
      );
      final restored = MoodEntry.fromMap(original.toMap());
      expect(restored.energyLevel, 1);
    });

    test('energyLevel 边界 5 往返', () {
      final original = MoodEntry(
        id: 'me-5',
        date: '2026-07-16',
        mood: 'happy',
        energyLevel: 5,
      );
      final restored = MoodEntry.fromMap(original.toMap());
      expect(restored.energyLevel, 5);
    });
  });

  group('MoodEntry.copyWith', () {
    final base = MoodEntry(
      id: 'me1',
      date: '2026-07-16',
      mood: 'happy',
      energyLevel: 3,
    );

    test('只改 mood', () {
      final c = base.copyWith(mood: 'sad');
      expect(c.mood, 'sad');
      expect(c.energyLevel, base.energyLevel);
      expect(c.id, base.id);
      expect(c.date, base.date);
    });

    test('只改 energyLevel', () {
      final c = base.copyWith(energyLevel: 5);
      expect(c.energyLevel, 5);
      expect(c.mood, base.mood);
    });

    test('不改任何字段', () {
      final c = base.copyWith();
      expect(c.id, base.id);
      expect(c.date, base.date);
      expect(c.mood, base.mood);
      expect(c.energyLevel, base.energyLevel);
    });

    test('同时改多个字段', () {
      final c = base.copyWith(mood: 'angry', energyLevel: 1);
      expect(c.mood, 'angry');
      expect(c.energyLevel, 1);
      expect(c.id, base.id);
      expect(c.date, base.date);
    });
  });
}
