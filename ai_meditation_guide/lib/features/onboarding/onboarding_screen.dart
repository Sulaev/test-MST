import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Данные для 4 страниц онбординга
  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      imagePath: 'assets/Image.png',
      titleItalic: 'Relax & Focus',
      titleBold: 'with AI\nMeditation',
      italicColor: Color(0xFF111111),
    ),
    _OnboardingData(
      imagePath: 'assets/Image (1).png',
      titleItalic: 'AI Creates',
      titleBold: 'Sessions for\nYour Mood',
      italicColor: Color(0xFF111111),
    ),
    _OnboardingData(
      imagePath: 'assets/image (2).png',
      titleItalic: 'Listen & Follow',
      titleBold: 'AI Guidance',
      italicColor: Color(0xFF111111),
    ),
    _OnboardingData(
      imagePath: 'assets/image (3).png',
      titleItalic: 'Track Your',
      titleBold: 'Mindfulness &\nProgress',
      italicColor: Color(0xFF111111),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      context.goNamed('home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

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
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index]);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Page indicator в белом контейнере
              _PageIndicator(
                currentPage: _currentPage,
                totalPages: _pages.length,
              ),
              const SizedBox(height: 24),
              // Кнопка
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: _OnboardingButton(
                  text: isLastPage ? 'START NOW' : 'NEXT',
                  onPressed: _goNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.imagePath,
    required this.titleItalic,
    required this.titleBold,
    required this.italicColor,
  });

  final String imagePath;
  final String titleItalic;
  final String titleBold;
  final Color italicColor;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.6;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          SizedBox(
            width: imageSize,
            height: imageSize,
            child: Image.asset(
              data.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.withOpacity(0.2),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              Text(
                data.titleItalic,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: data.italicColor,
                  letterSpacing: -1.5,
                  height: 52 / 48,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                data.titleBold,
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111111),
                  letterSpacing: -1.5,
                  height: 52 / 48,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// Page indicator: белый контейнер с серыми/чёрными точками
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          totalPages,
          (index) {
            final isActive = currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: index < totalPages - 1 ? 8 : 0),
              width: isActive ? 28 : 6,
              height: 6,
              decoration: BoxDecoration(
                // Активная — чёрная, неактивные — светло-серые #F6F7FA
                color: isActive
                    ? const Color(0xFF111111)
                    : const Color(0xFFF6F7FA),
                borderRadius: BorderRadius.circular(1000),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Кнопка: чёрный фон, текст слева от центра, серый круг со стрелкой справа
class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: Row(
          children: [
            // Пустое место для баланса (размер круга)
            const SizedBox(width: 56),
            // Текст по центру
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ),
            // Серый круг со стрелкой (56x56, цвет #F6F7FA с 8% opacity)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                // #F6F7FA с 8% прозрачности
                color: const Color(0xFFF6F7FA).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
