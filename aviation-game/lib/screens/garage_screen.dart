import 'package:flutter/material.dart';

import '../services/game_service.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String _selectedColor = 'blue';
  bool _loading = true;

  static const List<_PlaneColorOption> _options = <_PlaneColorOption>[
    _PlaneColorOption(
      id: 'blue',
      title: 'Blue',
      framePath: 'assets/images/tappy-plane/PNG/Planes/planeBlue1.png',
      accent: Color(0xFF42A5F5),
    ),
    _PlaneColorOption(
      id: 'green',
      title: 'Green',
      framePath: 'assets/images/tappy-plane/PNG/Planes/planeGreen1.png',
      accent: Color(0xFF66BB6A),
    ),
    _PlaneColorOption(
      id: 'red',
      title: 'Red',
      framePath: 'assets/images/tappy-plane/PNG/Planes/planeRed1.png',
      accent: Color(0xFFEF5350),
    ),
    _PlaneColorOption(
      id: 'yellow',
      title: 'Yellow',
      framePath: 'assets/images/tappy-plane/PNG/Planes/planeYellow1.png',
      accent: Color(0xFFFFCA28),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final color = await GameService.getPlaneColor();
    if (!mounted) return;
    setState(() {
      _selectedColor = color;
      _loading = false;
    });
  }

  Future<void> _selectColor(String colorId) async {
    setState(() => _selectedColor = colorId);
    await GameService.savePlaneColor(colorId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plane color updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: _options
                  .map(
                    (option) => _buildColorCard(
                      option: option,
                      selected: option.id == _selectedColor,
                      onTap: () => _selectColor(option.id),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildColorCard({
    required _PlaneColorOption option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: selected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? option.accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(
                  option.framePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                option.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: option.accent,
                  border: Border.all(
                    color: selected ? Colors.black87 : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaneColorOption {
  const _PlaneColorOption({
    required this.id,
    required this.title,
    required this.framePath,
    required this.accent,
  });

  final String id;
  final String title;
  final String framePath;
  final Color accent;
}
