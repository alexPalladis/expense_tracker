import 'package:flutter/material.dart';
import '../utils/category_style.dart';

class ExpenseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final CategoryStyle style;
  final VoidCallback? onTap;
  final String? heroTag;

  const ExpenseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.style,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: style.color.withOpacity(0.8), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIcon(),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: _buildAmount(),
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: Material(color: Colors.transparent, child: card),
      );
    }
    return card;
  }

  Widget _buildIcon() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(style.icon, color: const Color(0xFF3949AB), size: 20),
    );
  }

  Widget _buildAmount() {
    return Text(
      amount,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Color(0xFF3949AB),
      ),
    );
  }
}