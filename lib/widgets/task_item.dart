import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: task.isCompleted
                        ? const Color(0xFF00A99D)
                        : _getCategoryColor(task.category),
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: task.isCompleted
                        ? const Color(0xFF00A99D)
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.content,
                      style: TextStyle(
                        color: task.isCompleted ? Colors.grey.shade500 : const Color(0xFF333333),
                        fontSize: 16,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: const Color(0xFF00A99D),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(task.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getCategoryLabel(task.category),
                      style: TextStyle(
                        color: _getCategoryColor(task.category),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.grey.shade400),
                    onPressed: onEdit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'work':
        return const Color(0xFFFF8700);
      case 'life':
        return const Color(0xFF00A99D);
      default:
        final colors = [
          const Color(0xFF9C27B0),
          const Color(0xFF3F51B5),
          const Color(0xFFE91E63),
          const Color(0xFF795548),
          const Color(0xFF607D8B),
          const Color(0xFF009688),
          const Color(0xFFFF5722),
          const Color(0xFF673AB7),
        ];
        final hash = category.hashCode.abs();
        return colors[hash % colors.length];
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'work':
        return '工作';
      case 'life':
        return '生活';
      default:
        return category;
    }
  }
}