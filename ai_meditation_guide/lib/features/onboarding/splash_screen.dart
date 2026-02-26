import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Сплэш-экран — быстрый переход на онбординг.
/// Основная анимация происходит уже на первой странице онбординга.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Минимальная задержка для инициализации
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.goNamed('onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8EEFF),
              Color(0xFFD4E4F7),
              Color(0xFFE2F0E8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
