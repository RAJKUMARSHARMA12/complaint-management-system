import 'package:flutter/material.dart';

/// A reusable shimmer loading container that pulses gracefully.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// A skeleton loader placeholder mimicking a complaint card.
class ComplaintCardSkeleton extends StatelessWidget {
  const ComplaintCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 80, height: 20, borderRadius: 4),
                SizedBox(width: 8),
                ShimmerBox(width: 60, height: 20, borderRadius: 4),
                Spacer(),
                ShimmerBox(width: 75, height: 22, borderRadius: 12),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBox(width: double.infinity, height: 18, borderRadius: 4),
            SizedBox(height: 8),
            ShimmerBox(width: 180, height: 14, borderRadius: 4),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 100, height: 14, borderRadius: 4),
                ShimmerBox(width: 65, height: 14, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A full list of skeleton cards for loading states.
class ComplaintListSkeleton extends StatelessWidget {
  final int count;

  const ComplaintListSkeleton({
    super.key,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: count,
      itemBuilder: (context, index) => const ComplaintCardSkeleton(),
    );
  }
}
