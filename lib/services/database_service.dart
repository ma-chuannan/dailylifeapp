import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/diary.dart';
import '../models/mood_entry.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  static bool _isWebMode = false;
  static SharedPreferences? _prefs;

  // Keys for web storage
  static const String _keyTasks = 'web_tasks';
  static const String _keyHabits = 'web_habits';
  static const String _keyHabitLogs = 'web_habit_logs';
  static const String _keyDiaries = 'web_diaries';
  static const String _keyMoodEntries = 'web_mood_entries';

  // In-memory storage for web
  static List<Map<String, dynamic>> _memoryTasks = [];
  static List<Map<String, dynamic>> _memoryHabits = [];
  static List<Map<String, dynamic>> _memoryHabitLogs = [];
  static List<Map<String, dynamic>> _memoryDiaries = [];
  static List<Map<String, dynamic>> _memoryMoodEntries = [];

  DatabaseService._init();

  static void setWebMode(bool value) {
    _isWebMode = value;
  }

  bool get isWeb => _isWebMode;

  Future<void> initWebStorage() async {
    if (!_isWebMode) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadFromStorage();
  }

  /// ⚠️ 2026-07-17 Critical #3 修复：测试用，重置所有 static 状态。
  /// 测试 setUp 必须先调这个再调 initWebStorage()，否则 _memoryXxx 列表跨测试累积。
  /// 仅供测试使用（@visibleForTesting 会在 lint 时警告非测试代码调用）。
  @visibleForTesting
  static void resetForTest() {
    _memoryTasks.clear();
    _memoryHabits.clear();
    _memoryHabitLogs.clear();
    _memoryDiaries.clear();
    _memoryMoodEntries.clear();
    _database = null;
    _prefs = null;
    _isWebMode = false;
  }

  Future<void> _loadFromStorage() async {
    if (_prefs == null) return;

    final tasksJson = _prefs!.getString(_keyTasks);
    if (tasksJson != null && tasksJson.isNotEmpty) {
      final decoded = jsonDecode(tasksJson) as List;
      _memoryTasks = decoded.cast<Map<String, dynamic>>();
    }

    final habitsJson = _prefs!.getString(_keyHabits);
    if (habitsJson != null && habitsJson.isNotEmpty) {
      final decoded = jsonDecode(habitsJson) as List;
      _memoryHabits = decoded.cast<Map<String, dynamic>>();
    }

    final logsJson = _prefs!.getString(_keyHabitLogs);
    if (logsJson != null && logsJson.isNotEmpty) {
      final decoded = jsonDecode(logsJson) as List;
      _memoryHabitLogs = decoded.cast<Map<String, dynamic>>();
    }

    final diariesJson = _prefs!.getString(_keyDiaries);
    if (diariesJson != null && diariesJson.isNotEmpty) {
      final decoded = jsonDecode(diariesJson) as List;
      _memoryDiaries = decoded.cast<Map<String, dynamic>>();
    }

    final moodsJson = _prefs!.getString(_keyMoodEntries);
    if (moodsJson != null && moodsJson.isNotEmpty) {
      final decoded = jsonDecode(moodsJson) as List;
      _memoryMoodEntries = decoded.cast<Map<String, dynamic>>();
    }
  }

  Future<void> _saveTasksToStorage() async {
    if (_prefs == null) return;
    await _prefs!.setString(_keyTasks, jsonEncode(_memoryTasks));
  }

  Future<void> _saveHabitsToStorage() async {
    if (_prefs == null) return;
    await _prefs!.setString(_keyHabits, jsonEncode(_memoryHabits));
  }

  Future<void> _saveHabitLogsToStorage() async {
    if (_prefs == null) return;
    await _prefs!.setString(_keyHabitLogs, jsonEncode(_memoryHabitLogs));
  }

  Future<void> _saveDiariesToStorage() async {
    if (_prefs == null) return;
    await _prefs!.setString(_keyDiaries, jsonEncode(_memoryDiaries));
  }

  Future<void> _saveMoodEntriesToStorage() async {
    if (_prefs == null) return;
    await _prefs!.setString(_keyMoodEntries, jsonEncode(_memoryMoodEntries));
  }

  Future<Database> get database async {
    if (_isWebMode) throw StateError('Use in-memory storage on web');
    if (_database != null) return _database!;
    _database = await _initDB('daily_life.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        completedAt TEXT,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        targetFrequency INTEGER NOT NULL,
        currentStreak INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (habitId) REFERENCES habits (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE diaries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE mood_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        mood TEXT NOT NULL,
        energyLevel INTEGER NOT NULL
      )
    ''');
  }

  // Task CRUD
  Future<void> insertTask(Task task) async {
    if (_isWebMode) {
      _memoryTasks.removeWhere((t) => t['id'] == task.id);
      _memoryTasks.add(task.toMap());
      await _saveTasksToStorage();
      return;
    }
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasksByDate(String date) async {
    if (_isWebMode) {
      return _memoryTasks.where((t) => t['date'] == date).map((map) => Task.fromMap(map)).toList();
    }
    final db = await database;
    final result = await db.query('tasks', where: 'date = ?', whereArgs: [date]);
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    if (_isWebMode) {
      final index = _memoryTasks.indexWhere((t) => t['id'] == task.id);
      if (index >= 0) _memoryTasks[index] = task.toMap();
      await _saveTasksToStorage();
      return;
    }
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(String id) async {
    if (_isWebMode) {
      _memoryTasks.removeWhere((t) => t['id'] == id);
      await _saveTasksToStorage();
      return;
    }
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Habit CRUD
  Future<void> insertHabit(Habit habit) async {
    if (_isWebMode) {
      _memoryHabits.removeWhere((h) => h['id'] == habit.id);
      _memoryHabits.add(habit.toMap());
      await _saveHabitsToStorage();
      return;
    }
    final db = await database;
    await db.insert('habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Habit>> getAllHabits() async {
    if (_isWebMode) {
      return _memoryHabits.map((map) => Habit.fromMap(map)).toList();
    }
    final db = await database;
    final result = await db.query('habits');
    return result.map((map) => Habit.fromMap(map)).toList();
  }

  Future<void> updateHabit(Habit habit) async {
    if (_isWebMode) {
      final index = _memoryHabits.indexWhere((h) => h['id'] == habit.id);
      if (index >= 0) _memoryHabits[index] = habit.toMap();
      await _saveHabitsToStorage();
      return;
    }
    final db = await database;
    await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<void> deleteHabit(String id) async {
    if (_isWebMode) {
      _memoryHabits.removeWhere((h) => h['id'] == id);
      await _saveHabitsToStorage();
      return;
    }
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // HabitLog CRUD
  Future<void> insertHabitLog(HabitLog log) async {
    if (_isWebMode) {
      _memoryHabitLogs.removeWhere((l) => l['id'] == log.id);
      _memoryHabitLogs.add(log.toMap());
      await _saveHabitLogsToStorage();
      return;
    }
    final db = await database;
    await db.insert('habit_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HabitLog>> getHabitLogsByHabitId(String habitId) async {
    if (_isWebMode) {
      return _memoryHabitLogs.where((l) => l['habitId'] == habitId).map((map) => HabitLog.fromMap(map)).toList();
    }
    final db = await database;
    final result = await db.query('habit_logs', where: 'habitId = ?', whereArgs: [habitId]);
    return result.map((map) => HabitLog.fromMap(map)).toList();
  }

  Future<List<HabitLog>> getHabitLogsByDate(String date) async {
    if (_isWebMode) {
      return _memoryHabitLogs.where((l) => l['date'] == date).map((map) => HabitLog.fromMap(map)).toList();
    }
    final db = await database;
    final result = await db.query('habit_logs', where: 'date = ?', whereArgs: [date]);
    return result.map((map) => HabitLog.fromMap(map)).toList();
  }

  Future<void> deleteHabitLog(String id) async {
    if (_isWebMode) {
      _memoryHabitLogs.removeWhere((l) => l['id'] == id);
      await _saveHabitLogsToStorage();
      return;
    }
    final db = await database;
    await db.delete('habit_logs', where: 'id = ?', whereArgs: [id]);
  }

  // Diary CRUD
  Future<void> insertDiary(Diary diary) async {
    if (_isWebMode) {
      // ⚠️ 2026-07-17 Critical #4: web 模式也按 date UNIQUE 处理（与 sqflite schema 一致）
      // 之前只 removeWhere(id)，导致同 date 多条共存，getDiaryByDate 返回 .first 行为模糊
      _memoryDiaries.removeWhere((d) => d['id'] == diary.id);
      _memoryDiaries.removeWhere((d) => d['date'] == diary.date);
      _memoryDiaries.add(diary.toMap());
      await _saveDiariesToStorage();
      return;
    }
    final db = await database;
    await db.insert('diaries', diary.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Diary?> getDiaryByDate(String date) async {
    if (_isWebMode) {
      final results = _memoryDiaries.where((d) => d['date'] == date).toList();
      if (results.isEmpty) return null;
      return Diary.fromMap(results.first);
    }
    final db = await database;
    final result = await db.query('diaries', where: 'date = ?', whereArgs: [date]);
    if (result.isEmpty) return null;
    return Diary.fromMap(result.first);
  }

  Future<List<Diary>> getAllDiaries() async {
    if (_isWebMode) {
      final sorted = List<Map<String, dynamic>>.from(_memoryDiaries);
      sorted.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return sorted.map((map) => Diary.fromMap(map)).toList();
    }
    final db = await database;
    final result = await db.query('diaries', orderBy: 'date DESC');
    return result.map((map) => Diary.fromMap(map)).toList();
  }

  // MoodEntry CRUD
  Future<void> insertMoodEntry(MoodEntry entry) async {
    if (_isWebMode) {
      // ⚠️ 2026-07-17 Critical #4: 同 insertDiary，web 模式按 date UNIQUE 处理
      _memoryMoodEntries.removeWhere((m) => m['id'] == entry.id);
      _memoryMoodEntries.removeWhere((m) => m['date'] == entry.date);
      _memoryMoodEntries.add(entry.toMap());
      await _saveMoodEntriesToStorage();
      return;
    }
    final db = await database;
    await db.insert('mood_entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<MoodEntry?> getMoodEntryByDate(String date) async {
    if (_isWebMode) {
      final results = _memoryMoodEntries.where((m) => m['date'] == date).toList();
      if (results.isEmpty) return null;
      return MoodEntry.fromMap(results.first);
    }
    final db = await database;
    final result = await db.query('mood_entries', where: 'date = ?', whereArgs: [date]);
    if (result.isEmpty) return null;
    return MoodEntry.fromMap(result.first);
  }

  Future<List<MoodEntry>> getMoodEntriesByDateRange(String startDate, String endDate) async {
    if (_isWebMode) {
      final filtered = _memoryMoodEntries.where((m) =>
        (m['date'] as String).compareTo(startDate) >= 0 &&
        (m['date'] as String).compareTo(endDate) <= 0
      ).toList();
      filtered.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      return filtered.map((map) => MoodEntry.fromMap(map)).toList();
    }
    final db = await database;
    final result = await db.query(
      'mood_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return result.map((map) => MoodEntry.fromMap(map)).toList();
  }
}