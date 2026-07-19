// Task 数据模型 unit test
//
// 覆盖行为：
//   - 构造默认值（isCompleted 默认 false, completedAt 默认 null）
//   - toMap 布尔转 int、DateTime 转 ISO8601
//   - fromMap int 转布尔、ISO8601 转 DateTime
//   - toMap → fromMap 往返一致性
//   - copyWith 只改指定字段，未指定字段保持原值
//   - copyWith 不传任何参数返回等价实例
//   - completedAt 为 null 时序列化为 null，反序列化也得到 null

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/task.dart';

void main() {
  group('Task 构造', () {
    test('默认值 isCompleted=false, completedAt=null', () {
      final t = Task(
        id: 't1',
        content: '买牛奶',
        category: 'life',
        date: '2026-07-16',
      );
      expect(t.isCompleted, isFalse);
      expect(t.completedAt, isNull);
    });

    test('必填字段被保留', () {
      final t = Task(
        id: 't2',
        content: '写周报',
        category: 'work',
        date: '2026-07-16',
      );
      expect(t.id, 't2');
      expect(t.content, '写周报');
      expect(t.category, 'work');
      expect(t.date, '2026-07-16');
    });
  });

  group('Task.toMap', () {
    test('isCompleted=true 序列化为 1', () {
      final t = Task(
        id: 't1',
        content: 'x',
        category: 'work',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 16, 12, 0, 0),
        date: '2026-07-16',
      );
      expect(t.toMap()['isCompleted'], 1);
    });

    test('isCompleted=false 序列化为 0', () {
      final t = Task(
        id: 't1',
        content: 'x',
        category: 'work',
        date: '2026-07-16',
      );
      expect(t.toMap()['isCompleted'], 0);
    });

    test('completedAt=null 序列化为 null', () {
      final t = Task(
        id: 't1',
        content: 'x',
        category: 'work',
        date: '2026-07-16',
      );
      expect(t.toMap()['completedAt'], isNull);
    });

    test('completedAt=DateTime 序列化为 ISO8601 字符串', () {
      final t = Task(
        id: 't1',
        content: 'x',
        category: 'work',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 16, 12, 30, 45),
        date: '2026-07-16',
      );
      expect(t.toMap()['completedAt'], '2026-07-16T12:30:45.000Z');
    });
  });

  group('Task.fromMap', () {
    test('isCompleted=1 反序列化为 true', () {
      final t = Task.fromMap({
        'id': 't1',
        'content': 'x',
        'category': 'work',
        'isCompleted': 1,
        'completedAt': '2026-07-16T10:00:00.000Z',
        'date': '2026-07-16',
      });
      expect(t.isCompleted, isTrue);
    });

    test('isCompleted=0 反序列化为 false', () {
      final t = Task.fromMap({
        'id': 't1',
        'content': 'x',
        'category': 'work',
        'isCompleted': 0,
        'completedAt': null,
        'date': '2026-07-16',
      });
      expect(t.isCompleted, isFalse);
    });

    test('completedAt=null 反序列化为 null', () {
      final t = Task.fromMap({
        'id': 't1',
        'content': 'x',
        'category': 'work',
        'isCompleted': 0,
        'completedAt': null,
        'date': '2026-07-16',
      });
      expect(t.completedAt, isNull);
    });

    test('completedAt=ISO8601 字符串反序列化为 DateTime', () {
      final t = Task.fromMap({
        'id': 't1',
        'content': 'x',
        'category': 'work',
        'isCompleted': 1,
        'completedAt': '2026-07-16T12:30:45.000Z',
        'date': '2026-07-16',
      });
      expect(t.completedAt, DateTime.utc(2026, 7, 16, 12, 30, 45));
    });
  });

  group('Task roundtrip', () {
    test('toMap -> fromMap 往返后所有字段保持一致', () {
      final original = Task(
        id: 't-99',
        content: '买菜',
        category: 'life',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 16, 9, 0, 0),
        date: '2026-07-16',
      );
      final restored = Task.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.category, original.category);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.completedAt, original.completedAt);
      expect(restored.date, original.date);
    });

    test('未完成任务的往返', () {
      final original = Task(
        id: 't-1',
        content: 'c',
        category: 'other',
        date: '2026-07-16',
      );
      final restored = Task.fromMap(original.toMap());
      expect(restored.isCompleted, isFalse);
      expect(restored.completedAt, isNull);
    });
  });

  group('Task.copyWith', () {
    final base = Task(
      id: 't1',
      content: '原内容',
      category: 'work',
      isCompleted: false,
      date: '2026-07-16',
    );

    test('只改 content, 其他字段保持', () {
      final copy = base.copyWith(content: '新内容');
      expect(copy.content, '新内容');
      expect(copy.id, base.id);
      expect(copy.category, base.category);
      expect(copy.isCompleted, base.isCompleted);
      expect(copy.date, base.date);
    });

    test('标为已完成: isCompleted 改 true 同时设置 completedAt', () {
      final copy = base.copyWith(
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 16, 12, 0, 0),
      );
      expect(copy.isCompleted, isTrue);
      expect(copy.completedAt, DateTime.utc(2026, 7, 16, 12, 0, 0));
      expect(copy.content, base.content);
      expect(copy.category, base.category);
    });

    test('不改任何字段得到等价实例', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.content, base.content);
      expect(copy.category, base.category);
      expect(copy.isCompleted, base.isCompleted);
      expect(copy.date, base.date);
    });

    test('同时改多个字段: 标为已完成 + 改 category', () {
      final copy = base.copyWith(
        category: 'life',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 16, 12, 0, 0),
      );
      expect(copy.category, 'life');
      expect(copy.isCompleted, isTrue);
      expect(copy.completedAt, DateTime.utc(2026, 7, 16, 12, 0, 0));
      expect(copy.content, base.content);
    });

    // ⭐ Regression test for Critical #1 (reviewer demo 2026-07-17 抓到)
    // 之前用 `completedAt ?? this.completedAt` 时传 null 不会清空，
    // 导致 toggleTaskCompletion 取消完成任务时 isCompleted=false 但 completedAt 仍是旧值，
    // 触发 isCompleted==completedAt!=null 的 assert。
    // 修复：用 sentinel 对象区分"未传"和"传 null"。
    test('regression: 显式传 null 应该清空 completedAt（Critical #1 修复验证）', () {
      final completed = Task(
        id: 't1',
        content: 'x',
        category: 'work',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 16, 12, 0, 0),
        date: '2026-07-16',
      );

      final uncompleted = completed.copyWith(
        isCompleted: false,
        completedAt: null,  // 显式传 null，必须真清空
      );

      expect(uncompleted.isCompleted, isFalse);
      expect(uncompleted.completedAt, isNull);   // ← 关键断言
    });

    test('regression: 不传 completedAt 应该保留原值（sentinel 路径验证）', () {
      // 这个测试确保 sentinel 路径不被破坏：copyWith() 不传参数时所有字段保留
      final completed = Task(
        id: 't1',
        content: 'x',
        category: 'work',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 16, 12, 0, 0),
        date: '2026-07-16',
      );

      final copy = completed.copyWith(content: 'y');  // 只改 content

      expect(copy.content, 'y');
      expect(copy.isCompleted, completed.isCompleted);     // 保留 true
      expect(copy.completedAt, completed.completedAt);     // 保留原值
    });
  });
}
