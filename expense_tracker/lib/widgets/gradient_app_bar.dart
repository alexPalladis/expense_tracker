import 'package:flutter/material.dart';

/// Reusable gradient AppBar decoration — χρησιμοποιείται σε Expenses, Categories, Analysis
class GradientAppBarDecoration extends StatelessWidget
    implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool centerTitle;

  const GradientAppBarDecoration({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
          ),
        ),
      ),
      title: title,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: centerTitle,
      actions: actions,
    );
  }
}
