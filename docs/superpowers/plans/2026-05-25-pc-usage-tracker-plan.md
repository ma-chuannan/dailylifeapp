# PC Usage Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个 Flutter Windows 桌面应用，后台运行，记录电脑使用时长、应用使用时长、键盘敲击次数，支持久坐提醒。

**Architecture:** 新建独立 Flutter 项目，数据采集层通过 `win32` 包调用 Windows API，数据存储使用本地 SQLite，展示层为 Flutter UI，最小化到系统托盘运行。

**Tech Stack:** Flutter Windows, `win32`, `drift` (SQLite ORM), `system_tray`, `local_notifier`

---

## 文件结构

```
pc_usage_tracker/                     # 新项目根目录
├── lib/
│   ├── main.dart                     # 入口，托盘初始化
│   ├── models/
│   │   ├── session.dart              # 会话模型
│   │   ├── app_usage.dart            # 应用使用记录模型
│   │   └── keystroke_count.dart      # 键盘记录模型
│   ├── services/
│   │   ├── database_service.dart    # SQLite 数据库服务（drift）
│   │   ├── tracker_service.dart      # Windows API 数据采集
│   │   └── reminder_service.dart     # 提醒服务
│   └── ui/
│       └── stats_page.dart          # 统计页面
├── pubspec.yaml
└── windows/
```

---

## Task 1: 创建 Flutter 项目并配置依赖

**Files:**
- Create: `pc_usage_tracker/pubspec.yaml`
- Create: `pc_usage_tracker/lib/main.dart`

- [ ] **Step 1: 创建 Flutter 项目**

```powershell
cd D:\dailylifeapp
flutter create --platforms=windows pc_usage_tracker
```

- [ ] **Step 2: 修改 pubspec.yaml，添加依赖**

```yaml
name: pc_usage_tracker
description: PC Usage Tracker - 记录电脑使用时长、应用使用情况、键盘敲击次数

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  win32: ^5.0.0
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.0
  system_tray: ^2.0.0
  local_notifier: ^0.1.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

- [ ] **Step 3: 创建目录结构**

```powershell
cd pc_usage_tracker
mkdir lib/models
mkdir lib/services
mkdir lib/ui
```

- [ ] **Step 4: 运行 flutter pub get**

```powershell
cd pc_usage_tracker
flutter pub get
```

- [ ] **Step 5: 提交**

```bash
git init
git add .
git commit -m "feat: initial Flutter Windows project with dependencies"
```

---

## Task 2: 创建数据模型

**Files:**
- Create: `pc_usage_tracker/lib/models/session.dart`
- Create: `pc_usage_tracker/lib/models/app_usage.dart`
- Create: `pc_usage_tracker/lib/models/keystroke_count.dart`

- [ ] **Step 1: 创建 session.dart**

```dart
class Session {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int get durationMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  Session({this.id, required this.startTime, this.endTime});

  Map<String, dynamic> toMap() => {
    'id': id,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
  };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
    id: map['id'] as int?,
    startTime: DateTime.parse(map['start_time'] as String),
    endTime: map['end_time'] != null
        ? DateTime.parse(map['end_time'] as String)
        : null,
  );
}
```

- [ ] **Step 2: 创建 app_usage.dart**

```dart
class AppUsage {
  final int? id;
  final int sessionId;
  final String appName;
  final String windowTitle;
  final int durationMinutes;
  final DateTime date;

  AppUsage({
    this.id,
    required this.sessionId,
    required this.appName,
    required this.windowTitle,
    required this.durationMinutes,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'app_name': appName,
    'window_title': windowTitle,
    'duration_minutes': durationMinutes,
    'date': date.toIso8601String().split('T').first,
  };

  factory AppUsage.fromMap(Map<String, dynamic> map) => AppUsage(
    id: map['id'] as int?,
    sessionId: map['session_id'] as int,
    appName: map['app_name'] as String,
    windowTitle: map['window_title'] as String,
    durationMinutes: map['duration_minutes'] as int,
    date: DateTime.parse(map['date'] as String),
  );
}
```

- [ ] **Step 3: 创建 keystroke_count.dart**

```dart
class KeystrokeCount {
  final int? id;
  final int sessionId;
  final int count;
  final DateTime date;

