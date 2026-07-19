// HabitLog fromMap 防御性测试
//
// 覆盖行为：
//   - bool 输入（true/false）应该安全降级为 false
//   - null 输入应该安全降级为 false（不抛 NoSuchMethodError）
//   - 缺字段应该安全降级为 false
//   - 正常 int 0/1 仍然正确

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/habit_log.dart';

void main() {
  Map<String, dynamic> base() => {
        'id': 'l1',
        'habitId': 'h1',
        'date': '2026-07-16',
      };

  group('HabitLog.fromMap 防御性', () {
    test('正常: completed=1 (int) → true', () {
      final l = HabitLog.fromMap({...base(), 'completed': 1});
      expect(l.completed, isTrue);
    });

    test('正常: completed=0 (int) → false', () {
      final l = HabitLog.fromMap({...base(), 'completed': 0});
      expect(l.completed, isFalse);
    });

    test('防御: completed=true (bool) → 安全降级为 false', () {
      // 关键修复：如果外部传 bool true，旧代码会错误返回 false（true != 1）
      // 新代码应该同样返回 false（bool 也不能 == 1），但**不抛错**
      final l = HabitLog.fromMap({...base(), 'completed': true});
      expect(l.completed, isFalse);
    });

    test('防御: completed=false (bool) → false', () {
      final l = HabitLog.fromMap({...base(), 'completed': false});
      expect(l.completed, isFalse);
    });

    test('防御: completed=null → 安全降级为 false（不抛 NoSuchMethodError）', () {
      final l = HabitLog.fromMap({...base(), 'completed': null});
      expect(l.completed, isFalse);
    });

    test('防御: 缺 completed 字段 → 安全降级为 false（不抛 NoSuchMethodError）', () {
      final l = HabitLog.fromMap(base()); // 没有 'completed' key
      expect(l.completed, isFalse);
    });
  });
}
