import 'package:flutter/material.dart';

class ShimmerCard extends StatefulWidget {
  final double height;
  final EdgeInsets margin;

  const ShimmerCard({
    super.key,
    this.height = 72,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 10),
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1, end: 2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _shimmerBox({double? width, double? height, double radius = 8}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: Colors.grey.shade200, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Circle placeholder (icon)
            _shimmerBox(width: 42, height: 42, radius: 12),
            const SizedBox(width: 12),
            // Lines placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shimmerBox(width: double.infinity, height: 13, radius: 6),
                  const SizedBox(height: 8),
                  _shimmerBox(width: 100, height: 10, radius: 6),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount placeholder
            _shimmerBox(width: 60, height: 16, radius: 6),
          ],
        ),
      ),
    );
  }
}

Widget buildShimmerList({int count = 4, double height = 72}) {
  return Column(
    children: List.generate(count, (_) => ShimmerCard(height: height)),
  );
}