class MoodEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final String mood; // happy, neutral, sad, angry
  final int energyLevel; // 1-5

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.energyLevel,
  }) : assert(
            energyLevel >= 1 && energyLevel <= 5,
            'energyLevel 必须在 1-5 之间，实际: $energyLevel',
          ),
       assert(
            const ['happy', 'neutral', 'sad', 'angry'].contains(mood),
            'mood 必须是 happy/neutral/sad/angry 之一，实际: $mood',
          );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mood': mood,
      'energyLevel': energyLevel,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      date: map['date'],
      mood: map['mood'],
      energyLevel: map['energyLevel'],
    );
  }

  MoodEntry copyWith({
    String? id,
    String? date,
    String? mood,
    int? energyLevel,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      energyLevel: energyLevel ?? this.energyLevel,
    );
  }
}