import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/mood_entry.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class MoodProvider with ChangeNotifier {
  MoodEntry? _todayMood;
  List<MoodEntry> _moodHistory = [];
  final _uuid = const Uuid();

  MoodEntry? get todayMood => _todayMood;
  List<MoodEntry> get moodHistory => _moodHistory;

  Future<void> loadMoodByDate(String date) async {
    _todayMood = await DatabaseService.instance.getMoodEntryByDate(date);
    notifyListeners();
  }

  Future<void> loadMoodHistory(String startDate, String endDate) async {
    _moodHistory = await DatabaseService.instance.getMoodEntriesByDateRange(startDate, endDate);
    notifyListeners();
  }

  Future<void> saveMood(String date, String mood, int energyLevel) async {
    final existingMood = await DatabaseService.instance.getMoodEntryByDate(date);

    if (existingMood != null) {
      final updatedMood = existingMood.copyWith(mood: mood, energyLevel: energyLevel);
      await DatabaseService.instance.insertMoodEntry(updatedMood);
      _todayMood = updatedMood;
      final index = _moodHistory.indexWhere((m) => m.date == date);
      if (index != -1) {
        _moodHistory[index] = updatedMood;
      }
    } else {
      final newMood = MoodEntry(
        id: _uuid.v4(),
        date: date,
        mood: mood,
        energyLevel: energyLevel,
      );
      await DatabaseService.instance.insertMoodEntry(newMood);
      _todayMood = newMood;
      _moodHistory.add(newMood);
    }
    _syncToCloud();
    notifyListeners();
  }

  Future<void> _syncToCloud() async {
    try {
      await SyncService.instance.syncMoodEntries(_moodHistory);
    } catch (e) {
      // Ignore sync errors
    }
  }

  String getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'neutral':
        return '😐';
      case 'sad':
        return '😔';
      case 'angry':
        return '😤';
      default:
        return '😐';
    }
  }
}