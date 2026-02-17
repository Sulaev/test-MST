import 'package:flutter/material.dart';
import '../services/logger_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _gravity = 9.8;
  double _ballSpeed = 1.0;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getSettings();
    setState(() {
      _gravity = settings['gravity'] ?? 9.8;
      _ballSpeed = settings['ballSpeed'] ?? 1.0;
      _soundEnabled = settings['soundEnabled'] ?? true;
    });
  }

  Future<void> _saveSettings() async {
    await SettingsService.saveSettings({
      'gravity': _gravity,
      'ballSpeed': _ballSpeed,
      'soundEnabled': _soundEnabled,
    });
    LoggerService.info('Settings saved');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Гравитация: ${_gravity.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 16),
          ),
          Slider(
            value: _gravity,
            min: 5.0,
            max: 15.0,
            divisions: 20,
            label: _gravity.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _gravity = value;
              });
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Скорость мяча: ${_ballSpeed.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 16),
          ),
          Slider(
            value: _ballSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: _ballSpeed.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _ballSpeed = value;
              });
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Звук'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
