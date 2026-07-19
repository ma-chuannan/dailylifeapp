// DatabaseService web 模式测试
//
// 覆盖行为：
//   - Task / Habit / HabitLog / Diary / MoodEntry 的 CRUD
//   - upsert 语义（重复 id 时 replace 而非新增）
//   - 按 date 过滤查询
//   - 排序（diaries DESC、mood_entries range ASC）
//   - UNIQUE 约束（diary / mood_entry 同 date 只能有一条）
//
// 注意：
//   - DatabaseService 是单例，所有 static 字段共享
//   - 每个测试用 unique date (microsecondsSinceEpoch) 避免测试间数据污染
//   - 测的是 web 模式（_memoryXxx + SharedPreferences mock），native 模式留 TODO

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_life_manager/services/database_service.dart';
import 'package:daily_life_manager/models/task.dart';
import 'package:daily_life_manager/models/habit.dart';
import 'package:daily_life_manager/models/habit_log.dart';
import 'package:daily_life_manager/models/diary.dart';
import 'package:daily_life_manager/models/mood_entry.dart';

/// 每个测试用 unique date，避免 shared static state 污染
String _uniqueDate([String tag = 't']) {
  return 'd-$tag-${DateTime.now().microsecondsSinceEpoch}';
}

/// 每个测试用 unique id，避免 shared static state 污染
String _uniqueId([String tag = 'id']) {
  return '$tag-${DateTime.now().microsecondsSinceEpoch}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // ⚠️ 2026-07-17 Critical #3 修复：先用 resetForTest 清空所有 static 状态
    DatabaseService.resetForTest();
    // 重置 SharedPreferences mock（清空所有存储）
    SharedPreferences.setMockInitialValues({});
    // 切到 web 模式
    DatabaseService.setWebMode(true);
    // 初始化 web 存储（空 prefs → 所有 _memoryXxx 列表为空）
    await DatabaseService.instance.initWebStorage();
  });

  // ==================== Task CRUD ====================

  group('DatabaseService Task CRUD (web 模式)', () {
    test('insertTask + getTasksByDate 能查到插入的 task', () async {
      final date = _uniqueDate('task');
      final t = Task(
        id: _uniqueId('task'),
        content: '买菜',
        category: 'life',
        date: date,
      );

      await DatabaseService.instance.insertTask(t);
      final tasks = await DatabaseService.instance.getTasksByDate(date);

      expect(tasks, hasLength(1));
      expect(tasks.first.id, t.id);
      expect(tasks.first.content, '买菜');
      expect(tasks.first.category, 'life');
    });

    test('insertTask 重复 id 应该 replace（upsert 语义）', () async {
      final date = _uniqueDate('upsert');
      final id = _uniqueId('upsert');

      final t1 = Task(id: id, content: '原内容', category: 'work', date: date);
      final t2 = Task(id: id, content: '新内容', category: 'work', date: date);

      await DatabaseService.instance.insertTask(t1);
      await DatabaseService.instance.insertTask(t2);

      final tasks = await DatabaseService.instance.getTasksByDate(date);
      expect(tasks, hasLength(1)); // 不是 2 个
      expect(tasks.first.content, '新内容');
    });

    test('updateTask 改字段', () async {
      final date = _uniqueDate('update');
      final id = _uniqueId('update');
      await DatabaseService.instance.insertTask(
        Task(id: id, content: '原', category: 'work', date: date),
      );

      final updated = Task(
        id: id,
        content: '改后',
        category: 'life',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 7, 1, 12, 0),
        date: date,
      );
      await DatabaseService.instance.updateTask(updated);

      final tasks = await DatabaseService.instance.getTasksByDate(date);
      expect(tasks, hasLength(1));
      expect(tasks.first.content, '改后');
      expect(tasks.first.category, 'life');
      expect(tasks.first.isCompleted, isTrue);
    });

    test('updateTask 不存在的 id 应该静默忽略（不抛错）', () async {
      // updateTask 内部用 indexWhere，index < 0 时不操作
      // 不应抛错也不应新增
      final fake = Task(
        id: _uniqueId('nonexist'),
        content: 'x',
        category: 'work',
        date: _uniqueDate('no'),
      );
      await DatabaseService.instance.updateTask(fake);

      final tasks = await DatabaseService.instance.getTasksByDate(fake.date);
      expect(tasks, isEmpty);
    });

    test('deleteTask 删除指定 id，其他保留', () async {
      final date = _uniqueDate('delete');
      await DatabaseService.instance.insertTask(
        Task(id: _uniqueId('a'), content: 'a', category: 'work', date: date),
      );
      await DatabaseService.instance.insertTask(
        Task(id: _uniqueId('b'), content: 'b', category: 'work', date: date),
      );

      // 先取出两个 id
      final tasks = await DatabaseService.instance.getTasksByDate(date);
      expect(tasks, hasLength(2));
      await DatabaseService.instance.deleteTask(tasks[0].id);

      final remaining = await DatabaseService.instance.getTasksByDate(date);
      expect(remaining, hasLength(1));
      expect(remaining.first.id, tasks[1].id);
    });

    test('getTasksByDate 只返回该 date 的任务（隔离）', () async {
      final dateA = _uniqueDate('A');
      final dateB = _uniqueDate('B');

      await DatabaseService.instance.insertTask(
        Task(id: _uniqueId('a'), content: 'a', category: 'work', date: dateA),
      );
      await DatabaseService.instance.insertTask(
        Task(id: _uniqueId('b'), content: 'b', category: 'work', date: dateB),
      );

      expect((await DatabaseService.instance.getTasksByDate(dateA)).map((t) => t.content),
          ['a']);
      expect((await DatabaseService.instance.getTasksByDate(dateB)).map((t) => t.content),
          ['b']);
    });

    test('getTasksByDate 不存在的 date 返回空', () async {
      final tasks = await DatabaseService.instance.getTasksByDate(_uniqueDate('empty'));
      expect(tasks, isEmpty);
    });
  });

  // ==================== Habit CRUD ====================

  group('DatabaseService Habit CRUD (web 模式)', () {
    test('insertHabit + getAllHabits 能查到', () async {
      final h = Habit(
        id: _uniqueId('habit'),
        name: '晨跑',
        targetFrequency: 3,
        currentStreak: 0,
        createdAt: DateTime.utc(2026, 7, 1),
      );
      await DatabaseService.instance.insertHabit(h);

      final habits = await DatabaseService.instance.getAllHabits();
      // 注意：getAllHabits 返回全部，包括其他测试残留的数据
      // 所以断言"包含"，而不是"等于"
      expect(habits.any((x) => x.id == h.id), isTrue);
    });

    test('insertHabit 重复 id 应该 replace（upsert）', () async {
      final id = _uniqueId('habit-up');
      await DatabaseService.instance.insertHabit(
        Habit(id: id, name: '原', targetFrequency: 1, createdAt: DateTime.utc(2026, 7, 1)),
      );
      await DatabaseService.instance.insertHabit(
        Habit(id: id, name: '新', targetFrequency: 7, createdAt: DateTime.utc(2026, 7, 1)),
      );

      final habits = await DatabaseService.instance.getAllHabits();
      final h = habits.firstWhere((x) => x.id == id);
      expect(h.name, '新');
      expect(h.targetFrequency, 7);
    });

    test('updateHabit 改字段', () async {
      final id = _uniqueId('habit-update');
      await DatabaseService.instance.insertHabit(
        Habit(id: id, name: 'x', targetFrequency: 1, createdAt: DateTime.utc(2026, 7, 1)),
      );
      await DatabaseService.instance.updateHabit(
        Habit(
          id: id,
          name: 'y',
          targetFrequency: 5,
          currentStreak: 10,
          createdAt: DateTime.utc(2026, 7, 1),
        ),
      );

      final h = (await DatabaseService.instance.getAllHabits())
          .firstWhere((x) => x.id == id);
      expect(h.name, 'y');
      expect(h.targetFrequency, 5);
      expect(h.currentStreak, 10);
    });

    test('deleteHabit 删除指定 id', () async {
      final id = _uniqueId('habit-del');
      await DatabaseService.instance.insertHabit(
        Habit(id: id, name: 'x', targetFrequency: 1, createdAt: DateTime.utc(2026, 7, 1)),
      );
      expect(
          (await DatabaseService.instance.getAllHabits()).any((x) => x.id == id),
          isTrue);

      await DatabaseService.instance.deleteHabit(id);
      expect(
          (await DatabaseService.instance.getAllHabits()).any((x) => x.id == id),
          isFalse);
    });
  });

  // ==================== HabitLog CRUD ====================

  group('DatabaseService HabitLog CRUD (web 模式)', () {
    test('insertHabitLog + getHabitLogsByHabitId 过滤正确', () async {
      final habitId = _uniqueId('hl');
      final otherHabitId = _uniqueId('hl-other');
      final date = _uniqueDate('hl');

      await DatabaseService.instance.insertHabitLog(
        HabitLog(id: _uniqueId('l1'), habitId: habitId, date: date, completed: true),
      );
      await DatabaseService.instance.insertHabitLog(
        HabitLog(id: _uniqueId('l2'), habitId: habitId, date: date, completed: false),
      );
      await DatabaseService.instance.insertHabitLog(
        HabitLog(id: _uniqueId('l3'), habitId: otherHabitId, date: date, completed: true),
      );

      final logs = await DatabaseService.instance.getHabitLogsByHabitId(habitId);
      expect(logs, hasLength(2));
      expect(logs.every((l) => l.habitId == habitId), isTrue);
    });

    test('getHabitLogsByDate 按 date 过滤', () async {
      final habitId = _uniqueId('hl-date');
      final dateA = _uniqueDate('hl-A');
      final dateB = _uniqueDate('hl-B');

      await DatabaseService.instance.insertHabitLog(
        HabitLog(id: _uniqueId('a'), habitId: habitId, date: dateA, completed: true),
      );
      await DatabaseService.instance.insertHabitLog(
        HabitLog(id: _uniqueId('b'), habitId: habitId, date: dateB, completed: true),
      );

      expect((await DatabaseService.instance.getHabitLogsByDate(dateA)).length, 1);
      expect((await DatabaseService.instance.getHabitLogsByDate(dateB)).length, 1);
    });

    test('insertHabitLog 重复 id 应该 replace（upsert）', () async {
      final habitId = _uniqueId('hl-up');
      final date = _uniqueDate('hl-up');
      final id = _uniqueId('hl-up-id');

      await DatabaseService.instance.insertHabitLog(
        HabitLog(id: id, habitId: habitId, date: date, completed: false),
      );
      await DatabaseService.instance.insertHabitLog(
        HabitLog(id: id, habitId: habitId, date: date, completed: true),
      );

      final logs = await DatabaseService.instance.getHabitLogsByHabitId(habitId);
      expect(logs, hasLength(1));
      expect(logs.first.completed, isTrue);
    });

    test('deleteHabitLog 删除', () async {
      final habitId = _uniqueId('hl-del');
      final date = _uniqueDate('hl-del');
      final id = _uniqueId('hl-del-id');

      await DatabaseService.instance.insertHabitLog(
        HabitLog(id: id, habitId: habitId, date: date, completed: true),
      );
      expect((await DatabaseService.instance.getHabitLogsByHabitId(habitId)), hasLength(1));

      await DatabaseService.instance.deleteHabitLog(id);
      expect((await DatabaseService.instance.getHabitLogsByHabitId(habitId)), isEmpty);
    });
  });

  // ==================== Diary CRUD ====================

  group('DatabaseService Diary CRUD (web 模式)', () {
    test('insertDiary + getDiaryByDate 返回单条', () async {
      final date = _uniqueDate('diary');
      final d = Diary(id: _uniqueId('diary'), date: date, content: '今天天气好');

      await DatabaseService.instance.insertDiary(d);
      final got = await DatabaseService.instance.getDiaryByDate(date);

      expect(got, isNotNull);
      expect(got!.id, d.id);
      expect(got.content, '今天天气好');
    });

    test('getDiaryByDate 不存在的 date 返回 null', () async {
      final got = await DatabaseService.instance.getDiaryByDate(_uniqueDate('nope'));
      expect(got, isNull);
    });

    test('insertDiary 重复 id 应该 replace（upsert）', () async {
      // 注意：web 模式只按 id removeWhere，不处理 date UNIQUE
      // sqflite 因为 schema 上 date UNIQUE 约束会强制 replace
      // 此处只测"按 id upsert"这条共同路径
      final date = _uniqueDate('diary-up');
      final id = _uniqueId('diary-up');

      await DatabaseService.instance.insertDiary(
        Diary(id: id, date: date, content: '原内容'),
      );
      await DatabaseService.instance.insertDiary(
        Diary(id: id, date: date, content: '新内容'),
      );

      final got = await DatabaseService.instance.getDiaryByDate(date);
      expect(got, isNotNull);
      expect(got!.content, '新内容');
    });

    // ⭐ 2026-07-17 Critical #4 修复验证：web 模式按 date UNIQUE 处理（与 sqflite 一致）
    test('insertDiary 同 date 不同 id 应该 replace（web 模式 UNIQUE）', () async {
      final date = _uniqueDate('diary-date-unique');

      await DatabaseService.instance.insertDiary(
        Diary(id: _uniqueId('a'), date: date, content: '原内容'),
      );
      await DatabaseService.instance.insertDiary(
        Diary(id: _uniqueId('b'), date: date, content: '新内容'),
      );

      // 同 date 只能一条（与 sqflite schema `date UNIQUE` 一致）
      final got = await DatabaseService.instance.getDiaryByDate(date);
      expect(got, isNotNull);
      expect(got!.content, '新内容');
      // 验证只有一条（不是 2 条）
      final all = await DatabaseService.instance.getAllDiaries();
      expect(all.where((d) => d.date == date).length, 1);
    });

    test('getAllDiaries 按 date DESC 排序（最新在前）', () async {
      const dateOld = '2026-01-01';
      const dateMid = '2026-06-01';
      const dateNew = '2026-12-31';

      await DatabaseService.instance.insertDiary(
        Diary(id: _uniqueId('o'), date: dateOld, content: 'old'),
      );
      await DatabaseService.instance.insertDiary(
        Diary(id: _uniqueId('m'), date: dateMid, content: 'mid'),
      );
      await DatabaseService.instance.insertDiary(
        Diary(id: _uniqueId('n'), date: dateNew, content: 'new'),
      );

      final all = await DatabaseService.instance.getAllDiaries();
      // 过滤这三条（避免跟其他测试残留混）
      final ours = all.where((d) =>
          d.date == dateOld || d.date == dateMid || d.date == dateNew).toList();
      expect(ours.length, 3);
      expect(ours.map((d) => d.date).toList(),
          [dateNew, dateMid, dateOld]); // DESC
    });
  });

  // ==================== MoodEntry CRUD ====================

  group('DatabaseService MoodEntry CRUD (web 模式)', () {
    test('insertMoodEntry + getMoodEntryByDate 返回单条', () async {
      final date = _uniqueDate('mood');
      final m = MoodEntry(
        id: _uniqueId('mood'),
        date: date,
        mood: 'happy',
        energyLevel: 4,
      );

      await DatabaseService.instance.insertMoodEntry(m);
      final got = await DatabaseService.instance.getMoodEntryByDate(date);

      expect(got, isNotNull);
      expect(got!.mood, 'happy');
      expect(got.energyLevel, 4);
    });

    test('getMoodEntryByDate 不存在的 date 返回 null', () async {
      final got =
          await DatabaseService.instance.getMoodEntryByDate(_uniqueDate('mood-nope'));
      expect(got, isNull);
    });

    test('insertMoodEntry 重复 id 应该 replace（upsert）', () async {
      // 注意：web 模式只按 id removeWhere，不处理 date UNIQUE
      // sqflite 因为 schema 上 date UNIQUE 约束会强制 replace
      // 此处只测"按 id upsert"这条共同路径
      final date = _uniqueDate('mood-up');
      final id = _uniqueId('mood-up');

      await DatabaseService.instance.insertMoodEntry(
        MoodEntry(id: id, date: date, mood: 'sad', energyLevel: 1),
      );
      await DatabaseService.instance.insertMoodEntry(
        MoodEntry(id: id, date: date, mood: 'happy', energyLevel: 5),
      );

      final got = await DatabaseService.instance.getMoodEntryByDate(date);
      expect(got, isNotNull);
      expect(got!.mood, 'happy');
      expect(got.energyLevel, 5);
    });

    // ⭐ 2026-07-17 Critical #4 修复验证：web 模式按 date UNIQUE 处理
    test('insertMoodEntry 同 date 不同 id 应该 replace（web 模式 UNIQUE）', () async {
      final date = _uniqueDate('mood-date-unique');

      await DatabaseService.instance.insertMoodEntry(
        MoodEntry(id: _uniqueId('a'), date: date, mood: 'sad', energyLevel: 1),
      );
      await DatabaseService.instance.insertMoodEntry(
        MoodEntry(id: _uniqueId('b'), date: date, mood: 'happy', energyLevel: 5),
      );

      final got = await DatabaseService.instance.getMoodEntryByDate(date);
      expect(got, isNotNull);
      expect(got!.mood, 'happy');
      // 验证 getMoodEntriesByDateRange 也只返回 1 条
      final ranged = await DatabaseService.instance.getMoodEntriesByDateRange(date, date);
      expect(ranged.length, 1);
    });

    test('getMoodEntriesByDateRange 按范围过滤 + 按 date ASC 排序', () async {
      // 用专门的日期方便排序断言
      const start = '2026-01-01';
      const mid = '2026-06-15';
      const end = '2026-12-31';
      const outOfRange = '2025-12-31';

      await DatabaseService.instance.insertMoodEntry(
        MoodEntry(id: _uniqueId('start'), date: start, mood: 'happy', energyLevel: 3),
      );
      await DatabaseService.instance.insertMoodEntry(
        MoodEntry(id: _uniqueId('mid'), date: mid, mood: 'sad', energyLevel: 2),
      );
      await DatabaseService.instance.insertMoodEntry(
        MoodEntry(id: _uniqueId('end'), date: end, mood: 'happy', energyLevel: 5),
      );
      await DatabaseService.instance.insertMoodEntry(
        MoodEntry(id: _uniqueId('out'), date: outOfRange, mood: 'sad', energyLevel: 1),
      );

      final ranged =
          await DatabaseService.instance.getMoodEntriesByDateRange(start, end);
      // 过滤我们 4 条
      final ours = ranged.where((m) =>
          m.date == start || m.date == mid || m.date == end || m.date == outOfRange
      ).toList();
      expect(ours, hasLength(3)); // outOfRange 不在范围
      expect(ours.map((m) => m.date).toList(), [start, mid, end]); // ASC
    });
  });
}