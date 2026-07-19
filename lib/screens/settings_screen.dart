import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _habitReminderEnabled = true;
  TimeOfDay _habitReminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _taskReminderEnabled = true;
  TimeOfDay _taskReminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFF8700),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('设置', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('提醒设置', [
                    _buildReminderItem(
                      '习惯提醒',
                      Icons.notifications,
                      _habitReminderEnabled,
                      _habitReminderTime,
                      (value) => setState(() => _habitReminderEnabled = value),
                      () => _selectTime(context, true),
                    ),
                    const Divider(height: 1),
                    _buildReminderItem(
                      '任务提醒',
                      Icons.alarm,
                      _taskReminderEnabled,
                      _taskReminderTime,
                      (value) => setState(() => _taskReminderEnabled = value),
                      () => _selectTime(context, false),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('同步设置', [
                    _buildInfoItem('云端同步', 'Firebase同步服务', Icons.cloud),
                    const Divider(height: 1),
                    _buildInfoItem('同步历史', '暂无同步记录', Icons.sync),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('关于', [
                    _buildInfoItem('版本', 'v1.2.2', Icons.info_outline),
                    const Divider(height: 1),
                    _buildInfoItem('更新日志', '查看', Icons.update),
                    const Divider(height: 1),
                    _buildInfoItem('反馈问题', '联系开发者', Icons.feedback_outlined),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildReminderItem(
    String title,
    IconData icon,
    bool enabled,
    TimeOfDay time,
    ValueChanged<bool> onToggle,
    VoidCallback onTimeTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00A99D), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF333333), fontSize: 16)),
                if (enabled)
                  GestureDetector(
                    onTap: onTimeTap,
                    child: Text(
                      '每天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeColor: const Color(0xFF00A99D),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A99D)),
      title: Text(title, style: const TextStyle(color: Color(0xFF333333))),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: () => _showInfoDialog(title),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isHabit) async {
    final currentTime = isHabit ? _habitReminderTime : _taskReminderTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8700),
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isHabit) {
          _habitReminderTime = picked;
        } else {
          _taskReminderTime = picked;
        }
      });
    }
  }

  void _showInfoDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Color(0xFF333333))),
        content: Text(
          _getInfoContent(title),
          style: const TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭', style: TextStyle(color: Color(0xFF00A99D))),
          ),
        ],
      ),
    );
  }

  String _getInfoContent(String title) {
    switch (title) {
      case '云端同步':
        return 'Firebase同步服务配置中...\n\n如需启用云端同步，请联系开发者。';
      case '同步历史':
        return '暂无同步记录';
      case '版本':
        return '每日生活管理 v1.2.2\n\n支持手机和电脑跨平台使用';
      case '更新日志':
        return 'v1.2.2 (2026-06-13)\n'
            '━━━━━━━━━━━━━\n'
            '【修复】\n'
            '• 修复 v1.2.1 启动时 hang 住页面空白的问题\n'
            '• 去掉 await initializeDateFormatting()（dart2js web 下 hang）\n'
            '• 用本地 canvaskit（不再从 gstatic.com 拉资源）\n'
            '• main() 加 runZonedGuarded 兜底，错误可见\n'
            '• 数据库/Sync 初始化用 unawaited，不阻塞 runApp\n\n'
            '━━━━━━━━━━━━━\n'
            'v1.2.1 (2026-06-09)\n'
            '━━━━━━━━━━━━━\n'
            '【修复】\n'
            '• 修复 v1.2.0 启动时崩溃问题\n'
            '• Flutter Web 必须先调用 initializeDateFormatting() 才能用 DateFormat\n'
            '• v1.2.0 加日期选择器后漏了初始化，导致页面空白\n\n'
            '━━━━━━━━━━━━━\n'
            'v1.2.0 (2026-06-09)\n'
            '━━━━━━━━━━━━━\n'
            '【新增】\n'
            '• 新增日期选择器，可查看任意日期的任务\n'
            '• 顶部点击"日期"按钮选择历史/未来日期\n\n'
            '━━━━━━━━━━━━━\n'
            'v1.1.0 (2026-06-06)\n'
            '━━━━━━━━━━━━━\n'
            '【修复】\n'
            '• 修复 user_id 重启后变化导致数据丢失的问题\n'
            '• 修复同步逻辑 delete+insert 覆盖云端数据的问题\n'
            '• user_id 改为固定值 dailylife_fixed_user_v1\n'
            '• 所有表改为 upsert 同步方式\n\n'
            '【新增】\n'
            '• 新增"学习"固定标签\n\n'
            '【优化】\n'
            '• 删除不再需要的"恢复"按钮\n\n'
            '━━━━━━━━━━━━━\n'
            'v1.0.0 (2026-06-03)\n'
            '• 初始版本发布';
      case '反馈问题':
        return '如有问题或建议，请联系开发者。';
      default:
        return '功能开发中...';
    }
  }
}