import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/logger_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LoggerService.init();
  LoggerService.info('Time Management started');
  runApp(const TimeManagementApp());
}

class TimeManagementApp extends StatelessWidget {
  const TimeManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
