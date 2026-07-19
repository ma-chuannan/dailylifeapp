import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  Map<String, List<HabitLog>> _habitLogs = {};
  final _uuid = const Uuid();

  List<Habit> get habits => _habits;

  Future<void> loadAllHabits() async {
    _habits = await DatabaseService.instance.getAllHabits();
    for (final habit in _habits) {
      _habitLogs[habit.id] = await DatabaseService.instance.getHabitLogsByHabitId(habit.id);
    }
    notifyListeners();
  }

  Future<void> loadHabitLogsByDate(String date) async {
    final logs = await DatabaseService.instance.getHabitLogsByDate(date);
    for (final log in logs) {
      if (_habitLogs.containsKey(log.habitId)) {
        final existingIndex = _habitLogs[log.habitId]!.indexWhere((l) => l.date == date);
        if (existingIndex != -1) {
          _habitLogs[log.habitId]![existingIndex] = log;
        } else {
          _habitLogs[log.habitId]!.add(log);
        }
      }
    }
    notifyListeners();
  }

  Future<void> addHabit(String name, int targetFrequency) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      targetFrequency: targetFrequency,
      currentStreak: 0,
      createdAt: DateTime.now(),
    );
    await DatabaseService.instance.insertHabit(habit);
    _habits.add(habit);
    _habitLogs[habit.id] = [];
    _syncToCloud();
    notifyListeners();
  }

  Future<void> toggleHabitLog(String habitId, String date) async {
    final logs = _habitLogs[habitId] ?? [];
    final existingLog = logs.where((l) => l.date == date).firstOrNull;

    if (existingLog != null) {
      final updatedLog = HabitLog(
        id: existingLog.id,
        habitId: habitId,
        date: date,
        completed: !existingLog.completed,
      );
      await DatabaseService.instance.insertHabitLog(updatedLog);
      final index = logs.indexWhere((l) => l.id == existingLog.id);
      logs[index] = updatedLog;
    } else {
      final newLog = HabitLog(
        id: _uuid.v4(),
        habitId: habitId,
        date: date,
        completed: true,
      );
      await DatabaseService.instance.insertHabitLog(newLog);
      logs.add(newLog);

      final habit = _habits.firstWhere((h) => h.id == habitId);
      final updatedStreak = _calculateStreak(habitId);
      final updatedHabit = habit.copyWith(currentStreak: updatedStreak);
      await DatabaseService.instance.updateHabit(updatedHabit);
      final habitIndex = _habits.indexWhere((h) => h.id == habitId);
      _habits[habitIndex] = updatedHabit;
    }
    _syncToCloud();
    notifyListeners();
  }

  int _calculateStreak(String habitId) {
    final logs = _habitLogs[habitId] ?? [];
    final completedLogs = logs.where((l) => l.completed).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (completedLogs.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final log in completedLogs) {
      final logDate = DateTime.parse(log.date);
      final diff = checkDate.difference(logDate).inDays;
      if (diff <= 1) {
        streak++;
        checkDate = logDate;
      } else {
        break;
      }
    }
    return streak;
  }

  bool isHabitCompletedOnDate(String habitId, String date) {
    final logs = _habitLogs[habitId] ?? [];
    return logs.any((l) => l.date == date && l.completed);
  }

  Future<void> deleteHabit(String habitId) async {
    await DatabaseService.instance.deleteHabit(habitId);
    _habits.removeWhere((h) => h.id == habitId);
    _habitLogs.remove(habitId);
    _syncToCloud();
    notifyListeners();
  }

  Future<void> updateHabitName(String habitId, String name) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];
      final updatedHabit = habit.copyWith(name: name);
      await DatabaseService.instance.updateHabit(updatedHabit);
      _habits[index] = updatedHabit;
      _syncToCloud();
      notifyListeners();
    }
  }

  Future<void> _syncToCloud() async {
    try {
      await SyncService.instance.syncHabits(_habits);
      final allLogs = <HabitLog>[];
      for (final logs in _habitLogs.values) {
        allLogs.addAll(logs);
      }
      await SyncService.instance.syncHabitLogs(allLogs);
    } catch (e) {
      // Ignore sync errors
    }
  }
}