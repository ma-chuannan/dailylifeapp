import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final _uuid = const Uuid();

  List<Task> get tasks => _tasks;

  Future<void> loadTasksByDate(String date) async {
    _tasks = await DatabaseService.instance.getTasksByDate(date);
    notifyListeners();
  }

  Future<void> loadAllTasks() async {
    try {
      _tasks = await SyncService.instance.getTasks();
      notifyListeners();
    } catch (e) {
      // Fallback to local DB
      _tasks = await DatabaseService.instance.getTasksByDate('');
      notifyListeners();
    }
  }

  Future<void> addTask(String content, String category, String date) async {
    final task = Task(
      id: _uuid.v4(),
      content: content,
      category: category,
      isCompleted: false,
      date: date,
    );
    await DatabaseService.instance.insertTask(task);
    _tasks.add(task);
    _syncToCloud();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
      );
      await DatabaseService.instance.updateTask(updatedTask);
      _tasks[index] = updatedTask;
      _syncToCloud();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    await DatabaseService.instance.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    _syncToCloud();
    notifyListeners();
  }

  Future<void> updateTaskContent(String taskId, String content, String category) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(content: content, category: category);
      await DatabaseService.instance.updateTask(updatedTask);
      _tasks[index] = updatedTask;
      _syncToCloud();
      notifyListeners();
    }
  }

  Future<void> _syncToCloud() async {
    try {
      await SyncService.instance.syncTasks(_tasks);
    } catch (e) {
      // Ignore sync errors
    }
  }

  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get totalCount => _tasks.length;

  ///从云端恢复所有任务（不依赖 user_id）
  Future<void> recoverTasks() async {
    try {
      final recoveredTasks = await SyncService.instance.recoverTasks();
      // 保存到本地数据库
      for (final task in recoveredTasks) {
        await DatabaseService.instance.insertTask(task);
      }
      _tasks = recoveredTasks;
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }
}