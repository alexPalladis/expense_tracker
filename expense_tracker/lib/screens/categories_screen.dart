import 'package:expense_tracker/db/database_config.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/category_style.dart';
import '../widgets/animated_list_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/shimmer_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  Map<int, int> _expenseCount = {};
  Map<int, double> _expenseTotal = {};
  bool _showHint = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    final cats = await DatabaseConfig.instance.getAllCategories();
    final expenses = await DatabaseConfig.instance.getAllExpenses();

    final Map<int, int> count = {};
    final Map<int, double> total = {};
    for (final e in expenses) {
      count[e.categoryId] = (count[e.categoryId] ?? 0) + 1;
      total[e.categoryId] = (total[e.categoryId] ?? 0) + e.amount;
    }

    setState(() {
      _categories = cats;
      _expenseCount = count;
      _expenseTotal = total;
      _loading = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false, bool isDelete = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(message,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: isError
            ? Colors.red.shade600
            : isDelete
                ? Colors.red.shade600
                : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCategoryDialog({Category? existing}) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.label_outline,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    existing == null
                        ? 'Νέα κατηγορία'
                        : 'Επεξεργασία κατηγορίας',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Ονομασία *',
                  filled: true,
                  fillColor: const Color(0xFFF0F2FF),
                  prefixIcon: const Icon(Icons.label_outline,
                      color: Color(0xFF3949AB), size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF3949AB), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Περιγραφή (προαιρετική)',
                  filled: true,
                  fillColor: const Color(0xFFF0F2FF),
                  prefixIcon: const Icon(Icons.notes,
                      color: Color(0xFF3949AB), size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF3949AB), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ακύρωση',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3949AB).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            messenger.showSnackBar(SnackBar(
                              content: const Row(children: [
                                Icon(Icons.error_outline,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Η ονομασία είναι υποχρεωτική',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ]),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ));
                            return;
                          }
                          final category = Category(
                            id: existing?.id,
                            name: name,
                            description:
                                descController.text.trim().isEmpty
                                    ? null
                                    : descController.text.trim(),
                          );
                          if (existing == null) {
                            await DatabaseConfig.instance
                                .insertCategory(category);
                          } else {
                            await DatabaseConfig.instance
                                .updateCategory(category);
                          }
                          Navigator.pop(ctx);
                          _loadCategories();
                          messenger.showSnackBar(SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                existing == null
                                    ? 'Η κατηγορία δημιουργήθηκε!'
                                    : 'Η κατηγορία ενημερώθηκε!',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ]),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                        child: Text(
                          existing == null ? 'Προσθήκη' : 'Αποθήκευση',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final expenseCount = await DatabaseConfig.instance
        .getExpenseCountForCategory(category.id!);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          SizedBox(width: 8),
          Expanded(
              child: Text('Διαγραφή κατηγορίας',
                  style: TextStyle(fontSize: 16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Είστε σίγουροι για τη διαγραφή της κατηγορίας "${category.name}";'),
            if (expenseCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Υπάρχουν $expenseCount έξοδα σε αυτή την κατηγορία. '
                      'Θα μετακινηθούν αυτόματα στην κατηγορία "Άγνωστη".',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
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
              child: const Text('Διαγραφή')),
        ],
      ),
    );

    if (confirm == true) {
      if (expenseCount > 0) {
        final unknownId =
            await DatabaseConfig.instance.getOrCreateUnknownCategory();
        await DatabaseConfig.instance
            .moveExpensesToCategory(category.id!, unknownId);
      }
      await DatabaseConfig.instance.deleteCategory(category.id!);
      _loadCategories();
      if (mounted) {
        _showSnackBar('Η κατηγορία διαγράφηκε!', isDelete: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Κατηγορίες',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            if (_categories.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  '${_categories.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButton: (!_loading && _categories.isNotEmpty)
          ? GradientFab(onPressed: () => _showCategoryDialog())
          : null,
      body: _loading
          ? Column(
              children: List.generate(4, (_) => const ShimmerCard()),
            )
          : _categories.isEmpty
              ? EmptyState(
                  icon: Icons.label_off_outlined,
                  title: 'Καμία κατηγορία ακόμα.',
                  subtitle:
                      'Δημιουργήστε κατηγορίες για να οργανώσετε\nτα έξοδά σας.',
                  buttonLabel: 'Προσθήκη κατηγορίας',
                  onButtonPressed: () => _showCategoryDialog(),
                )
              : Column(
                  children: [
                    if (_showHint)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF3949AB)
                                  .withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.swipe,
                                color: Color(0xFF3949AB), size: 18),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Σύρε δεξιά για επεξεργασία · Σύρε αριστερά για διαγραφή',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF3949AB)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showHint = false),
                              child: const Icon(Icons.close,
                                  size: 16, color: Color(0xFF3949AB)),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final cat = _categories[i];
                          final style = getCategoryStyle(cat.name);
                          final count = _expenseCount[cat.id] ?? 0;
                          final total = _expenseTotal[cat.id] ?? 0.0;
                          final delay =
                              Duration(milliseconds: 60 * i.clamp(0, 15));

                          return AnimatedListCard(
                            key: Key(cat.id.toString()),
                            delay: delay,
                            child: Dismissible(
                              key: ValueKey('${cat.id}_dismiss'),
                              secondaryBackground: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete,
                                        color: Colors.white, size: 26),
                                    SizedBox(height: 4),
                                    Text('Διαγραφή',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3949AB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit,
                                        color: Colors.white, size: 26),
                                    SizedBox(height: 4),
                                    Text('Επεξεργασία',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction ==
                                    DismissDirection.startToEnd) {
                                  _showCategoryDialog(existing: cat);
                                  return false;
                                } else {
                                  await _deleteCategory(cat);
                                  return false;
                                }
                              },
                              onDismissed: (_) {},
                              child: Container(
                                decoration: BoxDecoration(
                                  color: style.color.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: style.color, width: 1.5),
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                  leading: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: style.color,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(style.icon,
                                        color: const Color(0xFF3949AB),
                                        size: 22),
                                  ),
                                  title: Text(cat.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  subtitle: cat.description != null
                                      ? Text(cat.description!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey))
                                      : null,
                                  trailing: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '€${total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF3949AB)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$count ${count == 1 ? 'έξοδο' : 'έξοδα'}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}