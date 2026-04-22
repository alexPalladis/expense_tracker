import 'package:expense_tracker/db/database_config.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../widgets/section_header.dart';
import 'categories_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;
  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _locationNameController = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;

  late AnimationController _headerController;
  late Animation<Color?> _colorAnim1;
  late Animation<Color?> _colorAnim2;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _colorAnim1 = ColorTween(
      begin: const Color(0xFF3949AB),
      end: const Color(0xFF7B1FA2),
    ).animate(_headerController);

    _colorAnim2 = ColorTween(
      begin: const Color(0xFF1E88E5),
      end: const Color(0xFF00897B),
    ).animate(_headerController);

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

  @override
  void dispose() {
    _headerController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseConfig.instance.getAllCategories();
    setState(() {
      _categories = cats;
      if (widget.existing != null && cats.isNotEmpty) {
        _selectedCategory = cats.firstWhere(
          (c) => c.id == widget.existing!.categoryId,
          orElse: () => cats.first,
        );
      } else if (_selectedCategory != null && cats.isNotEmpty) {
        final stillExists = cats.where((c) => c.id == _selectedCategory!.id);
        _selectedCategory = stillExists.isNotEmpty ? stillExists.first : null;
      }
    });
  }

  Future<void> _openCategoriesScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
    );
    await _loadCategories();
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Η άδεια τοποθεσίας απορρίφθηκε.')));
        }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Δεν ανακτήθηκε τοποθεσία: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3949AB),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (_amountController.text.trim().isEmpty) {
      _showError('Απαιτείται ποσό');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Εισάγετε έγκυρο ποσό');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Επιλέξτε κατηγορία');
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
      await DatabaseConfig.instance.insertExpense(expense);
    } else {
      await DatabaseConfig.instance.updateExpense(expense);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.existing == null
                    ? 'Το έξοδο αποθηκεύτηκε!'
                    : 'Το έξοδο ενημερώθηκε!',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pop(context, true);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(msg, style: const TextStyle(color: Colors.white)),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF0F2FF),
      prefixIcon: Icon(icon, color: const Color(0xFF3949AB), size: 20),
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
        borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3949AB).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      body: CustomScrollView(
        slivers: [
          // ── Animated Gradient Header ──
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            foregroundColor: Colors.white,
            title: Text(
              isEdit ? 'Επεξεργασία Εξόδου' : 'Νέο Έξοδο',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            flexibleSpace: AnimatedBuilder(
              animation: _headerController,
              builder: (context, _) {
                return FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _colorAnim1.value ?? const Color(0xFF3949AB),
                          _colorAnim2.value ?? const Color(0xFF1E88E5),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Amount preview with glow
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.euro,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                _amountController.text.isEmpty
                                    ? '0.00'
                                    : _amountController.text,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            backgroundColor: const Color(0xFF3949AB),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 
                  const SectionHeader(
                      title: 'ΒΑΣΙΚΑ ΣΤΟΙΧΕΙΑ',
                      icon: Icons.edit_outlined),
                  _sectionCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          decoration:
                              _inputDecoration('Ποσό (€) *', Icons.euro),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descController,
                          decoration: _inputDecoration(
                              'Περιγραφή (προαιρετική)', Icons.notes),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SectionHeader(
                      title: 'ΚΑΤΗΓΟΡΙΑ', icon: Icons.label_outline),
                  _sectionCard(
                    child: Column(
                      children: [
                        if (_categories.isEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text(
                                'Δημιουργήστε μία κατηγορία πρώτα'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3949AB),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _openCategoriesScreen,
                          )
                        else
                          DropdownButtonFormField<Category>(
                            value: _selectedCategory,
                            decoration: _inputDecoration(
                                'Επιλέξτε κατηγορία *',
                                Icons.label_outline),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.name),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Νέα κατηγορία'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3949AB),
                              side: const BorderSide(
                                  color: Color(0xFF3949AB)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _openCategoriesScreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SectionHeader(
                      title: 'ΗΜΕΡΟΜΗΝΙΑ',
                      icon: Icons.calendar_today_outlined),
                  _sectionCard(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3949AB),
                                    Color(0xFF1E88E5)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_today,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ημερομηνία & Ώρα',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF1A1A2E)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3949AB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Αλλαγή',
                                  style: TextStyle(
                                      color: Color(0xFF3949AB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SectionHeader(
                      title: 'ΤΟΠΟΘΕΣΙΑ',
                      icon: Icons.place_outlined),
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location button
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            decoration: BoxDecoration(
                              gradient: _latitude != null
                                  ? LinearGradient(colors: [
                                      Colors.green.shade500,
                                      Colors.green.shade400,
                                    ])
                                  : const LinearGradient(colors: [
                                      Color(0xFF3949AB),
                                      Color(0xFF1E88E5),
                                    ]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (_latitude != null
                                          ? Colors.green
                                          : const Color(0xFF3949AB))
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
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
                                      : Icons.my_location,
                                      color: Colors.white),
                              label: Text(
                                _loadingLocation
                                    ? 'Ανάκτηση τοποθεσίας...'
                                    : _latitude != null
                                        ? 'Τοποθεσία ανακτήθηκε'
                                        : 'Ανάκτηση τοποθεσίας',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed:
                                  _loadingLocation ? null : _getLocation,
                            ),
                          ),
                        ),
                        if (_latitude != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.gps_fixed,
                                    size: 14,
                                    color: Colors.green.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  'Lat: ${_latitude!.toStringAsFixed(4)},  Lng: ${_longitude!.toStringAsFixed(4)}',
                                  style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _locationNameController,
                            decoration: _inputDecoration(
                                'Ονομασία τοποθεσίας (προαιρετική)',
                                Icons.place),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3949AB).withOpacity(0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(isEdit ? Icons.check : Icons.save,
                          color: Colors.white),
                      label: Text(
                        isEdit ? 'Ενημέρωση' : 'Αποθήκευση',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _save,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}