import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../utils/category_style.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAll;
  final VoidCallback? onAnalysis;
  const HomeScreen({super.key, this.onViewAll, this.onAnalysis});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Expense> _recent = [];
  List<Category> _categories = [];
  double _monthTotal = 0;
  double _todayTotal = 0;
  List<_DayBar> _weekData = [];
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
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final monthData = await DatabaseHelper.instance
        .getExpensesByCategory(monthStart, now.toIso8601String());
    final todayData = await DatabaseHelper.instance
        .getExpensesByCategory(todayStart, todayEnd);

    final List<_DayBar> weekData = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayExpenses = expenses.where((e) {
        final d = DateTime.parse(e.date);
        return d.year == day.year && d.month == day.month && d.day == day.day;
      });
      final total = dayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      weekData.add(_DayBar(day: day, total: total, isToday: i == 0));
    }

    setState(() {
      _categories = categories;
      _recent = expenses.take(5).toList();
      _monthTotal = monthData.fold(0, (sum, r) => sum + (r['total'] as double));
      _todayTotal = todayData.fold(0, (sum, r) => sum + (r['total'] as double));
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

  String _dayLabel(DateTime d) {
    const days = ['Δε', 'Τρ', 'Τε', 'Πε', 'Πα', 'Σα', 'Κυ'];
    return days[d.weekday - 1];
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _ShimmerCard(),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = _weekData.isEmpty
        ? 1.0
        : _weekData.map((d) => d.total).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
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
                        child: _SummaryCard(
                          label: 'ΤΡΕΧΟΝ ΜΗΝΑΣ',
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

            // ── Bar chart ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
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
                      const Text('ΤΕΛΕΥΤΑΙΕΣ 7 ΗΜΕΡΕΣ',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _barAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            height: 120,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: _weekData.map((bar) {
                                final heightRatio = maxVal > 0
                                    ? bar.total / maxVal
                                    : 0.0;
                                final animatedHeight =
                                    80.0 * heightRatio * _barAnimation.value;
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (bar.total > 0)
                                      Opacity(
                                        opacity: _barAnimation.value,
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
                                        borderRadius:
                                            const BorderRadius.vertical(
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
                ),
              ),
            ),

            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 3, height: 16,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('ΠΡΟΣΦΑΤΑ ΕΞΟΔΑ',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.5)),
                    ]),
                    TextButton(
                      onPressed: widget.onViewAll,
                      child: const Text('Όλα',
                          style: TextStyle(color: Color(0xFF3949AB))),
                    ),
                  ],
                ),
              ),
            ),

            // ── Shimmer ή λίστα ή empty state ──
            if (_loading)
              SliverToBoxAdapter(child: _buildShimmer())
            else if (_recent.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Δεν υπάρχουν έξοδα ακόμα.',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text(
                            'Καταγράψτε τα καθημερινά σας έξοδα\nγια να παρακολουθείτε τις δαπάνες σας.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_outlined,
                                  color: Color(0xFF3949AB), size: 18),
                              SizedBox(width: 8),
                              Text('Πιέστε + για να ξεκινήσετε',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF3949AB))),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border(
                            left: BorderSide(
                                color: style.color.withOpacity(0.8),
                                width: 4),
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 42, height: 42,
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
      // Gradient FAB
      floatingActionButton: Container(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
            _loadData();
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _DayBar {
  final DateTime day;
  final double total;
  final bool isToday;
  _DayBar({required this.day, required this.total, required this.isToday});
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 8, color: Colors.white70, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

// Shimmer card widget
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}