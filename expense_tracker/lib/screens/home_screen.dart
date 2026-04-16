import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../utils/category_style.dart';
import '../widgets/animated_list_card.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/summary_card.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAll;
  final VoidCallback? onAnalysis;
  final VoidCallback? onOpenDrawer;
  const HomeScreen({super.key, this.onViewAll, this.onAnalysis, this.onOpenDrawer});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Expense> _recent = [];
  List<Category> _categories = [];
  double _monthTotal = 0;
  double _todayTotal = 0;
  List<DayBar> _weekData = [];
  bool _loading = true;

  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnimation = CurvedAnimation(
      parent: _barController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await DatabaseHelper.instance.fixOrphanedExpenses();
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    final categories = await DatabaseHelper.instance.getAllCategories();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final todayStart =
        DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd =
        DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final monthData = await DatabaseHelper.instance
        .getExpensesByCategory(monthStart, now.toIso8601String());
    final todayData = await DatabaseHelper.instance
        .getExpensesByCategory(todayStart, todayEnd);

    final List<DayBar> weekData = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayExpenses = expenses.where((e) {
        final d = DateTime.parse(e.date);
        return d.year == day.year && d.month == day.month && d.day == day.day;
      });
      final total =
          dayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      weekData.add(DayBar(day: day, total: total, isToday: i == 0));
    }

    setState(() {
      _categories = categories;
      _recent = expenses.take(5).toList();
      _monthTotal =
          monthData.fold(0, (sum, r) => sum + (r['total'] as double));
      _todayTotal =
          todayData.fold(0, (sum, r) => sum + (r['total'] as double));
      _weekData = weekData;
      _loading = false;
    });

    _barController.forward(from: 0);
  }

  String _categoryName(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return 'Άγνωστη';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── Gradient SliverAppBar ──
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              backgroundColor: const Color(0xFF3949AB),
              leading: IconButton(
  icon: const Icon(Icons.menu, color: Colors.white),
  onPressed: widget.onOpenDrawer, 
),
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
                  onPressed: widget.onAnalysis,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          label: 'ΤΡΕΧΟΝ ΜΗΝΑΣ',
                          value: '€${_monthTotal.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          label: 'ΣΗΜΕΡΑ',
                          value: '€${_todayTotal.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bar chart ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: WeekBarChart(
                  weekData: _weekData,
                  animation: _barAnimation,
                ),
              ),
            ),

            // ── Header "ΠΡΟΣΦΑΤΑ ΕΞΟΔΑ" ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionLabel(text: 'ΠΡΟΣΦΑΤΑ ΕΞΟΔΑ'),
                    TextButton(
                      onPressed: widget.onViewAll,
                      child: const Text('Όλα',
                          style: TextStyle(color: Color(0xFF3949AB))),
                    ),
                  ],
                ),
              ),
            ),

            // ── Shimmer / Empty / List ──
            if (_loading)
              SliverToBoxAdapter(
                child: Column(
                  children: List.generate(
                    3,
                    (_) => const ShimmerCard(),
                  ),
                ),
              )
            else if (_recent.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Δεν υπάρχουν έξοδα ακόμα.',
                  subtitle:
                      'Καταγράψτε τα καθημερινά σας έξοδα\nγια να παρακολουθείτε τις δαπάνες σας.',
                  hint: const HintChip(
                    icon: Icons.touch_app_outlined,
                    text: 'Πιέστε + για να ξεκινήσετε',
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final e = _recent[i];
                    final date = DateTime.parse(e.date);
                    final style =
                        getCategoryStyle(_categoryName(e.categoryId));
                    return AnimatedListCard(
                      key: Key(e.id.toString()),
                      delay: Duration(milliseconds: 60 * i.clamp(0, 10)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: ExpenseCard(
                          title: e.description ?? _categoryName(e.categoryId),
                          subtitle:
                              '${_categoryName(e.categoryId)}  ·  ${date.day}/${date.month}/${date.year}',
                          amount: '€${e.amount.toStringAsFixed(2)}',
                          style: style,
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
      floatingActionButton: GradientFab(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
          _loadData();
        },
      ),
    );
  }
}
