// Diary 数据模型 unit test
//
// 覆盖行为：
//   - 必填字段保留
//   - toMap / fromMap
//   - roundtrip
//   - copyWith
//   - 边界：content 为空字符串

import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_manager/models/diary.dart';

void main() {
  group('Diary 构造', () {
    test('必填字段保留', () {
      final d = Diary(
        id: 'd1',
        date: '2026-07-16',
        content: '今天去爬山',
      );
      expect(d.id, 'd1');
      expect(d.date, '2026-07-16');
      expect(d.content, '今天去爬山');
    });
  });

  group('Diary.toMap', () {
    test('所有字段都被序列化', () {
      final d = Diary(
        id: 'd1',
        date: '2026-07-16',
        content: '内容',
      );
      final m = d.toMap();
      expect(m['id'], 'd1');
      expect(m['date'], '2026-07-16');
      expect(m['content'], '内容');
    });
  });

  group('Diary.fromMap', () {
    test('所有字段被反序列化', () {
      final d = Diary.fromMap({
        'id': 'd1',
        'date': '2026-07-16',
        'content': '内容',
      });
      expect(d.id, 'd1');
      expect(d.date, '2026-07-16');
      expect(d.content, '内容');
    });
  });

  group('Diary roundtrip', () {
    test('长 content 往返一致', () {
      final longContent = '今天发生了很多事。' * 100;
      final original = Diary(
        id: 'd-99',
        date: '2026-07-16',
        content: longContent,
      );
      final restored = Diary.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.date, original.date);
      expect(restored.content, original.content);
    });

    test('空 content 往返一致', () {
      final original = Diary(id: 'd-1', date: '2026-07-16', content: '');
      final restored = Diary.fromMap(original.toMap());
      expect(restored.content, '');
    });
  });

  group('Diary.copyWith', () {
    final base = Diary(
      id: 'd1',
      date: '2026-07-16',
      content: '原内容',
    );

    test('只改 content', () {
      final c = base.copyWith(content: '新内容');
      expect(c.content, '新内容');
      expect(c.id, base.id);
      expect(c.date, base.date);
    });

    test('只改 date', () {
      final c = base.copyWith(date: '2026-07-17');
      expect(c.date, '2026-07-17');
      expect(c.content, base.content);
    });

    test('不改任何字段', () {
      final c = base.copyWith();
      expect(c.id, base.id);
      expect(c.date, base.date);
      expect(c.content, base.content);
    });
  });
}
