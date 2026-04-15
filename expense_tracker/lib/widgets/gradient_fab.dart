import 'package:flutter/material.dart';

/// Reusable gradient FAB — χρησιμοποιείται σε Home, Expenses, Categories
class GradientFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const GradientFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3949AB).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: onPressed,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
