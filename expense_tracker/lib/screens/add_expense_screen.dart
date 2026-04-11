import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/expense.dart';
import 'categories_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existing; // null = new expense, non-null = edit mode

  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _locationNameController = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // If editing, pre-fill all fields
    if (widget.existing != null) {
      final e = widget.existing!;
      _amountController.text = e.amount.toString();
      _descController.text = e.description ?? '';
      _locationNameController.text = e.locationName ?? '';
      _selectedDate = DateTime.parse(e.date);
      _latitude = e.latitude;
      _longitude = e.longitude;
    }
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getAllCategories();
    setState(() {
      _categories = cats;
      if (widget.existing != null) {
        _selectedCategory = cats.firstWhere(
          (c) => c.id == widget.existing!.categoryId,
          orElse: () => cats.first,
        );
      }
    });
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Η άδεια τοποθεσίας απορρίφθηκε.')));
        setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() => _loadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Δεν ανακτήθηκε τοποθεσία: $e')));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    // Validation
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Απαιτείται ποσό')));
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Εισάγετε έγκυρο ποσό')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Επιλέξτε κατηγορία')));
      return;
    }

    final expense = Expense(
      id: widget.existing?.id,
      amount: amount,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      categoryId: _selectedCategory!.id!,
      date: _selectedDate.toIso8601String(),
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationNameController.text.trim().isEmpty
          ? null
          : _locationNameController.text.trim(),
    );

    if (widget.existing == null) {
      await DatabaseHelper.instance.insertExpense(expense);
    } else {
      await DatabaseHelper.instance.updateExpense(expense);
    }

    Navigator.pop(context, true); // true = refresh parent
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text(
    widget.existing == null ? 'Προσθήκη Εξόδου' : 'Επεξεργασία Εξόδου',
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  backgroundColor: const Color(0xFF3949AB),
  foregroundColor: Colors.white,
  iconTheme: const IconThemeData(color: Colors.white),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ποσό (€) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Περιγραφή (προαιρετική)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),

            // Category picker
            _categories.isEmpty
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Δημιουργήστε μία κατηγορία πρώτα'),
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CategoriesScreen()));
                      _loadCategories();
                    },
                  )
                : DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Κατηγορία *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val),
                  ),
            const SizedBox(height: 16),

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.indigo),
              title: const Text('Ημερομηνία'),
              subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}'),
              trailing: TextButton(
                  onPressed: _pickDate, child: const Text('Αλλαγή')),
            ),
            const Divider(),

            // Location
            const Text('Τοποθεσία',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: _loadingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: Text(_loadingLocation
                  ? 'Ανάκτηση τοποθεσίας...'
                  : _latitude != null
                      ? 'Τοποθεσία ανακτήθηκε'
                      : 'Ανάκτηση τοποθεσίας'),
              onPressed: _loadingLocation ? null : _getLocation,
            ),
            if (_latitude != null) ...[
              const SizedBox(height: 8),
              Text(
                  'Lat: ${_latitude!.toStringAsFixed(5)},  Lng: ${_longitude!.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _locationNameController,
                decoration: const InputDecoration(
                  labelText: 'Ονομασία Τοποθεσίας (προαιρετική)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(widget.existing == null
                    ? 'Αποθήκευση'
                    : 'Ενημέρωση'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}