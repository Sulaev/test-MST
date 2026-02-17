import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../services/logger_service.dart';

class _Coin {
  _Coin({required this.x, required this.y});

  double x;
  double y;
  bool collected = false;
}

class _AmbientPlane {
  _AmbientPlane({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.spritePath,
  });

  double x;
  double y;
  double size;
  double speed;
  String spritePath;
}

class _AmbientBalloon {
  _AmbientBalloon({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });

  double x;
  double y;
  double size;
  double speed;
  double phase;
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double _planeSize = 54;

  static const String _cloudPath = 'assets/images/tappy-plane/PNG/puffLarge.png';
  static const String _groundPath = 'assets/images/tappy-plane/PNG/groundGrass.png';
  static const String _coinPath = 'assets/images/tappy-plane/PNG/starGold.png';
  static const String _getReadyPath = 'assets/images/tappy-plane/PNG/UI/textGetReady.png';
  static const String _gameOverPath = 'assets/images/tappy-plane/PNG/UI/textGameOver.png';
  static const String _buttonLargePath = 'assets/images/tappy-plane/PNG/UI/buttonLarge.png';
  static const List<String> _defaultPlaneFrames = <String>[
    'assets/images/tappy-plane/PNG/Planes/planeBlue1.png',
    'assets/images/tappy-plane/PNG/Planes/planeBlue2.png',
    'assets/images/tappy-plane/PNG/Planes/planeBlue3.png',
  ];
  static const List<String> _trafficPlaneSprites = <String>[
    'assets/images/tappy-plane/PNG/Planes/planeGreen1.png',
    'assets/images/tappy-plane/PNG/Planes/planeRed2.png',
    'assets/images/tappy-plane/PNG/Planes/planeYellow3.png',
  ];

  final math.Random _random = math.Random();
  final List<_Coin> _coinsList = <_Coin>[];
  final List<_AmbientPlane> _topTraffic = <_AmbientPlane>[];
  final List<_AmbientPlane> _midTraffic = <_AmbientPlane>[];
  final List<_AmbientBalloon> _bottomBalloons = <_AmbientBalloon>[];
  List<String> _playerPlaneFrames = _defaultPlaneFrames;

  Timer? _loop;
  DateTime? _lastTick;

  bool _initialized = false;
  bool _paused = false;
  bool _gameOver = false;
  bool _hasStarted = false;

  double _w = 0;
  double _h = 0;

  double _planeX = 0;
  double _planeY = 0;
  double _velocityY = 0;

  int _score = 0;
  int _coins = 0;
  double _distance = 0;

  double _speed = 170;
  double _coinCooldown = 1.9;
  double _topTrafficCooldown = 0.8;
  double _midTrafficCooldown = 4.2;
  double _bottomBalloonCooldown = 1.1;
  double _groundOffset = 0;
  double _cloudOffsetFar = 0;
  double _cloudOffsetNear = 0;

  int _frame = 0;

  double get _groundHeight => 72;
  double get _planeRadius => _planeSize * 0.36;

  @override
  void initState() {
    super.initState();
    LoggerService.info('Flight run opened');
    _loadSelectedPlaneColor();
  }

  Future<void> _loadSelectedPlaneColor() async {
    final selectedColor = await GameService.getPlaneColor();
    final frames = _framesForColor(selectedColor);
    if (!mounted) return;
    setState(() {
      _playerPlaneFrames = frames;
    });
  }

  List<String> _framesForColor(String color) {
    switch (color) {
      case 'green':
        return const <String>[
          'assets/images/tappy-plane/PNG/Planes/planeGreen1.png',
          'assets/images/tappy-plane/PNG/Planes/planeGreen2.png',
          'assets/images/tappy-plane/PNG/Planes/planeGreen3.png',
        ];
      case 'red':
        return const <String>[
          'assets/images/tappy-plane/PNG/Planes/planeRed1.png',
          'assets/images/tappy-plane/PNG/Planes/planeRed2.png',
          'assets/images/tappy-plane/PNG/Planes/planeRed3.png',
        ];
      case 'yellow':
        return const <String>[
          'assets/images/tappy-plane/PNG/Planes/planeYellow1.png',
          'assets/images/tappy-plane/PNG/Planes/planeYellow2.png',
          'assets/images/tappy-plane/PNG/Planes/planeYellow3.png',
        ];
      case 'blue':
      default:
        return _defaultPlaneFrames;
    }
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }

  void _initialize(Size size) {
    if (_initialized || size.width <= 0 || size.height <= 0) return;

    _w = size.width;
    _h = size.height;
    _resetState();
    _startLoop();

    _initialized = true;
  }

