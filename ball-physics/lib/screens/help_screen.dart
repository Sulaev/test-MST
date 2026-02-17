import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Как играть')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpCard(
            title: 'Запуск',
            text: 'Свайпни от шарика, чтобы задать стартовый импульс.',
          ),
          SizedBox(height: 12),
          _HelpCard(
            title: 'Полет',
            text:
                'Во время полета можно слегка менять траекторию свайпом. Старайся делать короткие корректировки.',
          ),
          SizedBox(height: 12),
          _HelpCard(
            title: 'Цель',
            text:
                'Вылетай через разрывы в кольцах. Когда шар пересекает кольцо через gap, кольцо ломается и дает очки.',
          ),
          SizedBox(height: 12),
          _HelpCard(
            title: 'Поражение',
            text:
                'Если кольца сойдутся к центру и сожмут пространство, забег заканчивается поражением.',
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(text),
          ],
        ),
      ),
    );
  }
}
