class Diary {
  final String id;
  final String date; // YYYY-MM-DD
  final String content;

  Diary({
    required this.id,
    required this.date,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'content': content,
    };
  }

  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'],
      date: map['date'],
      content: map['content'],
    );
  }

  Diary copyWith({
    String? id,
    String? date,
    String? content,
  }) {
    return Diary(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
    );
  }
}