  KeystrokeCount({
    this.id,
    required this.sessionId,
    required this.count,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'count': count,
    'date': date.toIso8601String().split('T').first,
  };

  factory KeystrokeCount.fromMap(Map<String, dynamic> map) => KeystrokeCount(
    id: map['id'] as int?,
    sessionId: map['session_id'] as int,
    count: map['count'] as int,
    date: DateTime.parse(map['date'] as String),
  );
}
```

- [ ] **Step 4: 提交**

```bash
git add lib/models/
git commit -m "feat: add data models for session, app_usage, keystroke_count"
```

---

## Task 3: 数据库服务（drift）

**Files:**
- Create: `pc_usage_tracker/lib/services/database_service.dart`
- Create: `pc_usage_tracker/lib/services/database.dart` (drift generated)
- Create: `pc_usage_tracker/lib/services/tables.dart` (drift tables)

- [ ] **Step 1: 创建 tables.dart（drift 表定义）**

```dart
import 'package:drift/drift.dart';

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
}

class AppUsages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  TextColumn get appName => text()();
  TextColumn get windowTitle => text()();
  IntColumn get durationMinutes => integer()();
  TextColumn get date => text()();
}

class KeystrokeCounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  IntColumn get count => integer()();
  TextColumn get date => text()();
}
```

- [ ] **Step 2: 创建 database.dart（drift 数据库）**

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Sessions, AppUsages, KeystrokeCounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Session CRUD
  Future<int> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  Future<void> updateSessionEnd(int id, DateTime endTime) =>
      (update(sessions)..where((t) => t.id.equals(id)))
          .write(SessionsCompanion(endTime: Value(endTime)));

  Future<List<Session>> getAllSessions() => select(sessions).get();

  Future<Session?> getActiveSession() =>
      (select(sessions)..where((t) => t.endTime.isNull()))
          .getSingleOrNull();

  // AppUsage CRUD
  Future<void> insertAppUsage(AppUsagesCompanion usage) =>
      into(appUsages).insert(usage);

  Future<List<AppUsage>> getAppUsagesByDate(String date) =>
      (select(appUsages)..where((t) => t.date.equals(date))).get();

  Future<List<AppUsage>> getAppUsagesBySession(int sessionId) =>
      (select(appUsages)..where((t) => t.sessionId.equals(sessionId))).get();

  // KeystrokeCount CRUD
  Future<void> insertKeystrokeCount(KeystrokeCountsCompanion kc) =>
      into(keystrokeCounts).insert(kc);

  Future<KeystrokeCount?> getKeystrokeCountByDate(String date) =>
      (select(keystrokeCounts)..where((t) => t.date.equals(date)))
          .getSingleOrNull();

  Future<void> updateKeystrokeCount(int id, int newCount) =>
      (update(keystrokeCounts)..where((t) => t.id.equals(id)))
          .write(KeystrokeCountsCompanion(count: Value(newCount)));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pc_usage.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 3: 运行 build_runner 生成 drift 代码**

```powershell
cd pc_usage_tracker
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: 提交**

```bash
git add lib/services/
git commit -m "feat: add drift database service with sessions, app_usages, keystroke_counts tables"
```

---

## Task 4: Tracker Service（Windows API 数据采集）

**Files:**
- Create: `pc_usage_tracker/lib/services/tracker_service.dart`

- [ ] **Step 1: 创建 tracker_service.dart**

