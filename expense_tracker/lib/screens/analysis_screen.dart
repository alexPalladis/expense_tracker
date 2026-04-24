import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_config.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _results = [];
  bool _searched = false;
  int _touchedIndex = -1;

  final List<Color> _chartColors = [
    const Color(0xFF3949AB),
    const Color(0xFF26C6DA),
    const Color(0xFFEF5350),
    const Color(0xFFFFCA28),
    const Color(0xFF66BB6A),
    const Color(0xFFAB47BC),
    const Color(0xFFFF7043),
    const Color(0xFF26A69A),
  ];

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3949AB),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3949AB),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _analyze() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Παρακαλώ επιλέξτε και τις δύο ημερομηνίες',
                style: TextStyle(color: Colors.white)),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Η ημερομηνία λήξης πρέπει να είναι μετά την έναρξη',
                style: TextStyle(color: Colors.white)),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final start = _startDate!.toIso8601String();
    final end = DateTime(
            _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
        .toIso8601String();
    final results =
        await DatabaseConfig.instance.getExpensesByCategory(start, end);
    setState(() {
      _results = results;
      _searched = true;
      _touchedIndex = -1;
    });
  }

  void _clearAnalysis() {
    setState(() {
      _results = [];
      _searched = false;
      _startDate = null;
      _endDate = null;
      _touchedIndex = -1;
    });
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final total = _results.fold<double>(
        0, (sum, r) => sum + (r['total'] as double));

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
            ),
          ),
        ),
        title: const Text('Ανάλυση',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,

        actions: [
          if (_searched)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Νέα ανάλυση',
              onPressed: _clearAnalysis,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              crossFadeState: _searched
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Column(
                children: [

                  Row(children: [
                    Expanded(
                      child: _dateButton(
                        label: _startDate == null
                            ? 'Ημ/νία έναρξης'
                            : _fmt(_startDate!),
                        icon: Icons.calendar_today,
                        onTap: _pickStart,
                        selected: _startDate != null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateButton(
                        label: _endDate == null
                            ? 'Ημ/νία λήξης'
                            : _fmt(_endDate!),
                        icon: Icons.calendar_today,
                        onTap: _pickEnd,
                        selected: _endDate != null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bar_chart,
                            color: Colors.white),
                        label: const Text('Ανάλυση',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _analyze,
                      ),
                    ),
                  ),
                ],
              ),

              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF3949AB).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range,
                        color: Color(0xFF3949AB), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _startDate != null && _endDate != null
                          ? '${_fmt(_startDate!)}  →  ${_fmt(_endDate!)}'
                          : '',
                      style: const TextStyle(
                          color: Color(0xFF3949AB),
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clearAnalysis,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3949AB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close,
                                color: Color(0xFF3949AB), size: 14),
                            SizedBox(width: 4),
                            Text('Καθαρισμός',
                                style: TextStyle(
                                    color: Color(0xFF3949AB),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),


            if (_searched && _results.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_outlined,
                          size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Δεν βρέθηκαν έξοδα',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        'Δεν υπάρχουν έξοδα για την περίοδο\n${_fmt(_startDate!)} — ${_fmt(_endDate!)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh,
                            color: Color(0xFF3949AB)),
                        label: const Text('Νέα αναζήτηση',
                            style: TextStyle(color: Color(0xFF3949AB))),
                        onPressed: _clearAnalysis,
                      ),
                    ],
                  ),
                ),
              ),

            if (_results.isNotEmpty) ...[

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Σύνολο περιόδου',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('€${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('ΚΑΤΑΝΟΜΗ ΕΞΟΔΩΝ',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),


              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: _results.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      final rowTotal = row['total'] as double;
                      final percent =
                          total > 0 ? rowTotal / total * 100 : 0.0;
                      final isTouched = i == _touchedIndex;
                      return PieChartSectionData(
                        color: _chartColors[i % _chartColors.length],
                        value: rowTotal,
                        title: '${percent.toStringAsFixed(1)}%',
                        radius: isTouched ? 90 : 75,
                        titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      );
                    }).toList(),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),


              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _results.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _chartColors[i % _chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(row['category_name'],
                          style: const TextStyle(fontSize: 12)),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('ΑΝΑΛΥΣΗ ΑΝΑ ΚΑΤΗΓΟΡΙΑ',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),

     
              ...(_results.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final rowTotal = row['total'] as double;
                final percent = total > 0 ? rowTotal / total : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(
                          color: _chartColors[i % _chartColors.length],
                          width: 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _chartColors[
                                    i % _chartColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(row['category_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ]),
                          Text('€${rowTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3949AB))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _chartColors[i % _chartColors.length]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          '${(percent * 100).toStringAsFixed(1)}% του συνόλου',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              })),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool selected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEEF0FF)
              : const Color(0xFFF5F6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF3949AB).withOpacity(0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF3949AB)
                    : Colors.grey,
                size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF3949AB)
                      : Colors.grey,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}