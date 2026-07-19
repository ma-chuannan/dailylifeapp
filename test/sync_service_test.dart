// SyncService 占位测试
//
// 现状（2026-07-16）：
//   - sync_service.dart 第 1 行 `import 'dart:html';` 用了 window.localStorage
//     这只能在 web 平台跑，host 平台 (flutter test 默认) 下 import 会编译失败
//   - 第 21 行 `_cloudEnabled = false`，所有 sync/get 方法早返回
//   - 第 24 行硬编码了 Supabase secret key（sb_secret_ 前缀），
//     ⚠️ 这是安全问题，**不应该 commit 到代码里**，建议改用环境变量
//
// 当前这些测试全部 skip，原因：
//   1. dart:html 限制 - 测试在 host 平台下连 import 都做不到
//   2. _cloudEnabled=false - 即使能 import，业务也是 no-op，没东西可测
//
// 真正接入 Supabase 后，建议：
//   1. 修 sync_service.dart 用条件导入 (dart:io + dart:html) 或 universal_io
//   2. 把 secret key 挪到 .env
//   3. 写真正的集成测试覆盖 syncTasks/getTasks 等行为

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PLACEHOLDER: sync_service 需要 web 平台或 dart:io 适配', () {
    // 等业务实现后写真正的测试
    expect(true, isTrue);
  }, skip: 'dart:html 限制 + _cloudEnabled=false，待 sync_service 重构');

  test('PLACEHOLDER: 接入 Supabase 后测 syncTasks 不抛错', () {
    // 占位测试 - 等实现
  }, skip: 'dart:html 限制 + _cloudEnabled=false，待 sync_service 重构');

  test('PLACEHOLDER: 接入 Supabase 后测 getTasks 返回 List<Task>', () {
    // 占位测试 - 等实现
  }, skip: 'dart:html 限制 + _cloudEnabled=false，待 sync_service 重构');

  test('PLACEHOLDER: 接入 Supabase 后测 syncAll 串行调用 5 个 sync', () {
    // 占位测试 - 等实现
    // 期望签名: syncAll({tasks, habits, habitLogs, diaries, moodEntries})
  }, skip: 'dart:html 限制 + _cloudEnabled=false，待 sync_service 重构');
}