  void _resetState() {
    _coinsList.clear();
    _topTraffic.clear();
    _midTraffic.clear();
    _bottomBalloons.clear();

    _planeX = _w * 0.28;
    _planeY = _h * 0.45;
    _velocityY = 0;

    _score = 0;
    _coins = 0;
    _distance = 0;

    _speed = 170;
    _coinCooldown = 1.9;
    _topTrafficCooldown = 0.8;
    _midTrafficCooldown = 4.2;
    _bottomBalloonCooldown = 1.1;
    _groundOffset = 0;
    _cloudOffsetFar = 0;
    _cloudOffsetNear = 0;

    _paused = false;
    _gameOver = false;
    _hasStarted = false;
    _frame = 0;
    _lastTick = null;
  }

  void _startLoop() {
    _loop?.cancel();
    _loop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || _paused || _gameOver) return;

      final now = DateTime.now();
      final dt = _lastTick == null
          ? 0.016
          : (now.difference(_lastTick!).inMilliseconds / 1000).clamp(0.0, 0.05).toDouble();
      _lastTick = now;

      _update(dt);
    });
  }

  void _update(double dt) {
    if (dt <= 0) return;

    setState(() {
      if (!_hasStarted) {
        // Keep a subtle movement on Get Ready screen, slower than normal gameplay.
        _groundOffset = (_groundOffset + (170 * dt * 0.42)) % _w;
        _cloudOffsetFar = (_cloudOffsetFar + 6 * dt) % (_w + 140);
        _cloudOffsetNear = (_cloudOffsetNear + 9 * dt) % (_w + 160);
        return;
      }

      _distance += dt * _speed * 0.08;
      _speed = (170 + _distance * 0.65).clamp(170.0, 330.0).toDouble();
      _groundOffset = (_groundOffset + (_speed * dt * 0.62)) % _w;
      _cloudOffsetFar = (_cloudOffsetFar + (_speed * dt * 0.08)) % (_w + 140);
      _cloudOffsetNear = (_cloudOffsetNear + (_speed * dt * 0.12)) % (_w + 160);

      _velocityY += 980 * dt * 0.35;
      _planeY += _velocityY * dt;

      _coinCooldown -= dt;
      _topTrafficCooldown -= dt;
      _midTrafficCooldown -= dt;
      _bottomBalloonCooldown -= dt;

      if (_coinCooldown <= 0) {
        _spawnCoinMaybe();
        _coinCooldown = _random.nextDouble() * 1.9 + 1.2;
      }
      if (_topTrafficCooldown <= 0) {
        _spawnTopTrafficPlane();
        _topTrafficCooldown = _random.nextDouble() * 1.2 + 0.9;
      }
      if (_midTrafficCooldown <= 0) {
        _spawnMidTrafficPlane();
        // Much rarer than top traffic by design.
        _midTrafficCooldown = _random.nextDouble() * 4.0 + 3.8;
      }
      if (_bottomBalloonCooldown <= 0) {
        _spawnBottomBalloon();
        _bottomBalloonCooldown = _random.nextDouble() * 1.5 + 1.1;
      }

      for (final c in _coinsList) {
        c.x -= _speed * dt;
      }
      for (final p in _topTraffic) {
        p.x -= p.speed * dt;
      }
      for (final p in _midTraffic) {
        p.x -= p.speed * dt;
      }
      for (final b in _bottomBalloons) {
        b.x -= b.speed * dt;
      }

      final planeCenterX = _planeX + _planeSize / 2;
      final planeCenterY = _planeY + _planeSize / 2;

      for (final c in _coinsList) {
        if (c.collected) continue;
        final dx = planeCenterX - c.x;
        final dy = planeCenterY - c.y;
        final hit = (dx * dx + dy * dy) <= math.pow(_planeRadius + 14, 2);
        if (hit) {
          c.collected = true;
          _coins += 1;
          _score += 15;
        }
      }

      _coinsList.removeWhere((c) => c.x < -30 || c.collected);
      _topTraffic.removeWhere((p) => p.x + p.size < -24);
      _midTraffic.removeWhere((p) => p.x + p.size < -24);
      _bottomBalloons.removeWhere((b) => b.x + b.size < -24);
      _score = _distance.round() + (_coins * 15);

      _frame = (_frame + 1) % (_playerPlaneFrames.length * 7);

      if (_checkCollision()) {
        _finishRun();
      }
    });
  }

  bool _checkCollision() {
    final top = _planeY + 8;
    final bottom = _planeY + _planeSize - 8;

    if (top <= 0 || bottom >= _h - _groundHeight) return true;

    final planeCenterX = _planeX + _planeSize / 2;
    final planeCenterY = _planeY + _planeSize / 2;

    for (final t in _topTraffic) {
      final trafficCenterX = t.x + t.size / 2;
      final trafficCenterY = t.y + t.size / 2;
      final dx = planeCenterX - trafficCenterX;
      final dy = planeCenterY - trafficCenterY;
      final minDist = _planeRadius + (t.size * 0.34);
      if ((dx * dx + dy * dy) <= (minDist * minDist)) return true;
    }
    for (final t in _midTraffic) {
      final trafficCenterX = t.x + t.size / 2;
      final trafficCenterY = t.y + t.size / 2;
      final dx = planeCenterX - trafficCenterX;
      final dy = planeCenterY - trafficCenterY;
      final minDist = _planeRadius + (t.size * 0.35);
      if ((dx * dx + dy * dy) <= (minDist * minDist)) return true;
    }

    for (final b in _bottomBalloons) {
      final y = b.y + math.sin((_distance * 0.15) + b.phase) * 4;
      final balloonCenterX = b.x + b.size * 0.36;
      final balloonCenterY = y + b.size * 0.36;
      final dx = planeCenterX - balloonCenterX;
      final dy = planeCenterY - balloonCenterY;
      final minDist = _planeRadius + (b.size * 0.28);
      if ((dx * dx + dy * dy) <= (minDist * minDist)) return true;
    }

    return false;
  }

  void _spawnCoinMaybe() {
    if (_random.nextDouble() > 0.86) return;

    for (var i = 0; i < 10; i++) {
      // Spawn coins off-screen on the right so they fly into view naturally.
      final x = _w + 24 + _random.nextDouble() * (_w * 0.55);
      final y = 76 + _random.nextDouble() * (_h - _groundHeight - 170);
      if (_isCoinSpotFree(x, y)) {
        _coinsList.add(_Coin(x: x, y: y));
        return;
      }
    }
  }

  bool _isCoinSpotFree(double x, double y) {
    if (x < _planeX + 56) return false;
    if (y < 56 || y > _h - _groundHeight - 56) return false;

    for (final t in _topTraffic) {
      final dx = x - (t.x + t.size / 2);
      final dy = y - (t.y + t.size / 2);
      if ((dx * dx + dy * dy) < 38 * 38) return false;
    }
    for (final t in _midTraffic) {
      final dx = x - (t.x + t.size / 2);
      final dy = y - (t.y + t.size / 2);
      if ((dx * dx + dy * dy) < 38 * 38) return false;
    }
    for (final b in _bottomBalloons) {
      final by = b.y + math.sin((_distance * 0.15) + b.phase) * 4;
      final dx = x - (b.x + b.size / 2);
      final dy = y - (by + b.size / 2);
      if ((dx * dx + dy * dy) < 38 * 38) return false;
    }

    for (final c in _coinsList) {
      final dx = x - c.x;
      final dy = y - c.y;
      if ((dx * dx + dy * dy) < 34 * 34) return false;
    }

    return true;
  }

  void _spawnTopTrafficPlane() {
    final y = 42 + _random.nextDouble() * (_h * 0.22);
    final size = 30 + _random.nextDouble() * 14;
    _topTraffic.add(
      _AmbientPlane(
        x: _w + 18,
        y: y,
        size: size,
        speed: 72 + _random.nextDouble() * 38,
        spritePath: _trafficPlaneSprites[_random.nextInt(_trafficPlaneSprites.length)],
      ),
    );
  }

  void _spawnMidTrafficPlane() {
    final y = (_h * 0.35) + _random.nextDouble() * (_h * 0.25);
    final size = 34 + _random.nextDouble() * 16;
    _midTraffic.add(
      _AmbientPlane(
        x: _w + 22,
        y: y,
        size: size,
        speed: 86 + _random.nextDouble() * 36,
        spritePath: _trafficPlaneSprites[_random.nextInt(_trafficPlaneSprites.length)],
      ),
    );
  }

  void _spawnBottomBalloon() {
    final size = 30 + _random.nextDouble() * 16;
    final y = _h - _groundHeight - size - (10 + _random.nextDouble() * 36);
    _bottomBalloons.add(
      _AmbientBalloon(
        x: _w + 14,
        y: y,
        size: size,
        speed: 48 + _random.nextDouble() * 24,
        phase: _random.nextDouble() * math.pi * 2,
      ),
    );
  }

  void _flap() {
    if (_gameOver) return;
    if (_paused) {
      setState(() => _paused = false);
      return;
    }
    setState(() {
      _hasStarted = true;
      _velocityY = -250;
    });
  }

  void _togglePause() {
    if (_gameOver) return;
    setState(() => _paused = !_paused);
  }

  Future<void> _finishRun() async {
    _loop?.cancel();
    _gameOver = true;
    _paused = false;

    try {
      await GameService.saveScore(_score);
      LoggerService.info('Run finished. Score: $_score');
    } catch (e) {
      LoggerService.error('Error saving score', e);
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5FBFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1B6F9E), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(_gameOverPath, width: 210, filterQuality: FilterQuality.none),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dialogMetric(
                      label: 'Distance',
                      value: '${_distance.round()} m',
                      icon: Icons.route_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dialogMetric(
                      label: 'Coins',
                      value: '$_coins',
                      icon: Icons.stars_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Score: $_score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0C3E5A),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  _gameOverActionButton(
                    label: 'Play Again',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _resetState();
                        _startLoop();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _gameOverActionButton(
                    label: 'Exit',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Run'),
        actions: [
          IconButton(
            icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          if (!_initialized && size.width > 0 && size.height > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _initialize(size);
            });
          }

          if (!_initialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _flap,
            child: Stack(
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
                  top: 86,
                  width: 90,
                  opacity: 0.62,
                  offset: _cloudOffsetFar,
                  span: _w + 140,
                ),
                _buildCloudLayer(
                  top: 124,
                  width: 76,
                  opacity: 0.78,
                  offset: _cloudOffsetNear,
                  span: _w + 160,
                ),
                for (final p in _topTraffic)
                  Positioned(
                    left: p.x,
                    top: p.y,
                    child: SizedBox(
                      width: p.size,
                      height: p.size,
                      child: Transform.flip(
                        flipX: true,
                        child: Image.asset(
                          p.spritePath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                for (final p in _midTraffic)
                  Positioned(
                    left: p.x,
                    top: p.y,
                    child: SizedBox(
                      width: p.size,
                      height: p.size,
                      child: Transform.flip(
                        flipX: true,
                        child: Image.asset(
                          p.spritePath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                for (final b in _bottomBalloons)
                  Positioned(
                    left: b.x,
                    top: b.y + math.sin((_distance * 0.15) + b.phase) * 4,
                    child: _BalloonSprite(size: b.size),
                  ),
                Positioned(
                  left: -_groundOffset,
                  bottom: 0,
                  child: SizedBox(
                    width: _w,
                    height: _groundHeight,
                    child: Image.asset(
                      _groundPath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                Positioned(
                  left: -_groundOffset + _w,
                  bottom: 0,
                  child: SizedBox(
                    width: _w,
                    height: _groundHeight,
                    child: Image.asset(
                      _groundPath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                for (final c in _coinsList)
                  Positioned(
                    left: c.x - 16,
                    top: c.y - 16,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Image.asset(
                        _coinPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                Positioned(
                  left: _planeX,
                  top: _planeY,
                  child: Transform.rotate(
                    angle: (_velocityY / 450).clamp(-0.35, 0.6).toDouble(),
                    child: SizedBox(
                      width: _planeSize,
                      height: _planeSize,
                      child: Image.asset(
                        _playerPlaneFrames[_frame ~/ 7],
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  top: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: _chip(
                          'Distance',
                          '${_distance.round()} m',
                          icon: Icons.route_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _chip(
                          'Coins',
                          _coins.toString(),
                          icon: Icons.stars_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: _groundHeight + 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Tap to fly',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (!_hasStarted)
                  Container(
                    color: Colors.black12,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(_getReadyPath, width: 220, filterQuality: FilterQuality.none),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Tap to start',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_paused)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Text(
                        'PAUSED',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, String value, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xAA123C57),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1B6F9E)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4E6A7E))),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0C3E5A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameOverActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8A4B00),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudLayer({
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
                  left: _w * 0.15,
                  child: Image.asset(_cloudPath, width: width, filterQuality: FilterQuality.none),
                ),
                Positioned(
                  left: _w * 0.58,
                  child: Image.asset(_cloudPath, width: width * 0.92, filterQuality: FilterQuality.none),
                ),
                Positioned(
                  left: span + (_w * 0.15),
                  child: Image.asset(_cloudPath, width: width, filterQuality: FilterQuality.none),
                ),
                Positioned(
                  left: span + (_w * 0.58),
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

class _BalloonSprite extends StatelessWidget {
  const _BalloonSprite({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final basketColor = Colors.brown.shade700;
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF7A59),
              border: Border.all(color: const Color(0xFFD34E30), width: 1.4),
            ),
          ),
          Positioned(
            top: size * 0.58,
            left: size * 0.29,
            child: Container(width: 1.6, height: size * 0.26, color: basketColor),
          ),
          Positioned(
            top: size * 0.58,
            right: size * 0.29,
            child: Container(width: 1.6, height: size * 0.26, color: basketColor),
          ),
          Positioned(
            top: size * 0.82,
            child: Container(
              width: size * 0.22,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: basketColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
