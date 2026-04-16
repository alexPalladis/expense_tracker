import 'package:expense_tracker/db/database_config.dart';
import 'package:flutter/material.dart';
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
        return d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
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

  void _openAddExpense() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const AddExpenseScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    _loadData();
  }

  void _showDetail(Expense expense) {
    final style = getCategoryStyle(_categoryName(expense.categoryId));
    final date = DateTime.parse(expense.date);
    final heroTag = 'expense_${expense.id}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailSheet(
        expense: expense,
        style: style,
        date: date,
        heroTag: heroTag,
        categoryName: _categoryName(expense.categoryId),
        onEdit: () async {
          Navigator.pop(ctx);
          await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) =>
                    AddExpenseScreen(existing: expense),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ));
          _loadData();
        },
        onDelete: () async {
          Navigator.pop(ctx);
          final confirm = await _confirmDelete(context);
          if (confirm == true) {
            await DatabaseHelper.instance.deleteExpense(expense.id!);
            _loadData();
          }
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          SizedBox(width: 8),
          Expanded(
              child: Text('Διαγραφή εξόδου',
                  style: TextStyle(fontSize: 16))),
        ]),
        content: const Text(
            'Είστε σίγουροι για τη διαγραφή αυτού του εξόδου;'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Άκυρο')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF3949AB),
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 60,
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
                          amount: _monthTotal,
                          gradient: const [
                            Color(0xFF3949AB),
                            Color(0xFF7B1FA2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          label: 'ΣΗΜΕΡΑ',
                          amount: _todayTotal,
                          gradient: const [
                            Color(0xFF00897B),
                            Color(0xFF1E88E5),
                          ],
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
                  children: List.generate(3, (_) => const ShimmerCard()),
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
                    final heroTag = 'expense_${e.id}';
                    return AnimatedListCard(
                      key: Key(e.id.toString()),
                      delay: Duration(milliseconds: 60 * i.clamp(0, 10)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: ExpenseCard(
                          title: e.description ??
                              _categoryName(e.categoryId),
                          subtitle:
                              '${_categoryName(e.categoryId)}  ·  ${date.day}/${date.month}/${date.year}',
                          amount: '€${e.amount.toStringAsFixed(2)}',
                          style: style,
                          heroTag: heroTag,
                          onTap: () => _showDetail(e),
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
        onPressed: _openAddExpense,
      ),
    );
  }
}

// ── Detail Bottom Sheet με Hero ──
class _DetailSheet extends StatelessWidget {
  final Expense expense;
  final CategoryStyle style;
  final DateTime date;
  final String heroTag;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailSheet({
    required this.expense,
    required this.style,
    required this.date,
    required this.heroTag,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.75,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Gradient header με Hero
            Hero(
              tag: heroTag,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        style.color.withOpacity(0.9),
                        style.color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: style.color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: '${heroTag}_amount',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                '€${expense.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          if (expense.description != null)
                            Text(
                              expense.description!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13),
                            ),
                        ],
                      ),
                      Hero(
                        tag: '${heroTag}_icon',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(style.icon,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Details
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  _detailRow(Icons.label_outline, 'Κατηγορία', categoryName),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.calendar_today,
                    'Ημερομηνία',
                    '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  ),
                  if (expense.latitude != null) ...[
                    const SizedBox(height: 12),
                    _detailRow(
                      Icons.place,
                      'Τοποθεσία',
                      '${expense.locationName ?? ''}  (${expense.latitude!.toStringAsFixed(4)}, ${expense.longitude!.toStringAsFixed(4)})',
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Επεξεργασία'),
                        onPressed: onEdit,
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
                        onPressed: onDelete,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF3949AB), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}