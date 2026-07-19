class Habit {
  final String id;
  final String name;
  final int targetFrequency; // 每周次数
  final int currentStreak;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.targetFrequency,
    this.currentStreak = 0,
    required this.createdAt,
  }) : assert(
            targetFrequency > 0,
            'targetFrequency 必须 > 0，实际: $targetFrequency',
          ),
       assert(
            currentStreak >= 0,
            'currentStreak 必须 >= 0，实际: $currentStreak',
          );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetFrequency': targetFrequency,
      'currentStreak': currentStreak,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      targetFrequency: map['targetFrequency'],
      currentStreak: map['currentStreak'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    int? targetFrequency,
    int? currentStreak,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}