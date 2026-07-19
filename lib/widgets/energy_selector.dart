import 'package:flutter/material.dart';

class EnergySelector extends StatelessWidget {
  final int? selectedLevel;
  final Function(int) onLevelSelected;

  const EnergySelector({
    super.key,
    required this.selectedLevel,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final level = index + 1;
        final isSelected = selectedLevel == level;
        return GestureDetector(
          onTap: () => onLevelSelected(level),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level',
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00A99D) : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00A99D) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00A99D) : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.battery_charging_full,
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}