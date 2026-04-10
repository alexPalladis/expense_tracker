import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';
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
      return 'Unknown';
    }
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
              Chip(label: Text(_categoryName(expense.categoryId))),
            ]),
            const SizedBox(height: 8),
            if (expense.description != null)
              Text(expense.description!,
                  style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
                '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.grey)),
            if (expense.latitude != null) ...[
              const SizedBox(height: 4),
              Text(
                  '📍 ${expense.locationName ?? ''}  (${expense.latitude!.toStringAsFixed(4)}, ${expense.longitude!.toStringAsFixed(4)})',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
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
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await DatabaseHelper.instance
                        .deleteExpense(expense.id!);
                    _loadData();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _expenses.isEmpty
          ? const Center(
              child: Text('No expenses yet.\nGo to Add to record one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final e = _expenses[i];
                final date = DateTime.parse(e.date);
                return Card(
                  child: ListTile(
                    onTap: () => _showDetail(e),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text('€',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                    ),
                    title: Text('€${e.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${_categoryName(e.categoryId)}  ·  ${date.day}/${date.month}/${date.year}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}