import 'package:flutter/material.dart';

class EscalationBadge extends StatefulWidget {
  final bool isCompact;

  const EscalationBadge({
    super.key,
    this.isCompact = false,
  });

  @override
  State<EscalationBadge> createState() => _EscalationBadgeState();
}

class _EscalationBadgeState extends State<EscalationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 6 : 8,
              vertical: widget.isCompact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: widget.isCompact ? 11 : 14,
                  color: Colors.white,
                ),
                SizedBox(width: widget.isCompact ? 3 : 4),
                Text(
                  widget.isCompact ? 'OVERDUE' : 'ESCALATED / OVERDUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isCompact ? 9 : 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