```dart
import 'dart:async';
import 'dart:ffi';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'database_service.dart';

class TrackerService {
  static final TrackerService instance = TrackerService._();
  TrackerService._();

  final AppDatabase _db = AppDatabase();
  Timer? _pollingTimer;
  int? _currentSessionId;
  String _lastAppName = '';
  String _lastWindowTitle = '';
  DateTime? _lastPollTime;
  int _idleMinutes = 0;

  // 键盘全局钩子
  int _keystrokeCount = 0;
  int _hookId = 0;

  Future<void> start() async {
    // 创建新 session
    final session = Session(
      startTime: DateTime.now(),
    );
    _currentSessionId = await _db.insertSession(
      SessionsCompanion.insert(startTime: session.startTime),
    );
    _keystrokeCount = 0;

    // 启动轮询（每秒检查前台窗口）
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());

    // 安装键盘钩子
    _installKeyboardHook();
  }

  void _installKeyboardHook() {
    _hookId = user32.SetWindowsHookEx(
      WH_KEYBOARD_LL,
      Pointer.fromFunction< IntPtr Function(Int, Int, Pointer)>(_keyboardProc, 0),
      kernel32.GetModuleHandle(nullptr),
      0,
    );
  }

  int _keyboardProc(int code, int wParam, int lParam) {
    if (code >= 0 && wParam == WM_KEYDOWN) {
      _keystrokeCount++;
    }
    return CallConv.instance.CallFunctionStdCall(
      Pointer.fromAddress(user32.CallNextHookEx(_hookId, code, wParam, lParam.address)),
    );
  }

  Future<void> _poll() async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T').first;

    // 获取前台窗口
    final hwnd = user32.GetForegroundWindow();
    if (hwnd == 0) return;

    final length = user32.GetWindowTextLength(hwnd);
    if (length == 0) return;

    final titlePtr = calloc<Uint16>(length + 1);
    user32.GetWindowText(hwnd, titlePtr, length + 1);
    final windowTitle = titlePtr.toDartString();
    calloc.free(titlePtr);

    final pidPtr = calloc<DWORD>();
    user32.GetWindowThreadProcessId(hwnd, pidPtr);
    final pid = pidPtr.value;
    calloc.free(pidPtr);

    final appName = _getProcessName(pid);

    // 写入应用使用记录（每分钟聚合一次）
    if (_lastPollTime != null && now.difference(_lastPollTime!).inMinutes >= 1) {
      if (_lastAppName.isNotEmpty) {
        await _db.insertAppUsage(
          AppUsagesCompanion.insert(
            sessionId: _currentSessionId!,
            appName: _lastAppName,
            windowTitle: _lastWindowTitle,
            durationMinutes: now.difference(_lastPollTime!).inMinutes,
            date: today,
          ),
        );
      }
      _lastPollTime = now;
    }
    _lastPollTime ??= now;
    _lastAppName = appName;
    _lastWindowTitle = windowTitle;

    // 更新键盘记录
    if (_keystrokeCount > 0) {
      final existing = await _db.getKeystrokeCountByDate(today);
      if (existing != null) {
        await _db.updateKeystrokeCount(existing.id, existing.count + _keystrokeCount);
      } else {
        await _db.insertKeystrokeCount(
          KeystrokeCountsCompanion.insert(
            sessionId: _currentSessionId!,
            count: _keystrokeCount,
            date: today,
          ),
        );
      }
      _keystrokeCount = 0;
    }

    // 空闲检测（无键盘/鼠标活动超过 5 分钟视为空闲）
    _idleMinutes = now.difference(_lastPollTime!).inMinutes;
  }

  String _getProcessName(int pid) {
    final handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (handle == 0) return 'Unknown';

    final buffer = calloc<Uint16>(260);
    final size = calloc<DWORD>();
    size.value = 260;

    final result = kernel32.QueryFullProcessImageName(handle, 0, buffer, size);
    kernel32.CloseHandle(handle);

    if (result == 0) return 'Unknown';

    final path = buffer.toDartString();
    calloc.free(buffer);
    calloc.free(size);

    return path.split('\\').last.split('.').first;
  }

  Future<void> stop() async {
    _pollingTimer?.cancel();
    if (_hookId != 0) {
      user32.UnhookWindowsHookEx(_hookId);
      _hookId = 0;
    }
    if (_currentSessionId != null) {
      await _db.updateSessionEnd(_currentSessionId!, DateTime.now());
      _currentSessionId = null;
    }
  }

  bool get isIdle => _idleMinutes >= 5;
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/services/tracker_service.dart
git commit -m "feat: add tracker service with Windows API polling and keyboard hook"
```

