import 'package:flutter/material.dart';
import 'screens/categories_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/analysis_screen.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainScreen(),
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

  final List<Widget> _screens = const [
    ExpensesScreen(),
    AddExpenseScreen(),
    CategoriesScreen(),
    AnalysisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'Expenses'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.label_outline), label: 'Categories'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Analysis'),
        ],
      ),
    );
  }
}