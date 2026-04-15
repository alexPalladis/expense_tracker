import 'package:flutter/material.dart';

class DayBar {
  final DateTime day;
  final double total;
  final bool isToday;
  DayBar({required this.day, required this.total, required this.isToday});
}

/// Animated bar chart για τις τελευταίες 7 ημέρες
class WeekBarChart extends StatelessWidget {
  final List<DayBar> weekData;
  final Animation<double> animation;

  const WeekBarChart({
    super.key,
    required this.weekData,
    required this.animation,
  });

  String _dayLabel(DateTime d) {
    const days = ['Δε', 'Τρ', 'Τε', 'Πε', 'Πα', 'Σα', 'Κυ'];
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = weekData.isEmpty
        ? 1.0
        : weekData.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    final weekTotal =
        weekData.fold<double>(0, (sum, b) => sum + b.total);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ΤΕΛΕΥΤΑΙΕΣ 7 ΗΜΕΡΕΣ',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Εβδομάδα: €${weekTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekData.map((bar) {
                    final heightRatio =
                        maxVal > 0 ? bar.total / maxVal : 0.0;
                    final animatedHeight =
                        80.0 * heightRatio * animation.value;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (bar.total > 0)
                          Opacity(
                            opacity: animation.value,
                            child: Text(
                              '€${bar.total.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: bar.isToday
                                      ? const Color(0xFF3949AB)
                                      : Colors.grey),
                            ),
                          ),
                        if (bar.total > 0) const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: bar.total > 0
                              ? animatedHeight.clamp(0.0, 80.0)
                              : 4,
                          decoration: BoxDecoration(
                            gradient: bar.total > 0
                                ? LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: bar.isToday
                                        ? [
                                            const Color(0xFF3949AB),
                                            const Color(0xFF1E88E5)
                                          ]
                                        : [
                                            const Color(0xFF3949AB)
                                                .withOpacity(0.2),
                                            const Color(0xFF3949AB)
                                                .withOpacity(0.4)
                                          ],
                                  )
                                : null,
                            color: bar.total == 0
                                ? Colors.grey.shade200
                                : null,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _dayLabel(bar.day),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: bar.isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: bar.isToday
                                ? const Color(0xFF3949AB)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
