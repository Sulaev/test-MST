import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'encyclopedia_screen.dart';
import 'favorites_screen.dart';
import 'facts_screen.dart';
import 'quiz_screen.dart';
import '../services/animals_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _warmupStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmupStarted) return;
    _warmupStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnimalsService.ensureImagesPrecached(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = <_HomeMenuItem>[
      const _HomeMenuItem(
        title: 'Animal World',
        subtitle: 'Explore photos and fun facts.',
        icon: Icons.auto_stories_rounded,
        color: Color(0xFF5B8DEF),
        screen: EncyclopediaScreen(),
      ),
      const _HomeMenuItem(
        title: 'Quiz Time',
        subtitle: 'Play and test what you learned.',
        icon: Icons.quiz_rounded,
        color: Color(0xFFF59E0B),
        screen: QuizScreen(),
      ),
      const _HomeMenuItem(
        title: 'Favorites',
        subtitle: 'Keep your favorite animals here.',
        icon: Icons.favorite_rounded,
        color: Color(0xFFEF476F),
        screen: FavoritesScreen(),
      ),
      const _HomeMenuItem(
        title: 'Daily Facts',
        subtitle: 'Short quick facts for everyday learning.',
        icon: Icons.lightbulb_outline_rounded,
        color: Color(0xFF6C63FF),
        screen: FactsScreen(),
      ),
      const _HomeMenuItem(
        title: 'About',
        subtitle: 'Info about the app and its sections.',
        icon: Icons.info_outline_rounded,
        color: Color(0xFF2CC8A0),
        screen: AboutScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Animals Encyclopedia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2CC8A0), Color(0xFF6EE7C8)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Explorer!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Discover animals, hear their sounds, and learn with fun.',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 260 + (i * 120)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 16),
                    child: child,
                  ),
                );
              },
              child: _HomeMenuCard(item: items[i]),
            ),
        ],
      ),
    );
  }
}

class _HomeMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _HomeMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _HomeMenuCard extends StatelessWidget {
  const _HomeMenuCard({required this.item});

  final _HomeMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item.screen),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(item.subtitle, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}
