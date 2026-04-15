import 'package:flutter/material.dart';

/// Reusable slide-in + fade-in animation wrapper
/// Χρησιμοποιείται σε Home, Expenses, Categories
class AnimatedListCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedListCard({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<AnimatedListCard> createState() => _AnimatedListCardState();
}

class _AnimatedListCardState extends State<AnimatedListCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
