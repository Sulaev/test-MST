import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/logger_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep enough decoded images in memory to avoid re-decoding when user
  // repeatedly enters/exits the animal list screens.
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 300;
  imageCache.maximumSizeBytes = 220 << 20;
  LoggerService.init();
  LoggerService.info('Animals Encyclopedia started');
  runApp(const AnimalsApp());
}

class AnimalsApp extends StatelessWidget {
  const AnimalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animals Encyclopedia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2CC8A0)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF9F0),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          elevation: 1.2,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
