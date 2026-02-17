import 'dart:async';

import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'garage_screen.dart';
import 'game_screen.dart';
import 'help_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _cloudPath = 'assets/images/tappy-plane/PNG/puffLarge.png';
  static const String _groundPath = 'assets/images/tappy-plane/PNG/groundGrass.png';
  static const String _getReadyPath = 'assets/images/tappy-plane/PNG/UI/textGetReady.png';
  static const String _buttonLargePath = 'assets/images/tappy-plane/PNG/UI/buttonLarge.png';
  static const List<String> _trafficPlaneSprites = <String>[
    'assets/images/tappy-plane/PNG/Planes/planeBlue1.png',
    'assets/images/tappy-plane/PNG/Planes/planeGreen2.png',
    'assets/images/tappy-plane/PNG/Planes/planeRed1.png',
    'assets/images/tappy-plane/PNG/Planes/planeYellow3.png',
  ];

  Timer? _timer;
  double _groundOffset = 0;
  double _cloudOffsetFar = 0;
  double _cloudOffsetNear = 0;
  DateTime? _lastTick;
  final List<_MenuPlane> _menuPlanes = <_MenuPlane>[];
  final List<_TrafficWave> _waves = const <_TrafficWave>[
    _TrafficWave(leftToRightCount: 1, rightToLeftCount: 1),
    _TrafficWave(leftToRightCount: 2, rightToLeftCount: 2),
    _TrafficWave(leftToRightCount: 1, rightToLeftCount: 2),
    _TrafficWave(leftToRightCount: 2, rightToLeftCount: 1),
    _TrafficWave(leftToRightCount: 1, rightToLeftCount: 1),
    _TrafficWave(leftToRightCount: 2, rightToLeftCount: 1),
    _TrafficWave(leftToRightCount: 1, rightToLeftCount: 2),
  ];
  int _waveIndex = 0;
  double _waveCooldown = 0.35;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final dt = _lastTick == null
          ? 0.016
          : (now.difference(_lastTick!).inMilliseconds / 1000).clamp(0.0, 0.05).toDouble();
      _lastTick = now;

      setState(() {
        _groundOffset += 48 * dt;
        _cloudOffsetFar += 8 * dt;
        _cloudOffsetNear += 12 * dt;
        _updateMenuPlanes(dt);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateMenuPlanes(double dt) {
    _waveCooldown -= dt;
    if (_waveCooldown <= 0) {
      _spawnWave(_waves[_waveIndex % _waves.length]);
      _waveIndex++;
      _waveCooldown = 1.45 + (_waveIndex % 3) * 0.35;
    }

    for (final plane in _menuPlanes) {
      if (plane.leftToRight) {
        plane.x += plane.speed * dt;
      } else {
        plane.x -= plane.speed * dt;
      }
    }

    _menuPlanes.removeWhere((plane) {
      if (plane.leftToRight) return plane.x > _screenWidth + plane.size + 56;
      return plane.x < -plane.size - 56;
    });
  }

  void _spawnWave(_TrafficWave wave) {
    for (var i = 0; i < wave.leftToRightCount; i++) {
      final size = 38 + ((_waveIndex + i) % 3) * 4;
      _menuPlanes.add(
        _MenuPlane(
          x: -size - 54 - i * 74,
          y: _pickPlaneY(),
          size: size.toDouble(),
          speed: (48 + ((_waveIndex + i) % 4) * 5).toDouble(),
          leftToRight: true,
          spritePath: _trafficPlaneSprites[(_waveIndex + i) % _trafficPlaneSprites.length],
        ),
      );
    }

    for (var i = 0; i < wave.rightToLeftCount; i++) {
      final size = 38 + ((_waveIndex + i + 1) % 3) * 4;
      _menuPlanes.add(
        _MenuPlane(
          x: _screenWidth + 54 + i * 74,
          y: _pickPlaneY(),
          size: size.toDouble(),
          speed: (50 + ((_waveIndex + i) % 4) * 5).toDouble(),
          leftToRight: false,
          spritePath: _trafficPlaneSprites[(_waveIndex + i + 2) % _trafficPlaneSprites.length],
        ),
      );
    }
  }

  double _pickPlaneY() {
    final h = MediaQuery.of(context).size.height;
    const minY = 92.0;
    final maxY = (h - 150).clamp(180.0, h);
    return minY + ((DateTime.now().microsecondsSinceEpoch % 1000) / 1000) * (maxY - minY);
  }

  double get _screenWidth => MediaQuery.of(context).size.width;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final groundOffset = _groundOffset % size.width;
    final cloudFarOffset = _cloudOffsetFar % (size.width + 140);
    final cloudNearOffset = _cloudOffsetNear % (size.width + 160);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFF80D8FF),
                    Color(0xFFB3E5FC),
                    Color(0xFFD6F4FF),
                  ],
                ),
              ),
            ),
          ),
          _buildCloudLayer(
            screenWidth: size.width,
            top: 86,
            width: 90,
            opacity: 0.62,
            offset: cloudFarOffset,
            span: size.width + 140,
          ),
          _buildCloudLayer(
            screenWidth: size.width,
            top: 124,
            width: 76,
            opacity: 0.78,
            offset: cloudNearOffset,
            span: size.width + 160,
          ),
          for (final plane in _menuPlanes)
            Positioned(
              left: plane.x,
              top: plane.y,
              child: SizedBox(
                width: plane.size,
                height: plane.size,
                child: Transform.flip(
                  flipX: !plane.leftToRight,
                  child: Image.asset(
                    plane.spritePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          Positioned(
            left: -groundOffset,
            right: null,
            bottom: 0,
            child: SizedBox(
              width: size.width,
              height: 30,
              child: Image.asset(_groundPath, fit: BoxFit.cover, filterQuality: FilterQuality.none),
            ),
          ),
          Positioned(
            left: -groundOffset + size.width,
            right: null,
            bottom: 0,
            child: SizedBox(
              width: size.width,
              height: 30,
              child: Image.asset(_groundPath, fit: BoxFit.cover, filterQuality: FilterQuality.none),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 26),
                    const Text(
                      'Flight Run',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D3F5B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(_getReadyPath, width: 220, filterQuality: FilterQuality.none),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Choose an action',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    _buildMenuButton(
                      context,
                      'Start Flight',
                      Icons.play_arrow_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      'Leaderboard',
                      Icons.emoji_events_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      'Garage',
                      Icons.precision_manufacturing_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GarageScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      'How To Play',
                      Icons.help_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      'About',
                      Icons.info_outline_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  _buttonLargePath,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFF8A4B00)),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8A4B00),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudLayer({
    required double screenWidth,
    required double top,
    required double width,
    required double opacity,
    required double offset,
    required double span,
  }) {
    return Positioned(
      top: top,
      left: -offset,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: span * 2,
            height: width * 0.62,
            child: Stack(
              children: [
                Positioned(
                  left: screenWidth * 0.15,
                  child: Image.asset(_cloudPath, width: width, filterQuality: FilterQuality.none),
                ),
                Positioned(
                  left: screenWidth * 0.58,
                  child: Image.asset(_cloudPath, width: width * 0.92, filterQuality: FilterQuality.none),
                ),
                Positioned(
                  left: span + (screenWidth * 0.15),
                  child: Image.asset(_cloudPath, width: width, filterQuality: FilterQuality.none),
                ),
                Positioned(
                  left: span + (screenWidth * 0.58),
                  child: Image.asset(_cloudPath, width: width * 0.92, filterQuality: FilterQuality.none),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuPlane {
  _MenuPlane({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.leftToRight,
    required this.spritePath,
  });

  double x;
  double y;
  double size;
  double speed;
  bool leftToRight;
  String spritePath;
}

class _TrafficWave {
  const _TrafficWave({
    required this.leftToRightCount,
    required this.rightToLeftCount,
  });

  final int leftToRightCount;
  final int rightToLeftCount;
}
