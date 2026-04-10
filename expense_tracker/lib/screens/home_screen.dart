import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _recent = [];
  List<Category> _categories = [];
  double _monthTotal = 0;
  double _todayTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    final categories = await DatabaseHelper.instance.getAllCategories();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final monthData = await DatabaseHelper.instance
        .getExpensesByCategory(monthStart, now.toIso8601String());
    final todayData = await DatabaseHelper.instance
        .getExpensesByCategory(todayStart, todayEnd);

    setState(() {
      _categories = categories;
      _recent = expenses.take(5).toList();
      _monthTotal = monthData.fold(0, (sum, r) => sum + (r['total'] as double));
      _todayTotal = todayData.fold(0, (sum, r) => sum + (r['total'] as double));
    });
  }

  String _categoryName(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  Color _categoryColor(int index) {
    final colors = [
      const Color(0xFFEEF0FF),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
      const Color(0xFFFCE4EC),
      const Color(0xFFE0F7FA),
    ];
    return colors[index % colors.length];
  }

  IconData _categoryIcon(int index) {
    final icons = [
      Icons.shopping_cart_outlined,
      Icons.directions_bus_outlined,
      Icons.coffee_outlined,
      Icons.restaurant_outlined,
      Icons.label_outline,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── Custom SliverAppBar ──
            SliverAppBar(
  expandedHeight: 150,
  pinned: true,
  backgroundColor: const Color(0xFF3949AB),
  title: const Text(
    'Expense Tracker',
    style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  actions: [
    IconButton(
      icon: const Icon(Icons.bar_chart, color: Colors.white),
      onPressed: () {},
    ),
  ],
  flexibleSpace: FlexibleSpaceBar(
    background: Container(
      color: const Color(0xFF3949AB),
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'ΑΥΤΟΝ ΤΟΝ ΜΗΝΑ',
              value: '€${_monthTotal.toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'ΣΗΜΕΡΑ',
              value: '€${_todayTotal.toStringAsFixed(2)}',
            ),
          ),
        ],
      ),
    ),
  ),
),

            // ── Recent Expenses ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ΠΡOΣΦΑΤΑ ΕΞΟΔΑ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Όλα',
                          style: TextStyle(color: Color(0xFF3949AB))),
                    ),
                  ],
                ),
              ),
            ),

            _recent.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('Δεν υπάρχουν έξοδα ακόμα.',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('Πάτα + για να προσθέσεις ένα.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final e = _recent[i];
                        final date = DateTime.parse(e.date);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _categoryColor(i),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_categoryIcon(i),
                                    color: const Color(0xFF3949AB), size: 20),
                              ),
                              title: Text(
                                e.description ?? _categoryName(e.categoryId),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${_categoryName(e.categoryId)}  ·  ${date.day}/${date.month}/${date.year}',
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
                        );
                      },
                      childCount: _recent.length,
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3949AB),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
          _loadData();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }
}