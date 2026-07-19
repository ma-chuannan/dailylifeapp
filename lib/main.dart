import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/task_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/mood_provider.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    DatabaseService.setWebMode(true);
    await DatabaseService.instance.initWebStorage();
  }
  await initializeDateFormatting();
  await SyncService.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: const DailyLifeApp(),
    ),
  );
}
