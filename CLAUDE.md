# dailylifeapp 项目 — AI 项目记忆

> 项目级 AI 指令：Claude Code 进入本目录时自动加载
> 来源：从用户级 MEMORY.md 下沉，避免跨用户/跨设备时丢失
> 溯源原则：每条经验都标注来源，行号定位 + 原文件链接

---

## 项目元信息

- **项目名**：dailylifeapp（个人任务记录系统）
- **位置**：`D:\dailylifeapp\`
- **技术栈**：Flutter（Dart）+ Web 模式运行（pubspec.yaml / web/ 目录）
- **平台支持**：android / ios / linux / macos / windows / web（全平台 Flutter）
- **关键文件**：
  - `lib/screens/settings_screen.dart` — 版本号 + 更新日志在这里管理
  - `bring_to_front.ps1` / `run_web.bat` / `start_app.bat` / `start_server.vbs` — 启动相关脚本
  - `serve.py` 系列 — 本地 web 服务器

> 📎 来源: ../memory/MEMORY.md 旧索引 always-use-superpowers-skills 条目（2026-06-07）

---

## 项目专属规则（硬性）

### 规则 1：先调用 superpowers 技能
本项目回答/操作前，**第一步必须**调用 `Skill` 工具检查可用的 superpowers 技能。

### 规则 2：修复代码后必须改版本号 + 更新日志
修复本项目任何代码 bug 后，必须：

1. **修改版本号**：`lib/screens/settings_screen.dart` 中的版本号（如 v1.0.0 → v1.1.0）
2. **更新修复日志**：在 `_getInfoContent` 方法的"更新日志"里添加新条目
3. **重新构建 Web 版本**（如果影响 Web 端）

---

## Why（为什么有这条规则）

- 用户明确要求（2026-06-07）
- **历史教训**：
  - 之前没用 superpowers 技能 → 沟通错误、修复不彻底、**数据丢失**
  - 之前修复了但忘了改版本号和更新日志 → **用户不信任**

---

## How to apply（如何应用）

```
当用户讨论 dailylifeapp 项目时：
  ↓
第一步：调用 Skill 工具检查 superpowers 技能
  ↓
（其他话题不需要触发此规则）
  ↓
修复代码后：
  → 改 lib/screens/settings_screen.dart 中的版本号
  → 在 _getInfoContent 方法的"更新日志"加新条目
  → 重新构建 Web 版本
