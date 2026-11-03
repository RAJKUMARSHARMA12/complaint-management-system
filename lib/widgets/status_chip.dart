import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final double? fontSize;
  final bool showIcon;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    IconData iconData;

    switch (status) {
      case 'Submitted':
        textColor = Colors.orange.shade900;
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        iconData = Icons.schedule_rounded;
        break;
      case 'Assigned':
        textColor = Colors.blue.shade900;
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        iconData = Icons.person_pin_rounded;
        break;
      case 'In Progress':
        textColor = Colors.amber.shade900;
        bgColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade300;
        iconData = Icons.engineering_rounded;
        break;
      case 'Resolved':
        textColor = Colors.green.shade900;
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case 'Closed':
        textColor = Colors.grey.shade800;
        bgColor = Colors.grey.shade200;
        borderColor = Colors.grey.shade300;
        iconData = Icons.task_alt_rounded;
        break;
      default:
        textColor = Colors.grey.shade800;
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade300;
        iconData = Icons.info_outline_rounded;
        break;
    }

    return Container(
      key: Key('status_chip_$status'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              iconData,
              size: (fontSize ?? 12) + 2,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
