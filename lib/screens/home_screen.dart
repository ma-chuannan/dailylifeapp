import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/mood_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/habit_card.dart';
import '../widgets/mood_selector.dart';
import '../widgets/energy_selector.dart';
import '../models/task.dart';
import '../models/habit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _taskController = TextEditingController();
  String _selectedCategory = 'work';
  String _customCategoryName = '';
  String _taskDate = '';
  bool _isTomorrow = false;

  @override
  void initState() {
    super.initState();
    try {
      _taskDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    } catch (e, st) {
      _taskDate = DateTime.now().toIso8601String().substring(0, 10);
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await context.read<TaskProvider>().loadTasksByDate(_taskDate);
      await context.read<HabitProvider>().loadAllHabits();
      await context.read<HabitProvider>().loadHabitLogsByDate(_taskDate);
      await context.read<MoodProvider>().loadMoodByDate(_taskDate);
    } catch (e, st) {
      debugPrint('load error: $e\n$st');
    }
  }

  String get _displayDate {
    final now = DateTime.now();
    final targetDate = DateTime.parse(_taskDate);
    if (_isSameDay(targetDate, now)) return '今天';
    if (_isSameDay(targetDate, now.add(const Duration(days: 1)))) return '明天';
    return DateFormat('MM月dd日').format(targetDate);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _toggleDate() {
    setState(() {
      _isTomorrow = !_isTomorrow;
      final now = DateTime.now();
      if (_isTomorrow) {
        _taskDate = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      } else {
        _taskDate = DateFormat('yyyy-MM-dd').format(now);
      }
    });
    _loadData();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_taskDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _taskDate = DateFormat('yyyy-MM-dd').format(picked);
        _isTomorrow = false;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFF8700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('每日任务', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _toggleDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(_isTomorrow ? '明天' : '今天', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('日期', style: TextStyle(color: Colors.white, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _displayDate,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFFFF8700),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMoodSection(),
                      const SizedBox(height: 16),
                      _buildHabitsSection(),
                      const SizedBox(height: 16),
                      _buildTasksSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8700).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF8700).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8700),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('今日心情', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        MoodSelector(
                          selectedMood: moodProvider.todayMood?.mood,
                          onMoodSelected: (mood) => moodProvider.saveMood(_taskDate, mood, moodProvider.todayMood?.energyLevel ?? 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A99D),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('精力水平', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        EnergySelector(
                          selectedLevel: moodProvider.todayMood?.energyLevel,
                          onLevelSelected: (level) => moodProvider.saveMood(_taskDate, moodProvider.todayMood?.mood ?? 'neutral', level),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitsSection() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8700),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('代办事项', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => _showAddHabitDialog(context),
                  child: const Text('+ 添加', style: TextStyle(color: Color(0xFF00A99D), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (habitProvider.habits.isEmpty)
              GestureDetector(
                onTap: () => _showAddHabitDialog(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.repeat, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('点击添加习惯', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...habitProvider.habits.map((habit) => HabitCard(
                habit: habit,
                isCompletedToday: habitProvider.isHabitCompletedOnDate(habit.id, DateFormat('yyyy-MM-dd').format(DateTime.now())),
                onToggle: () => habitProvider.toggleHabitLog(habit.id, DateFormat('yyyy-MM-dd').format(DateTime.now())),
                onDelete: () => _confirmDeleteHabit(context, habit.id),
                onEdit: () => _showEditHabitDialog(context, habit),
              )),
          ],
        );
      },
    );
  }

  Widget _buildTasksSection() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8700),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '任务列表 (${taskProvider.completedCount}/${taskProvider.totalCount})',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _copyTasksToTomorrow(context, taskProvider),
                      child: const Text('→ 明天', style: TextStyle(color: Color(0xFFFF8700), fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: _showAddTaskDialog,
                      child: const Text('+ 添加', style: TextStyle(color: Color(0xFF00A99D), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (taskProvider.tasks.isEmpty)
              GestureDetector(
                onTap: _showAddTaskDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('点击添加任务', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...taskProvider.tasks.map((task) => TaskItem(
                task: task,
                onToggle: () => taskProvider.toggleTaskCompletion(task.id),
                onDelete: () => taskProvider.deleteTask(task.id),
                onEdit: () => _showEditTaskDialog(context, task),
              )),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    _taskController.text = task.content;
    _selectedCategory = task.category == 'work' || task.category == 'life' || task.category == 'study' ? task.category : 'other';
    _customCategoryName = task.category == 'work' || task.category == 'life' || task.category == 'study' ? '' : task.category;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('编辑任务', style: TextStyle(color: Color(0xFF333333), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _taskController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF333333)),
                decoration: InputDecoration(
                  hintText: '输入任务内容',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildCategoryChip('work', '工作', setModalState),
                  const SizedBox(width: 8),
                  _buildCategoryChip('life', '生活', setModalState),
                  const SizedBox(width: 8),
                  _buildCategoryChip('study', '学习', setModalState),
                  const SizedBox(width: 8),
                  _buildCategoryChip('other', '自定义', setModalState),
                ],
              ),
              if (_selectedCategory == 'other' || _customCategoryName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: TextEditingController(text: _customCategoryName),
                    onChanged: (value) {
                      setModalState(() {
                        _customCategoryName = value;
                      });
                    },
                    style: const TextStyle(color: Color(0xFF333333)),
                    decoration: InputDecoration(
                      hintText: '输入自定义标签名称',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8700),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_taskController.text.trim().isNotEmpty) {
                      final category = _selectedCategory == 'other'
                          ? (_customCategoryName.isEmpty ? '自定义' : _customCategoryName)
                          : _selectedCategory;
                      context.read<TaskProvider>().updateTaskContent(task.id, _taskController.text.trim(), category);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('保存', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, Habit habit) {
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

  void _showAddTaskDialog() {
    _taskController.clear();
    _selectedCategory = 'work';
    _customCategoryName = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('添加任务', style: TextStyle(color: Color(0xFF333333), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _taskController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF333333)),
                decoration: InputDecoration(
                  hintText: '输入任务内容',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildCategoryChip('work', '工作', setModalState),
                  const SizedBox(width: 8),
                  _buildCategoryChip('life', '生活', setModalState),
                  const SizedBox(width: 8),
                  _buildCategoryChip('study', '学习', setModalState),
                  const SizedBox(width: 8),
                  _buildCategoryChip('other', '自定义', setModalState),
                ],
              ),
              if (_selectedCategory == 'other' || _customCategoryName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    onChanged: (value) {
                      setModalState(() {
                        _customCategoryName = value;
                      });
                    },
                    style: const TextStyle(color: Color(0xFF333333)),
                    decoration: InputDecoration(
                      hintText: '输入自定义标签名称',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8700),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_taskController.text.trim().isNotEmpty) {
                      final category = _selectedCategory == 'other'
                          ? (_customCategoryName.isEmpty ? '自定义' : _customCategoryName)
                          : _selectedCategory;
                      context.read<TaskProvider>().addTask(_taskController.text.trim(), category, _taskDate);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('添加', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, StateSetter setModalState) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedCategory = category;
        });
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8700) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF333333),
          ),
        ),
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
              backgroundColor: const Color(0xFF00A99D),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<HabitProvider>().addHabit(nameController.text.trim(), 7);
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A99D),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<HabitProvider>().deleteHabit(habitId);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _copyTasksToTomorrow(BuildContext context, TaskProvider taskProvider) {
    final uncompletedTasks = taskProvider.tasks.where((t) => !t.isCompleted).toList();
    if (uncompletedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有未完成的任务'), duration: Duration(seconds: 2)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('添加到明天', style: TextStyle(color: Color(0xFF333333))),
        content: Text('确定要把 ${uncompletedTasks.length} 个未完成任务添加到明天吗？', style: TextStyle(color: Colors.grey.shade600)),
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
            onPressed: () async {
              final tomorrow = DateTime.now().add(const Duration(days: 1));
              final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);
              for (final task in uncompletedTasks) {
                await taskProvider.addTask(task.content, task.category, tomorrowStr);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已添加 ${uncompletedTasks.length} 个任务到明天'), duration: const Duration(seconds: 2)),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