```

---

## 与全局规则的关系

本项目规则**补充**（不取代）全局 superpowers 调用规则：
- **全局规则**（在用户级 MEMORY.md `always-invoke-superpowers-skills`）：整个对话都要调用 superpowers 技能
- **本项目规则**（本文件）：dailylifeapp 项目还要额外遵守"修复后改版本号 + 更新日志"

---

## 相关链接

- 原始 memory：`~/.claude/projects/C--Users-16288/memory/always-use-superpowers-skills.md`
- 关键文件：`D:\dailylifeapp\lib\screens\settings_screen.dart`
- Spec 目录：`D:\dailylifeapp\docs\superpowers\specs\`
- 实施计划目录：`D:\dailylifeapp\docs\superpowers\plans\`

---

## 测试纪律（新增于 2026-07-16）

> 来源：用户要求"起 pytest 测试套件" → 实测发现项目是 Flutter → 改用 flutter_test

### 测试框架

- **不是 pytest**，是 `flutter test`
- 跑测试命令：`flutter test`（详细：`flutter test --reporter expanded`）
- 跑单个文件：`flutter test test/task_test.dart`
- 跑覆盖率：`flutter test --coverage`
- 测试目录：`test/`（2026-07-16 之前不存在）

### 必须遵守

1. **改完代码不跑测试不算完成**（呼应 `verification-before-completion` skill）
2. **新增 model 必须带测试**，至少覆盖：构造、`toMap` / `fromMap`、roundtrip 一致性、`copyWith` 局部修改、边界 case
3. **新增 service 必须带测试** + IO 类 mock（SQLite / Supabase / Notification）
4. **不要删除测试让测试通过**（删测试 ≠ 修 bug）

### Baseline（2026-07-16 起）

**52 个测试全部通过**，0 红。任何改动后跑 `flutter test` 必须保持 `All tests passed!`

| 文件 | 测试数 | 状态 |
|---|---|---|
| `test/task_test.dart` | 16 | ✅ |
| `test/mood_entry_test.dart` | 11 | ✅ |
| `test/habit_test.dart` | 10 | ✅ |
| `test/diary_test.dart` | 8 | ✅ |
| `test/habit_log_test.dart` | 7 | ✅ |

### 标准工作流（Explore → Plan → Code → Test → Commit）

1. **Explore** — 读相关文件，理解现状
2. **Plan** — Plan Mode 给方案 → 用户确认
3. **Code** — 写代码 + 写测试（同步）
4. **Test** — 跑 `flutter test` 全过才交付
5. **Commit** — `code-review` skill review 改动 + 跑最后一次 `flutter test`

### 已有测试目录参考

```
D:\dailylifeapp\test\
├── task_test.dart        # 16 tests
├── mood_entry_test.dart  # 11 tests
├── habit_test.dart       # 10 tests
├── diary_test.dart       # 8 tests
└── habit_log_test.dart   # 7 tests
```

### 验证/质量 skill 协同表

| 场景 | 用什么 skill |
|---|---|
| 新功能从零开始 | `test-driven-development` (TDD 红→绿→重构) |
| 改完准备交付 | `verification-before-completion` (跑测试) |
| 跑应用实测 | `verify` |
| 改完准备 commit | `code-review` + 再跑一次 `flutter test` |
| 测试挂了找原因 | `systematic-debugging` |
| 清理冗余代码 | `simplify` |
| 提交前自查安全 | `security-review` |
| 请别人 review | `requesting-code-review` |
| 收到 review 反馈 | `receiving-code-review` |

> 📎 来源: 用户会话 2026-07-16，CLAUDE 101 课程 → Connectors / deep-research / 测试套件讨论

---

## 业务约束（新增于 2026-07-16）

> 来源：paranoid 检查 → 发现 3 个真隐患 + 2 个业务规则漏洞 → 加 assert 防御

### Model 层 assert 规则（开发期生效，release 模式剥离）

每个 model 在构造时校验业务规则，违规会立刻抛 `AssertionError`：

| Model | 约束 | 非法行为 |
|---|---|---|
| **Task** | `isCompleted == (completedAt != null)` | 已完成必须有 completedAt；未完成 completedAt 必须为 null |
| **MoodEntry** | `energyLevel >= 1 && energyLevel <= 5` | 0 / 6 / -1 / 100 都抛 assert |
| **MoodEntry** | `mood ∈ {happy, neutral, sad, angry}` | 'banana' / '' / 'HAPPY' 都抛 assert（区分大小写） |
| **Habit** | `targetFrequency > 0` | 0 / -1 都抛 assert |
| **Habit** | `currentStreak >= 0` | -1 / -100 都抛 assert |
| **HabitLog** | fromMap 只接受 `int 1`，其他降级为 false | bool / null / 缺字段都不抛错 |

### 防御性写法（HabitLog.fromMap）

```dart
final raw = map['completed'];
completed: raw is int && raw == 1;  // 不抛 TypeError，安全降级
```

### 为什么用 assert 不用 throw

- ✅ 开发期立刻报错（定位快）
- ✅ release 模式自动剥离（零运行时成本）
- ⚠️ 业务规则靠 assert + 测试守护，**不能用 assert 做用户输入校验**（用户输入应该 throw + UI 提示）

### 修改 assert 时必须同步做的事

1. 修改 model 文件（lib/models/*.dart）
2. 检查所有现有测试是否仍然合法（合法值测试不变，非法值测试要更新为期望抛 assert）
3. 在对应 `xxx_constraints_test.dart` 里补新边界 case
4. 跑 `flutter test` 确认 `All tests passed!`
5. 跑 mutation testing（手动改 model 看测试是否抓到）

### 业务约束测试文件清单

| 文件 | 测什么 | 测试数 |
|---|---|---|
| `test/task_constraints_test.dart` | Task 跨字段一致性 | 7 |
| `test/mood_entry_constraints_test.dart` | energyLevel 范围 + mood 枚举 | 11 |
| `test/habit_constraints_test.dart` | targetFrequency / currentStreak 范围 | 14 |
| `test/habit_log_defensive_test.dart` | fromMap 防御性 | 6 |

### 当前总测试数

**123 tests passing + 4 skipped**（52 原始 model + 42 业务约束 + 23 database_service + 6 notification_service + 4 sync_service 占位 skip）

> 📎 来源: 用户会话 2026-07-16，paranoid 检查 → mutation testing → assert 防御

---

## Service 层测试（新增于 2026-07-17）

### 现状盘点

| Service | 行数 | 真正"做事"吗？ | 测试覆盖 |
|---|---|---|---|
| `database_service.dart` | 373 | ✅ 完整 CRUD + web/native 双模式 | ✅ 23 tests（web 模式全覆盖） |
| `notification_service.dart` | 37 | ❌ 全是 stub（`if (kIsWeb) return;`） | ⚠️ 6 占位测试 |
| `sync_service.dart` | 255 | ❌ `_cloudEnabled=false` 全早返回 | ⚠️ 4 占位测试（skip） |

### database_service 测试策略

- **测 web 模式**（SharedPreferences mock + 内存 List）—— 项目主要跑 web 路径
- **不测 native 模式**（sqflite）—— 留 TODO，等 native 优先时补
- 每个测试用 `_uniqueDate()` / `_uniqueId()` 避免 shared static state 污染
- 测了：Task/Habit/HabitLog/Diary/MoodEntry 五个 model 的 CRUD + 查询 + upsert + 排序

### notification_service / sync_service 占位测试

- **notification_service**: 6 个测试验证"调用不抛错"（因为实现全是 stub）
- **sync_service**: 4 个测试**全部 skip**，原因：
  1. `import 'dart:html';` 导致 host 平台编译失败
  2. `_cloudEnabled=false` 业务上 no-op

### 已知 bug（service 层）—— 全部修复于 2026-07-17

#### ✅ #4 web-mode date UNIQUE — 已修复

> `database_service.insertDiary()` 和 `insertMoodEntry()` 在 web 模式只按 `id` removeWhere，
> **不处理 `date UNIQUE` 约束**。

**修复**：`database_service.dart` web 模式分支加 `_memoryDiaries.removeWhere((d) => d['date'] == diary.date)`（mood 同理）。

**测试**：`database_service_test.dart` 加 2 个新 case 验证同 date 不同 id 应该 replace。

#### ✅ #3 database_service test setUp 不真清空 — 已修复

> 测试 setUp 调 `SharedPreferences.setMockInitialValues({})` + `initWebStorage()`，
> 但 `_loadFromStorage` 只在 prefs 有数据时覆盖 `_memoryXxx`，空 prefs 不清空。

**修复**：`database_service.dart` 加 `@visibleForTesting static void resetForTest()` 方法清空所有 static 状态；测试 setUp 先调它。

#### ✅ #5 sync_service bool/int 序列化不匹配 — 已修复

> `syncTasks` 写 `'isCompleted': t.isCompleted` 是 **bool**，
> 但 `Task.fromMap` 读 `map['isCompleted'] == 1`（要 **int**）。cloud sync 重新启用时所有 task 解析成 `isCompleted=false` + `completedAt=原值` → 触发新 assert。

**修复**：`sync_service.dart` 改写 `'isCompleted': t.isCompleted ? 1 : 0`、`'completed': l.completed ? 1 : 0`，与 `fromMap` 对齐。

#### ✅ #1 Task.copyWith null sentinel + 新 assert 冲突 — 已修复（最严重）

> `Task.copyWith` 用 `?? this.completedAt` 无法区分"未传"和"传 null"。
> 用户点"取消完成"调 `task.copyWith(isCompleted: false, completedAt: null)`，
> 期望清空 completedAt，但 `??` 让 null 失效 → 返回值违反新 assert → **debug 模式崩**。

**修复**：`task.dart` 用 sentinel 对象区分"未传"和"传 null"。`Object? completedAt = _sentinel`，用 `identical(completedAt, _sentinel)` 判断。

**测试**：`task_test.dart` 加 2 个 regression test 验证双向行为（显式 null 真清空 + 不传保留原值）。

> 📎 来源: 2026-07-17 reviewer subagent demo 抓到 5 个 bug，全部修复。reviewer 在独立上下文里看到主 agent 看不到的端到端调用链问题。

### ⚠️ 安全行动项（**修复了但还需要用户手动操作**）

> ~~`lib/services/sync_service.dart` 第 24 行硬编码了 Supabase secret key~~

**修复部分**：代码改用 `String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '')`，硬编码 key 已删除。

**用户必须手动**：
1. ⚠️ **立刻去 Supabase 控制台撤销 `sb_secret_***REDACTED***` 这个 key**（之前 commit 过旧源码到 dailylifeapp 外的位置，必须 rotate）
2. 启用 cloud sync 时用：`flutter build web --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxx`
3. 未注入时自动禁用（`_cloudEnabled` 检查 url 和 key 都非空）

> 📎 来源: 用户会话 2026-07-17，service 层测试覆盖 + reviewer 抓到 5 个 bug

> ⚠️ **本文件不记录完整 key 字面量**（即使用作文档），避免 key 通过文档/git 历史泄露。完整 key 只能在用户本地 `.env` 里存在。
