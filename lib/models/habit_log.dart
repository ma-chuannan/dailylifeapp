class HabitLog {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD
  final bool completed;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date,
      'completed': completed ? 1 : 0,
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    final raw = map['completed'];
    return HabitLog(
      id: map['id'],
      habitId: map['habitId'],
      date: map['date'],
      // 防御性写法：只接受 int 1；其他一切（int 0、bool、null、缺字段）安全降级为 false
      // - 数据库 sqflite 通常存 int（0/1）所以正常路径是 int 1
      // - bool / null / 缺字段 是非预期输入，全部安全降级为 false，不抛 TypeError
      completed: raw is int && raw == 1,
    );
  }
}