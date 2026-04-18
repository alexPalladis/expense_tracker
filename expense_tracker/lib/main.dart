import 'package:expense_tracker/db/database_config.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/analysis_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3949AB)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _screens = [
    HomeScreen(
      onViewAll: () => setState(() => _currentIndex = 1),
      onAnalysis: () => setState(() => _currentIndex = 3),
      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
    ),
    const ExpensesScreen(),
    const CategoriesScreen(),
    const AnalysisScreen(),
  ];

  void _openAddExpense() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
  key: _scaffoldKey, 
  body: _screens[_currentIndex],
  drawer: _buildDrawer(),
  bottomNavigationBar: _buildBottomNav(),
);
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 220,
      child: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.person,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                const Text('Expense Tracker',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Text('Προσωπική Διαχείριση Εξόδων',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'Αρχική',
            active: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.add_circle_outline,
            label: 'Προσθήκη Εξόδου',
            active: false,
            onTap: () {
              Navigator.pop(context);
              _openAddExpense();
            },
          ),
          _DrawerItem(
            icon: Icons.list_alt_outlined,
            label: 'Έξοδα',
            active: _currentIndex == 1,
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.label_outline,
            label: 'Κατηγορίες',
            active: _currentIndex == 2,
            onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.bar_chart_outlined,
            label: 'Ανάλυση',
            active: _currentIndex == 3,
            onTap: () {
              setState(() => _currentIndex = 3);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.info_outline,
            label: 'Σχετικά με την εφαρμογή',
            active: false,
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Expense Tracker',
                applicationVersion: 'version 1.0.0',
                applicationLegalese: 'Αλέξανδρος Παλλάδης \nΚινητός και Διάχυτος Υπολογισμός',
              );
            },
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('v1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      selectedItemColor: const Color(0xFF3949AB),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 12,
      onTap: (i) => setState(() => _currentIndex = i),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Αρχική'),
        BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Έξοδα'),
        BottomNavigationBarItem(
            icon: Icon(Icons.label_outline),
            activeIcon: Icon(Icons.label),
            label: 'Κατηγορίες'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Ανάλυση'),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: active ? const Color(0xFF3949AB) : Colors.grey, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? const Color(0xFF3949AB) : Colors.black87)),
      tileColor: active ? const Color(0xFFEEF0FF) : null,
      shape: active
          ? const Border(
              left: BorderSide(color: Color(0xFF3949AB), width: 3))
          : null,
      onTap: onTap,
    );
  }
}