---

## Task 5: 提醒服务

**Files:**
- Create: `pc_usage_tracker/lib/services/reminder_service.dart`

- [ ] **Step 1: 创建 reminder_service.dart**

```dart
import 'dart:async';
import 'package:local_notifier/local_notifier.dart';

class ReminderService {
  static final ReminderService instance = ReminderService._();
  ReminderService._();

  static const int sedentaryThresholdMinutes = 45;
  static const int overtimeThresholdMinutes = 120;

  Timer? _checkTimer;
  int _consecutiveUsageMinutes = 0;
  bool _notifiedSedentary = false;
  bool _notifiedOvertime = false;
  DateTime? _lastActivityTime;

  Future<void> start() async {
    await localNotifier.setup(appName: 'PC Usage Tracker');
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) => _check());
  }

  void recordActivity() {
    _lastActivityTime = DateTime.now();
    _consecutiveUsageMinutes = 0;
    _notifiedSedentary = false;
    _notifiedOvertime = false;
  }

  void _check() {
    _consecutiveUsageMinutes++;

    if (_consecutiveUsageMinutes >= sedentaryThresholdMinutes && !_notifiedSedentary) {
      _sendNotification(
        title: '休息提醒',
        body: '你已连续使用电脑 45 分钟，建议站起来活动一下',
      );
      _notifiedSedentary = true;
    }

    if (_consecutiveUsageMinutes >= overtimeThresholdMinutes && !_notifiedOvertime) {
      _sendNotification(
        title: '超时提醒',
        body: '你已使用电脑超过 2 小时，记得适当休息',
      );
      _notifiedOvertime = true;
    }
  }

  void _sendNotification({required String title, required String body}) {
    final notification = LocalNotification(
      title: title,
      body: body,
    );
    notification.show();
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/services/reminder_service.dart
git commit -m "feat: add reminder service with sedentary (45min) and overtime (2hr) notifications"
```

---

## Task 6: 主入口和系统托盘

**Files:**
- Create: `pc_usage_tracker/lib/ui/stats_page.dart`
- Modify: `pc_usage_tracker/lib/main.dart`

- [ ] **Step 1: 创建 stats_page.dart（统计页面）**

```dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class StatsPage extends StatelessWidget {
  final AppDatabase db;

  const StatsPage({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日统计')),
      body: FutureBuilder<List<AppUsage>>(
        future: db.getAppUsagesByDate(
          DateTime.now().toIso8601String().split('T').first,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final usages = snapshot.data!;

          final totalMinutes = usages.fold<int>(
            0, (sum, u) => sum + u.durationMinutes,
          );

          return ListView(
            children: [
              ListTile(
                title: const Text('今日使用时长'),
                trailing: Text('${totalMinutes} 分钟'),
              ),
              const Divider(),
              const ListTile(
                title: Text('应用使用排行'),
                dense: true,
              ),
              ...usages.map((u) => ListTile(
                dense: true,
                title: Text(u.appName),
                subtitle: Text(u.windowTitle),
                trailing: Text('${u.durationMinutes} 分钟'),
              )),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: 修改 main.dart**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'services/tracker_service.dart';
import 'services/reminder_service.dart';
import 'services/database_service.dart';
import 'ui/stats_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 隐藏窗口边框，最小化到托盘
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);

  runApp(const PCUsageTrackerApp());
}

class PCUsageTrackerApp extends StatefulWidget {
  const PCUsageTrackerApp({super.key});

  @override
  State<PCUsageTrackerApp> createState() => _PCUsageTrackerAppState();
}

class _PCUsageTrackerAppState extends State<PCUsageTrackerApp> with WindowListener {
  final SystemTray _systemTray = SystemTray();
  final AppDatabase _db = AppDatabase();
  bool _showWindow = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initSystemTray();
    _startServices();
  }

  Future<void> _initSystemTray() async {
    await _systemTray.initSystemTray(
      title: 'PC Usage Tracker',
      iconPath: Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );

    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: '显示主窗口', onClicked: (_) => _showMainWindow()),
      MenuItemLabel(label: '今日统计', onClicked: (_) => _showStats()),
      MenuSeparator(),
      MenuItemLabel(label: '退出', onClicked: (_) => _exit()),
    ]);
    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        _showMainWindow();
      }
    });
  }

  Future<void> _startServices() async {
    await TrackerService.instance.start();
    await ReminderService.instance.start();
  }

  void _showMainWindow() {
    setState(() => _showWindow = true);
    windowManager.show();
    windowManager.focus();
  }

  void _showStats() {
    Navigator.of(
      _showWindow ? null : navigatorKey.currentContext!,
    ).push(
      MaterialPageRoute(builder: (_) => StatsPage(db: _db)),
    );
  }

  Future<void> _exit() async {
    await TrackerService.instance.stop();
    ReminderService.instance.stop();
    exit(0);
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
    setState(() => _showWindow = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showWindow) {
      return const MaterialApp(home: SizedBox.shrink());
    }
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('PC Usage Tracker')),
        body: const Center(
          child: Text('后台运行中，点击托盘图标查看统计'),
        ),
      ),
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
```

- [ ] **Step 3: 提交**

```bash
git add lib/ui/stats_page.dart lib/main.dart
git commit -m "feat: add main entry with system tray and stats page"
```

---

## Task 7: 开机自启配置

**Files:**
- Modify: `pc_usage_tracker/windows/runner/main.cpp`（添加注册表开机自启）

- [ ] **Step 1: 修改 windows/runner/main.cpp**

在 `main.cpp` 中添加开机自启注册：

```cpp
#include <windows.h>
#include <winreg.h>

void SetAutoStart() {
    HKEY hKey;
    RegOpenKeyEx(HKEY_CURRENT_USER, TEXT("Software\\Microsoft\\Windows\\CurrentVersion\\Run"), 0, KEY_SET_VALUE, &hKey);

    TCHAR exePath[MAX_PATH];
    GetModuleFileName(NULL, exePath, MAX_PATH);

    RegSetValueEx(hKey, TEXT("PCUsageTracker"), 0, REG_SZ, (LPBYTE)exePath, lstrlen(exePath) * sizeof(TCHAR));
    RegCloseKey(hKey);
}
```

在 `main()` 函数开头调用 `SetAutoStart();`。

- [ ] **Step 2: 提交**

```bash
git add windows/runner/main.cpp
git commit -m "feat: add auto-start registry entry on Windows"
```

---

## 实现计划自检

1. **Spec 覆盖检查：**
   - 会话信息（开关机时间）→ Task 3, 4
   - 应用使用时长 → Task 2, 4
   - 键盘敲击次数 → Task 2, 4
   - 空闲检测 → Task 4（`isIdle` 字段）
   - 久坐提醒（45 分钟）→ Task 5
   - 超时提醒（2 小时）→ Task 5
   - 系统托盘 + 后台运行 → Task 6
   - 开机自启 → Task 7

2. **占位符扫描：** 无 TBD/TODO

3. **类型一致性：** `AppDatabase`, `SessionsCompanion`, `AppUsagesCompanion`, `KeystrokeCountsCompanion` 等类型在 drift 生成后需验证

---

**Plan 编写完成。**
