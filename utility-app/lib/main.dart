import 'package:flutter/material.dart';

import 'screens/calculator_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/tasks_screen.dart';
import 'services/logger_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LoggerService.init();
  LoggerService.info('Utility App started');
  runApp(const UtilityApp());
}

class UtilityApp extends StatelessWidget {
  const UtilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Utility App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const UtilityShell(),
    );
  }
}

class UtilityShell extends StatefulWidget {
  const UtilityShell({super.key});

  @override
  State<UtilityShell> createState() => _UtilityShellState();
}

class _UtilityShellState extends State<UtilityShell> {
  int _index = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TasksScreen(),
    FocusScreen(),
    NotesScreen(),
    CalculatorScreen(),
  ];

  final List<String> _titles = const [
    'Workspace',
    'Tasks',
    'Focus',
    'Notes',
    'Calculator',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          LoggerService.debug('Section changed to: ${_titles[value]}');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Focus'),
          NavigationDestination(icon: Icon(Icons.note_alt_outlined), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), label: 'Calc'),
        ],
      ),
    );
  }
}
