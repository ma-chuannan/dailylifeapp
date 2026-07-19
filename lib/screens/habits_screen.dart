import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<HabitProvider>().loadAllHabits();
    await context.read<HabitProvider>().loadHabitLogsByDate(_today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 顶部橙色区域
          Container(
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFF8700),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('习惯追踪', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  onPressed: () => _showAddHabitDialog(context),
                ),
              ],
            ),
          ),
          // 白色背景内容区
          Expanded(
            child: Container(
              color: Colors.white,
              child: Consumer<HabitProvider>(
                builder: (context, habitProvider, _) {
                  if (habitProvider.habits.isEmpty) {
                    return Center(
                      child: GestureDetector(
                        onTap: () => _showAddHabitDialog(context),
                        child: Container(
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('点击添加第一个习惯', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFFFF8700),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: habitProvider.habits.length,
                      itemBuilder: (context, index) {
                        final habit = habitProvider.habits[index];
                        return HabitCard(
                          habit: habit,
                          isCompletedToday: habitProvider.isHabitCompletedOnDate(habit.id, _today),
                          onToggle: () => habitProvider.toggleHabitLog(habit.id, _today),
                          onDelete: () => _confirmDeleteHabit(context, habit.id),
                          onEdit: () => _showEditHabitDialog(context, habit),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('添加习惯', style: TextStyle(color: Color(0xFF333333))),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF333333)),
          decoration: InputDecoration(
            hintText: '习惯名称',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8700),
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<HabitProvider>().addHabit(nameController.text.trim(), 7);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHabit(BuildContext context, String habitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('确认删除', style: TextStyle(color: Color(0xFF333333))),
        content: Text('确定要删除这个习惯吗？', style: TextStyle(color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<HabitProvider>().deleteHabit(habitId);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, dynamic habit) {
    final nameController = TextEditingController(text: habit.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('编辑习惯', style: TextStyle(color: Color(0xFF333333))),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF333333)),
          decoration: InputDecoration(
            hintText: '习惯名称',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A99D),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<HabitProvider>().updateHabitName(habit.id, nameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}