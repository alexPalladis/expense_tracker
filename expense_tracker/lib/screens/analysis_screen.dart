import 'package:flutter/material.dart';
import '../db/database_helper.dart';

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

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _analyze() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both dates')));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Η ημερομηνία λήξης πρέπει να είναι μετά την ημερομηνία έναρξης')));
      return;
    }

    // Use end of day for endDate so it includes all expenses on that day
    final start = _startDate!.toIso8601String();
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day,
            23, 59, 59)
        .toIso8601String();

    final results =
        await DatabaseHelper.instance.getExpensesByCategory(start, end);
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final total = _results.fold<double>(
        0, (sum, r) => sum + (r['total'] as double));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ανάλυση'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range pickers
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                      _startDate == null ? 'Ημ/νία έναρξης' : _fmt(_startDate!)),
                  onPressed: _pickStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                      _endDate == null ? 'Ημ/νία λήξης' : _fmt(_endDate!)),
                  onPressed: _pickEnd,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text('Ανάλυση'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _analyze,
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_searched && _results.isEmpty)
              const Center(
                  child: Text('Δε βρέθηκαν έξοδα για αυτή την περίοδο.',
                      style: TextStyle(color: Colors.grey))),

            if (_results.isNotEmpty) ...[
              Text('Total: €${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final row = _results[i];
                    final rowTotal = row['total'] as double;
                    final percent =
                        total > 0 ? rowTotal / total : 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(row['category_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text('€${rowTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: percent,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text('${(percent * 100).toStringAsFixed(1)}% of total',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}