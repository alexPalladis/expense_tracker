import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/category.dart';

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

  void _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
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
    if (confirm == true) {
      await DatabaseHelper.instance.deleteCategory(category.id!);
      _loadCategories();
    }
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
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEEF0FF),
                      child: Icon(Icons.label_outline,
                          color: const Color(0xFF3949AB)),
                    ),
                    title: Text(cat.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: cat.description != null
                        ? Text(cat.description!)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Color(0xFF3949AB)),
                          onPressed: () =>
                              _showCategoryDialog(existing: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(cat),
                        ),
                      ],
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