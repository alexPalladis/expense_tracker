import 'package:flutter/material.dart';

/// Reusable shimmer loading card — χρησιμοποιείται σε Home, Expenses
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}

/// Βοηθητική μέθοδος για να χτίσεις μια λίστα από shimmer cards
Widget buildShimmerList({int count = 4, double height = 72}) {
  return Column(
    children: List.generate(
      count,
      (i) => ShimmerCard(height: height),
    ),
  );
}
