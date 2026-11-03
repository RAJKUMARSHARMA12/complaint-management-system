import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final double? fontSize;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    IconData icon;

    switch (priority) {
      case 'Urgent':
        color = Colors.red.shade800;
        bgColor = Colors.red.shade50;
        icon = Icons.local_fire_department_rounded;
        break;
      case 'High':
        color = Colors.deepOrange.shade800;
        bgColor = Colors.deepOrange.shade50;
        icon = Icons.priority_high_rounded;
        break;
      case 'Medium':
        color = Colors.amber.shade900;
        bgColor = Colors.amber.shade50;
        icon = Icons.remove_rounded;
        break;
      case 'Low':
      default:
        color = Colors.teal.shade800;
        bgColor = Colors.teal.shade50;
        icon = Icons.arrow_downward_rounded;
        break;
    }

    return Container(
      key: Key('priority_badge_$priority'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: (fontSize ?? 11) + 2,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontSize: fontSize ?? 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
