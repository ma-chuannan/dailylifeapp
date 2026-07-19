class Task {
  final String id;
  final String content;
  final String category; // work, life, other
  final bool isCompleted;
  final DateTime? completedAt;
  final String date; // YYYY-MM-DD

  Task({
    required this.id,
    required this.content,
    required this.category,
    this.isCompleted = false,
    this.completedAt,
    required this.date,
  }) : assert(
            isCompleted == (completedAt != null),
            'isCompleted 和 completedAt 必须一致：\n'
            '  isCompleted=true 时 completedAt 必须有值\n'
            '  isCompleted=false 时 completedAt 必须为 null',
          );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'date': date,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      content: map['content'],
      category: map['category'],
      isCompleted: map['isCompleted'] == 1,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      date: map['date'],
    );
  }

  // Sentinel 用于 copyWith 区分"未传参数"和"传 null"
  // 不这样写的话 ?? this.completedAt 会让 null 失效
  // （这是 Critical #1 修复：un-complete task 时 assert 不再误触发）
  static const Object _sentinel = Object();

  Task copyWith({
    String? id,
    String? content,
    String? category,
    bool? isCompleted,
    Object? completedAt = _sentinel,
    String? date,
  }) {
    return Task(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: identical(completedAt, _sentinel)
          ? this.completedAt
          : completedAt as DateTime?,
      date: date ?? this.date,
    );
  }
}