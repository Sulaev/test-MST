import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Управление',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('• Тап по экрану - поднять самолет'),
            Text('• Отпустить - опустить самолет'),
            Text('• Избегайте препятствий'),
            Text('• Собирайте бонусы'),
            SizedBox(height: 24),
            Text(
              'Цель',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Пролетите как можно дальше и наберите максимальное количество очков!'),
          ],
        ),
      ),
    );
  }
}
