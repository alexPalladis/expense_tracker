import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/expense.dart';
import 'categories_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;

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
      if (widget.existing != null && cats.isNotEmpty) {
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

    Navigator.pop(context, true);
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3949AB)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3949AB),
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // ── Colored header ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF3949AB),
            foregroundColor: Colors.white,
            title: Text(
              isEdit ? 'Επεξεργασία Εξόδου' : 'Νέο Έξοδο',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF3949AB),
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.euro, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            _amountController.text.isEmpty
                                ? '0.00'
                                : _amountController.text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Section: Βασικά στοιχεία ──
                  _sectionHeader('ΒΑΣΙΚΑ ΣΤΟΙΧΕΙΑ', Icons.edit_outlined),
                  _card(
                    child: Column(
                      children: [
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Ποσό (€) *',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.euro,
                                color: Color(0xFF3949AB)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF3949AB), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _descController,
                          decoration: InputDecoration(
                            labelText: 'Περιγραφή (προαιρετική)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.notes,
                                color: Color(0xFF3949AB)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF3949AB), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section: Κατηγορία ──
                  _sectionHeader('ΚΑΤΗΓΟΡΙΑ', Icons.label_outline),
                  _card(
                    child: _categories.isEmpty
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Δημιουργήστε μία κατηγορία πρώτα'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3949AB),
                                foregroundColor: Colors.white),
                            onPressed: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const CategoriesScreen()));
                              _loadCategories();
                            },
                          )
                        : DropdownButtonFormField<Category>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Επιλέξτε κατηγορία *',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.label_outline,
                                  color: Color(0xFF3949AB)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF3949AB), width: 2),
                              ),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c.name)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section: Ημερομηνία ──
                  _sectionHeader('ΗΜΕΡΟΜΗΝΙΑ', Icons.calendar_today_outlined),
                  _card(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today,
                              color: Color(0xFF3949AB), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ημερομηνία & Ώρα',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          child: const Text('Αλλαγή',
                              style: TextStyle(color: Color(0xFF3949AB))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section: Τοποθεσία ──
                  _sectionHeader('ΤΟΠΟΘΕΣΙΑ', Icons.place_outlined),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _loadingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : Icon(_latitude != null
                                    ? Icons.location_on
                                    : Icons.my_location),
                            label: Text(_loadingLocation
                                ? 'Ανάκτηση τοποθεσίας...'
                                : _latitude != null
                                    ? 'Τοποθεσία ανακτήθηκε ✓'
                                    : 'Ανάκτηση τοποθεσίας'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _latitude != null
                                  ? Colors.green
                                  : const Color(0xFF3949AB),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _loadingLocation ? null : _getLocation,
                          ),
                        ),
                        if (_latitude != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.gps_fixed,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  'Lat: ${_latitude!.toStringAsFixed(4)},  Lng: ${_longitude!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _locationNameController,
                            decoration: InputDecoration(
                              labelText: 'Ονομασία τοποθεσίας (προαιρετική)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.place,
                                  color: Color(0xFF3949AB)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF3949AB), width: 2),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Save button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(isEdit ? Icons.check : Icons.save),
                      label: Text(
                        isEdit ? 'Ενημέρωση' : 'Αποθήκευση',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3949AB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _save,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}