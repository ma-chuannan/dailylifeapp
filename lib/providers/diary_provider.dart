import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/diary.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class DiaryProvider with ChangeNotifier {
  List<Diary> _diaries = [];
  Diary? _todayDiary;
  final _uuid = const Uuid();

  List<Diary> get diaries => _diaries;
  Diary? get todayDiary => _todayDiary;

  Future<void> loadDiaries() async {
    _diaries = await DatabaseService.instance.getAllDiaries();
    notifyListeners();
  }

  Future<void> loadDiaryByDate(String date) async {
    _todayDiary = await DatabaseService.instance.getDiaryByDate(date);
    notifyListeners();
  }

  Future<void> saveDiary(String date, String content) async {
    if (content.trim().isEmpty) return;

    final existingDiary = await DatabaseService.instance.getDiaryByDate(date);
    if (existingDiary != null) {
      final updatedDiary = existingDiary.copyWith(content: content);
      await DatabaseService.instance.insertDiary(updatedDiary);
      final index = _diaries.indexWhere((d) => d.date == date);
      if (index != -1) {
        _diaries[index] = updatedDiary;
      } else {
        _diaries.insert(0, updatedDiary);
      }
      if (_todayDiary?.date == date) {
        _todayDiary = updatedDiary;
      }
    } else {
      final diary = Diary(
        id: _uuid.v4(),
        date: date,
        content: content,
      );
      await DatabaseService.instance.insertDiary(diary);
      _diaries.insert(0, diary);
      if (_todayDiary?.date == date) {
        _todayDiary = diary;
      }
    }
    _syncToCloud();
    notifyListeners();
  }

  Future<void> _syncToCloud() async {
    try {
      await SyncService.instance.syncDiaries(_diaries);
    } catch (e) {
      // Ignore sync errors
    }
  }
}