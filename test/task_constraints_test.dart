// Task 业务约束测试
//
// 覆盖行为：
//   - isCompleted 和 completedAt 必须一致
//   - 非法状态组合应该抛 AssertionError（开发期）

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/task.dart';

void main() {
  group('Task isCompleted/completedAt 一致性约束', () {
    test('合法: isCompleted=true, completedAt 有值 → OK', () {
      final t = Task(
        id: 't1',
        content: 'x',
        category: 'work',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 16),
        date: '2026-07-16',
      );
      expect(t.isCompleted, isTrue);
      expect(t.completedAt, isNotNull);
    });

    test('合法: isCompleted=false, completedAt=null → OK', () {
      final t = Task(
        id: 't1',
        content: 'x',
        category: 'work',
        date: '2026-07-16',
      );
      expect(t.isCompleted, isFalse);
      expect(t.completedAt, isNull);
    });

    test('非法: isCompleted=true 但 completedAt=null → 抛 AssertionError', () {
      expect(
        () => Task(
          id: 't1',
          content: 'x',
          category: 'work',
          isCompleted: true,
          // 故意不传 completedAt
          date: '2026-07-16',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('非法: isCompleted=false 但 completedAt 有值 → 抛 AssertionError', () {
      expect(
        () => Task(
          id: 't1',
          content: 'x',
          category: 'work',
          isCompleted: false,
          completedAt: DateTime.utc(2026, 7, 16),
          date: '2026-07-16',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Task fromMap 后的状态约束', () {
    test('fromMap 合法数据 (isCompleted=1, completedAt 有) → 构造成功', () {
      final t = Task.fromMap({
        'id': 't1',
        'content': 'x',
        'category': 'work',
        'isCompleted': 1,
        'completedAt': '2026-07-16T10:00:00.000Z',
        'date': '2026-07-16',
      });
      expect(t.isCompleted, isTrue);
      expect(t.completedAt, isNotNull);
    });

    test('fromMap 合法数据 (isCompleted=0, completedAt=null) → 构造成功', () {
      final t = Task.fromMap({
        'id': 't1',
        'content': 'x',
        'category': 'work',
        'isCompleted': 0,
        'completedAt': null,
        'date': '2026-07-16',
      });
      expect(t.isCompleted, isFalse);
      expect(t.completedAt, isNull);
    });

    test('fromMap 不一致数据 (isCompleted=1 但 completedAt=null) → 抛 assert', () {
      // 这个测试揭示 fromMap 也能触发 assert（因为 fromMap 内部调构造器）
      expect(
        () => Task.fromMap({
          'id': 't1',
          'content': 'x',
          'category': 'work',
          'isCompleted': 1,
          'completedAt': null, // 与 isCompleted=1 不一致
          'date': '2026-07-16',
        }),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
