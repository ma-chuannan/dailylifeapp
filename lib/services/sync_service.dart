import 'dart:html';
import 'package:supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/diary.dart';
import '../models/mood_entry.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  late SupabaseClient _client;
  bool _isInitialized = false;
  String? _userId;

  // Cloud sync 配置：通过 dart-define 注入。**绝对不要**在源码里硬编码 Supabase key。
  // 启用方法：`flutter build web --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxx`
  // 未注入时（_url 或 _anonKey 为空字符串），cloud sync 自动禁用，所有方法 no-op。
  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static bool get _cloudEnabled => _url.isNotEmpty && _anonKey.isNotEmpty;

  // 固定的本地存储 key
  static const String _localStorageUserIdKey = 'dailylife_user_id';
  static const String _defaultUserId = 'dailylife_fixed_user_v1';

  SyncService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Only create the Supabase client if cloud sync is enabled. Skipping this
    // when disabled avoids touching a misconfigured URL on every startup.
    if (_cloudEnabled) {
      _client = SupabaseClient(_url, _anonKey);
    }

    // 获取或创建固定的 user ID
    _userId = window.localStorage[_localStorageUserIdKey];
    if (_userId == null || _userId!.isEmpty) {
      _userId = _defaultUserId;
      window.localStorage[_localStorageUserIdKey] = _userId!;
    }

    _isInitialized = true;
  }

  String get userId => _userId ?? '';

  // ==================== Tasks ====================

  Future<void> syncTasks(List<Task> tasks) async {
    if (!_cloudEnabled) return;
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final taskMaps = tasks.map((t) => {
      'id': t.id,
      'content': t.content,
      'category': t.category,
      // ⚠️ 2026-07-17 Critical #5: 写 int (0/1) 与 Task.fromMap 的 `== 1` 解码对齐
      'isCompleted': t.isCompleted ? 1 : 0,
      'completedAt': t.completedAt?.toIso8601String(),
      'date': t.date,
      'user_id': uid,
    }).toList();

    // Use upsert instead of delete+insert to prevent data loss
    if (taskMaps.isNotEmpty) {
      await _client.from('tasks').upsert(taskMaps, onConflict: 'id');
    }
  }

  Future<List<Task>> getTasks() async {
    if (!_cloudEnabled) return [];
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final response = await _client
        .from('tasks')
        .select()
        .eq('user_id', uid);

    return (response as List)
        .map((map) => Task.fromMap(map))
        .toList();
  }

  ///恢复模式：不依赖 user_id，直接获取所有任务（用于数据恢复）
  Future<List<Task>> recoverTasks() async {
    if (!_cloudEnabled) return [];
    if (!_isInitialized) await initialize();

    final response = await _client
        .from('tasks')
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((map) => Task.fromMap(map))
        .toList();
  }

  // ==================== Habits ====================

  Future<void> syncHabits(List<Habit> habits) async {
    if (!_cloudEnabled) return;
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final habitMaps = habits.map((h) => {
      'id': h.id,
      'name': h.name,
      'targetFrequency': h.targetFrequency,
      'currentStreak': h.currentStreak,
      'createdAt': h.createdAt.toIso8601String(),
      'user_id': uid,
    }).toList();

        await _client.from('habits').upsert(habitMaps, onConflict: 'id');
  }

  Future<List<Habit>> getHabits() async {
    if (!_cloudEnabled) return [];
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final response = await _client
        .from('habits')
        .select()
        .eq('user_id', uid);

    return (response as List)
        .map((map) => Habit.fromMap(map))
        .toList();
  }

  // ==================== Habit Logs ====================

  Future<void> syncHabitLogs(List<HabitLog> logs) async {
    if (!_cloudEnabled) return;
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final logMaps = logs.map((l) => {
      'id': l.id,
      'habitId': l.habitId,
      'date': l.date,
      // ⚠️ 2026-07-17 Critical #5: 写 int (0/1) 与 HabitLog.fromMap 的 `raw is int && raw == 1` 对齐
      'completed': l.completed ? 1 : 0,
      'user_id': uid,
    }).toList();

        await _client.from('habit_logs').upsert(logMaps, onConflict: 'id');
  }

  Future<List<HabitLog>> getHabitLogs() async {
    if (!_cloudEnabled) return [];
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final response = await _client
        .from('habit_logs')
        .select()
        .eq('user_id', uid);

    return (response as List)
        .map((map) => HabitLog.fromMap(map))
        .toList();
  }

  // ==================== Diaries ====================

  Future<void> syncDiaries(List<Diary> diaries) async {
    if (!_cloudEnabled) return;
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final diaryMaps = diaries.map((d) => {
      'id': d.id,
      'date': d.date,
      'content': d.content,
      'user_id': uid,
    }).toList();

    await _client.from('diaries').upsert(diaryMaps, onConflict: 'id');
  }

  Future<List<Diary>> getDiaries() async {
    if (!_cloudEnabled) return [];
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final response = await _client
        .from('diaries')
        .select()
        .eq('user_id', uid);

    return (response as List)
        .map((map) => Diary.fromMap(map))
        .toList();
  }

  // ==================== Mood Entries ====================

  Future<void> syncMoodEntries(List<MoodEntry> entries) async {
    if (!_cloudEnabled) return;
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final entryMaps = entries.map((e) => {
      'id': e.id,
      'date': e.date,
      'mood': e.mood,
      'energyLevel': e.energyLevel,
      'user_id': uid,
    }).toList();

    await _client.from('mood_entries').upsert(entryMaps, onConflict: 'id');
  }

  Future<List<MoodEntry>> getMoodEntries() async {
    if (!_cloudEnabled) return [];
    if (!_isInitialized) await initialize();
    final uid = _userId ?? '';

    final response = await _client
        .from('mood_entries')
        .select()
        .eq('user_id', uid);

    return (response as List)
        .map((map) => MoodEntry.fromMap(map))
        .toList();
  }

  // ==================== Full Sync ====================

  Future<void> syncAll({
    required List<Task> tasks,
    required List<Habit> habits,
    required List<HabitLog> habitLogs,
    required List<Diary> diaries,
    required List<MoodEntry> moodEntries,
  }) async {
    await Future.wait([
      syncTasks(tasks),
      syncHabits(habits),
      syncHabitLogs(habitLogs),
      syncDiaries(diaries),
      syncMoodEntries(moodEntries),
    ]);
  }
}