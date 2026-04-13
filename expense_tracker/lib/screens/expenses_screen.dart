import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../utils/category_style.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    final categories = await DatabaseHelper.instance.getAllCategories();
    setState(() {
      _expenses = expenses;
      _categories = categories;
    });
  }

  String _categoryName(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return 'Άγνωστη';
    }
  }

  Map<String, List<Expense>> _groupByDay() {
    final Map<String, List<Expense>> grouped = {};
    for (final e in _expenses) {
      final date = DateTime.parse(e.date);
      final now = DateTime.now();
      String key;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        key = 'Σήμερα';
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        key = 'Χθες';
      } else {
        key = '${date.day}/${date.month}/${date.year}';
      }
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return grouped;
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text('Διαγραφή εξόδου',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: const Text(
            'Είστε σίγουροι για τη διαγραφή αυτού του εξόδου;'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Άκυρο'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Διαγραφή'),
          ),
        ],
      ),
    );
  }

  void _showDetail(Expense expense) {
    final date = DateTime.parse(expense.date);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('€${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              Chip(
                label: Text(_categoryName(expense.categoryId)),
                backgroundColor: const Color(0xFFEEF0FF),
                labelStyle: const TextStyle(color: Color(0xFF3949AB)),
              ),
            ]),
            const SizedBox(height: 8),
            if (expense.description != null)
              Text(expense.description!,
                  style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.grey)),
            ]),
            if (expense.latitude != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.place, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${expense.locationName ?? ''}  (${expense.latitude!.toStringAsFixed(4)}, ${expense.longitude!.toStringAsFixed(4)})',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Επεξεργασία'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AddExpenseScreen(existing: expense)));
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Διαγραφή'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final confirm = await _confirmDelete(context);
                    if (confirm == true) {
                      await DatabaseHelper.instance.deleteExpense(expense.id!);
                      _loadData();
                    }
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();
    final keys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Έξοδα',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Δεν υπάρχουν έξοδα ακόμα.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Προσθέστε ένα.',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: keys.length,
              itemBuilder: (ctx, groupIndex) {
                final dayKey = keys[groupIndex];
                final dayExpenses = grouped[dayKey]!;
                final dayTotal = dayExpenses.fold<double>(
                    0, (sum, e) => sum + e.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dayKey,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 0.3)),
                          Text('€${dayTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3949AB))),
                        ],
                      ),
                    ),
                    ...dayExpenses.map((e) {
                      final style = getCategoryStyle(_categoryName(e.categoryId));
                      return Dismissible(
                        key: Key(e.id.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) => _confirmDelete(context),
                        onDismissed: (direction) async {
                          await DatabaseHelper.instance.deleteExpense(e.id!);
                          _loadData();
                        },
                        background: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, color: Colors.white, size: 26),
                              SizedBox(height: 4),
                              Text('Διαγραφή',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: ListTile(
                              onTap: () => _showDetail(e),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: style.color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(style.icon,
                                    color: const Color(0xFF3949AB), size: 20),
                              ),
                              title: Text(
                                e.description ?? _categoryName(e.categoryId),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                _categoryName(e.categoryId),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              trailing: Text(
                                '€${e.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF3949AB),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}