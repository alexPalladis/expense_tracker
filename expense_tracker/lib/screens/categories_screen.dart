import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../utils/category_style.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getAllCategories();
    setState(() => _categories = cats);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing == null ? 'Νέα κατηγορία' : 'Επεξεργασία κατηγορίας'),
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
                messenger.showSnackBar(
                  const SnackBar(content: Text('Η ονομασία είναι υποχρεωτική')),
                );
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
            child: Text(existing == null ? 'Προσθήκη' : 'Αποθήκευση'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(Category category) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text('Διαγραφή κατηγορίας',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Text(
            'Είστε σίγουροι για τη διαγραφή της κατηγορίας "${category.name}";'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Κατηγορίες',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _categories.isEmpty
          ? const Center(
              child: Text(
                'Καμία κατηγορία ακόμα.\nΠιέστε + για να προσθέσετε μία.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final style = getCategoryStyle(cat.name);
                return Dismissible(
                  key: Key(cat.id.toString()),
                  // Swipe δεξιά = επεξεργασία
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
                  // Swipe αριστερά = διαγραφή
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
                        Icon(Icons.edit, color: Colors.white, size: 26),
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
                    if (direction == DismissDirection.startToEnd) {
                      // Swipe δεξιά = επεξεργασία
                      _showCategoryDialog(existing: cat);
                      return false; // μην αφαιρείς το item
                    } else {
                      // Swipe αριστερά = διαγραφή
                      return await _confirmDelete(cat);
                    }
                  },
                  onDismissed: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      await DatabaseHelper.instance.deleteCategory(cat.id!);
                      _loadCategories();
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: style.color,
                        child: Icon(style.icon,
                            color: const Color(0xFF3949AB), size: 20),
                      ),
                      title: Text(cat.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: cat.description != null
                          ? Text(cat.description!)
                          : const Text('Σύρε → επεξεργασία  |  ← διαγραφή',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3949AB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}