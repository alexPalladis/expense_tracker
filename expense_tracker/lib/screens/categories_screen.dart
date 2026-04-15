import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../utils/category_style.dart';
import '../widgets/animated_list_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_fab.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getAllCategories();
    final expenses = await DatabaseHelper.instance.getAllExpenses();

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
    });
  }

  void _showCategoryDialog({Category? existing}) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(existing == null
            ? 'Νέα κατηγορία'
            : 'Επεξεργασία κατηγορίας'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ονομασία *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Περιγραφή (προαιρετική)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ακύρωση'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Η ονομασία είναι υποχρεωτική')));
                return;
              }
              final category = Category(
                id: existing?.id,
                name: name,
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              );
              if (existing == null) {
                await DatabaseHelper.instance.insertCategory(category);
              } else {
                await DatabaseHelper.instance.updateCategory(category);
              }
              Navigator.pop(ctx);
              _loadCategories();
            },
            child:
                Text(existing == null ? 'Προσθήκη' : 'Αποθήκευση'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final expenseCount = await DatabaseHelper.instance
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
            Text('Είστε σίγουροι για τη διαγραφή της κατηγορίας "${category.name}";'),
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
            await DatabaseHelper.instance.getOrCreateUnknownCategory();
        await DatabaseHelper.instance
            .moveExpensesToCategory(category.id!, unknownId);
      }
      await DatabaseHelper.instance.deleteCategory(category.id!);
      _loadCategories();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      floatingActionButton: _categories.isEmpty
          ? null
          : GradientFab(onPressed: () => _showCategoryDialog()),
      body: _categories.isEmpty
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
                          color:
                              const Color(0xFF3949AB).withOpacity(0.2)),
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
                                fontSize: 12, color: Color(0xFF3949AB)),
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
                              border:
                                  Border.all(color: style.color, width: 1.5),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: style.color,
                                  borderRadius: BorderRadius.circular(12),
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
                                          fontSize: 12, color: Colors.grey))
                                  : null,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                                        fontSize: 11, color: Colors.grey),
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
