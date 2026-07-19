import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  final String? selectedMood;
  final Function(String) onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final moods = [
      {'key': 'happy', 'emoji': '😊', 'label': '开心'},
      {'key': 'neutral', 'emoji': '😐', 'label': '平静'},
      {'key': 'sad', 'emoji': '😔', 'label': '低落'},
      {'key': 'angry', 'emoji': '😤', 'label': '烦躁'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.map((mood) {
        final isSelected = selectedMood == mood['key'];
        return GestureDetector(
          onTap: () => onMoodSelected(mood['key'] as String),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF8700)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFFFF8700) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  mood['emoji'] as String,
                  style: TextStyle(
                    fontSize: isSelected ? 28 : 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}