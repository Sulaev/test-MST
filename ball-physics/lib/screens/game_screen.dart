import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/ball.dart';
import '../models/ring.dart';
import '../services/logger_service.dart';
import '../services/settings_service.dart';
import '../services/stats_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int _targetRingCount = 4;
  static const double _ringSpacing = 52.0;
  static const double _ringThickness = 18.0;

  final List<Ring> _rings = [];
  final math.Random _random = math.Random();
  late Ball _ball;
  Timer? _physicsTimer;

  double _screenWidth = 0;
  double _screenHeight = 0;
  double _speedMultiplier = 1;
  bool _isInitialized = false;
  bool _isLaunched = false;
  bool _isPaused = false;
  bool _isFinished = false;
  bool _isVictory = false;
  bool _scoreSaved = false;
  int _score = 0;
  int _broken = 0;
  int _nextRingId = 0;
  Offset? _dragStart;
  Offset? _dragCurrent;
  DateTime _lastAirControlAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _ball = Ball(x: 200, y: 300, gravity: 0);
    LoggerService.info('Ball escape mode opened');
  }

  Future<void> _initializeGame() async {
    if (_isInitialized || _screenWidth <= 0 || _screenHeight <= 0) {
      return;
    }
    final settings = await SettingsService.getSettings();
    _speedMultiplier = ((settings['ballSpeed'] as num?)?.toDouble() ?? 1.0)
        .clamp(0.6, 1.8);
    _resetRun();
    _isInitialized = true;
    _startGameLoop();
  }

  void _resetRun() {
    _score = 0;
    _broken = 0;
    _isPaused = false;
    _isFinished = false;
    _isVictory = false;
    _isLaunched = false;
    _scoreSaved = false;
    _nextRingId = 0;
    _dragStart = null;
    _dragCurrent = null;

    final centerX = _screenWidth / 2;
    final centerY = _screenHeight / 2;
    _ball = Ball(
      x: centerX,
      y: centerY,
      gravity: 0,
      radius: 14,
    );

    _rings
      ..clear()
      ..addAll(_buildConcentricRings(centerX, centerY));
  }

  List<Ring> _buildConcentricRings(double centerX, double centerY) {
    final maxRadius = _maxVisibleRingRadius();
    final rings = <Ring>[];

    for (var i = 0; i < _targetRingCount; i++) {
      final radius = maxRadius - i * _ringSpacing;
      rings.add(_createRingWithRadius(radius, level: i));
    }
    return rings;
  }

  Ring _createRingWithRadius(double radius, {required int level}) {
    final maxRadius = _maxVisibleRingRadius();
    final radiusRatio = (radius / maxRadius).clamp(0.45, 2.8);
    final baseAngularSpeed = 0.006 + (0.02 * radiusRatio);
    return Ring(
      id: _nextRingId++,
      x: _screenWidth / 2,
      y: _screenHeight / 2,
      radius: radius,
      thickness: _ringThickness,
      gapStartAngle: _random.nextDouble() * math.pi * 2,
      gapSize: math.pi / 3 + _random.nextDouble() * (math.pi / 12),
      angularVelocity: (baseAngularSpeed + _random.nextDouble() * 0.008) *
          (_random.nextBool() ? 1 : -1),
      shrinkSpeed: 0.078 + level * 0.022,
      initialRadius: radius,
    );
  }

  double _maxVisibleRingRadius() {
    final shortestSide = math.min(_screenWidth, _screenHeight);
    return (shortestSide * 0.47).clamp(150.0, 275.0);
  }

  void _spawnReplacementRingsIfNeeded() {
    final activeCount = _rings.where((ring) => !ring.isBroken).length;
    if (activeCount >= _targetRingCount) {
      return;
    }

    final missingCount = _targetRingCount - activeCount;
    final currentOuterRadius = _rings.isEmpty
        ? _maxVisibleRingRadius()
        : _rings
                .where((ring) => !ring.isBroken)
                .map((ring) => ring.radius)
                .fold<double>(0, math.max);
    for (var i = 0; i < missingCount; i++) {
      final level = (_score ~/ 120).clamp(0, 5);
      final spawnRadius = currentOuterRadius + _ringSpacing * (1.2 + i * 0.3);
      final newRing = _createRingWithRadius(spawnRadius, level: level);
      _rings.add(newRing);
    }
  }

  void _startGameLoop() {
    _physicsTimer?.cancel();
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_isPaused && !_isFinished && mounted) {
        _updateWorld();
      }
    });
  }

  void _updateWorld() {
    setState(() {
      final previousDistances = <int, double>{};
      final previousRadii = <int, double>{};
      for (final ring in _rings.where((ring) => !ring.isBroken)) {
        previousDistances[ring.id] = _distanceToRingCenter(ring);
        previousRadii[ring.id] = ring.radius;
      }

      for (final ring in _rings) {
        final radiusRatio = (ring.radius / _maxVisibleRingRadius()).clamp(0.28, 3.0);
        final baseFactor = math.pow(radiusRatio, 1.45).toDouble();
        final middleBand = 1 - (((radiusRatio - 0.95).abs()) / 0.52).clamp(0.0, 1.0);
        final middleBoost = 1 + middleBand * 2.65;
        final shrinkFactor = (baseFactor * middleBoost).clamp(0.65, 9.0);
        ring.update(shrink: _isLaunched, shrinkFactor: shrinkFactor);
      }

      _enforceRingSpacing();

      if (_isLaunched) {
        _ball.update(
          _screenWidth,
          _screenHeight,
          bounceBottom: true,
          bounceDamping: 0.9,
          maxVelocityX: 13 * _speedMultiplier,
          maxVelocityY: 13 * _speedMultiplier,
        );
      }

      for (final ring in _rings.where((ring) => !ring.isBroken)) {
        _applyPhysicalCollision(
          ring,
          previousDistances[ring.id] ?? 0,
          previousRadii[ring.id] ?? ring.radius,
        );
      }

      _rings.removeWhere((ring) => ring.isGone);
      _spawnReplacementRingsIfNeeded();
      _checkFinishConditions();
    });
  }

  void _enforceRingSpacing() {
    final activeRings = _rings.where((ring) => !ring.isBroken).toList()
      ..sort((a, b) => b.radius.compareTo(a.radius));
    if (activeRings.length < 2) {
      return;
    }

    final minSeparation = (_ringThickness * 1.55 + _ball.radius * 1.25).clamp(34.0, 58.0);
    var previousRadius = activeRings.first.radius;
    for (var i = 1; i < activeRings.length; i++) {
      final ring = activeRings[i];
      final maxAllowedRadius = previousRadius - minSeparation;
      if (ring.radius > maxAllowedRadius) {
        ring.radius = maxAllowedRadius;
      }
      ring.radius = ring.radius.clamp(_ringThickness * 0.55, 9999.0);
      previousRadius = ring.radius;
    }
  }

  double _distanceToRingCenter(Ring ring) {
    final dx = _ball.x - ring.x;
    final dy = _ball.y - ring.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _applyPhysicalCollision(
    Ring ring,
    double previousDistance,
    double previousRadius,
  ) {
    final dx = _ball.x - ring.x;
    final dy = _ball.y - ring.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);
    final inGap = ring.containsAngle(angle);
    final inner = ring.radius - ring.thickness / 2;
    final outer = ring.radius + ring.thickness / 2;
    final crossedOuterBoundary =
        previousDistance <= (previousRadius + ring.thickness / 2) &&
        distance >= outer + _ball.radius * 0.12;
    final oldCrossedOutward =
        previousDistance <= previousRadius && distance >= previousRadius;
    final currentCrossedOutward =
        previousDistance <= ring.radius && distance >= ring.radius;

    // Failsafe: if the ball has clearly escaped ring zone in one frame, count it as break.
    if (crossedOuterBoundary) {
      ring.shatter();
      _broken++;
      _score += 25;
      _ball.velocityX *= 1.015;
      _ball.velocityY *= 1.015;
      return;
    }

    // Guaranteed break when the ball crosses the ring radius from inside to outside via gap.
    if (inGap && (oldCrossedOutward || currentCrossedOutward)) {
      ring.shatter();
      _broken++;
      _score += 25;
      _ball.velocityX *= 1.02;
      _ball.velocityY *= 1.02;
      return;
    }

    final minContact = inner - _ball.radius;
    final maxContact = outer + _ball.radius;
    if (distance < minContact || distance > maxContact) {
      return;
    }

    if (inGap && previousDistance < ring.radius && distance > outer + _ball.radius * 0.2) {
      ring.shatter();
      _broken++;
      _score += 25;
      _ball.velocityX *= 1.02;
      _ball.velocityY *= 1.02;
      return;
    }

    if (inGap) {
      return;
    }

    final normalX = distance == 0 ? 1 : dx / distance;
    final normalY = distance == 0 ? 0 : dy / distance;
    final direction = distance < ring.radius ? -1.0 : 1.0;
    final collisionNormalX = normalX * direction;
    final collisionNormalY = normalY * direction;
    final dot = _ball.velocityX * collisionNormalX + _ball.velocityY * collisionNormalY;
    if (dot < 0) {
      const restitution = 0.95;
      _ball.velocityX -= (1 + restitution) * dot * collisionNormalX;
      _ball.velocityY -= (1 + restitution) * dot * collisionNormalY;
    } else {
      // Keep bounce feedback even when the ball is already near tangent movement.
      _ball.velocityX += collisionNormalX * 0.75;
      _ball.velocityY += collisionNormalY * 0.75;
    }

    final speed = math.sqrt(
      _ball.velocityX * _ball.velocityX + _ball.velocityY * _ball.velocityY,
    );
    if (speed < 2.2) {
      _ball.velocityX += collisionNormalX * 1.4;
      _ball.velocityY += collisionNormalY * 1.4;
    }

    final correction = distance < ring.radius ? minContact - distance : distance - maxContact;
    final push = correction.abs() + 0.8;
    _ball.x += normalX * push * direction;
    _ball.y += normalY * push * direction;
  }

  void _checkFinishConditions() {
    final activeRings = _rings.where((ring) => !ring.isBroken).toList();
    if (activeRings.isEmpty) {
      return;
    }

    final collapseThreshold = _ball.radius + _ringThickness * 0.95;
    final allCollapsed = activeRings.every((ring) => ring.radius <= collapseThreshold);
    if (allCollapsed) {
      _finishRun(victory: false);
      return;
    }

    for (final ring in activeRings) {
      final distance = _distanceToRingCenter(ring);
      final crushLimit = _ball.radius + ring.thickness / 2 + 3;
      if (ring.radius <= crushLimit && distance < ring.radius + _ball.radius) {
        _finishRun(victory: false);
        return;
      }
      if (ring.isTooSmall) {
        _finishRun(victory: false);
        return;
      }
    }
  }

  Future<void> _finishRun({required bool victory}) async {
    if (_scoreSaved) {
      return;
    }
    _isFinished = true;
    _isVictory = victory;
    _scoreSaved = true;
    try {
      await StatsService.saveScore(_score);
    } catch (error) {
      LoggerService.error('Cannot save score', error);
    }
  }

  void _launchBall(Offset dragVector) {
    final length = dragVector.distance;
    final direction = length < 8 ? const Offset(0, -1) : dragVector / length;
    final power = (length * 0.14).clamp(6.0, 12.0) * _speedMultiplier;
    _ball.applyForce(direction.dx * power, direction.dy * power);
    _isLaunched = true;
  }

  void _applyAirControlDelta(Offset delta) {
    if (!_isLaunched || _isFinished || _isPaused) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastAirControlAt).inMilliseconds < 16) {
      return;
    }
    _lastAirControlAt = now;

    final swipeLength = delta.distance;
    if (swipeLength < 0.2) {
      return;
    }

    final speed = math.sqrt(
      _ball.velocityX * _ball.velocityX + _ball.velocityY * _ball.velocityY,
    );
    final scale = (0.18 / (1 + speed * 0.12)).clamp(0.08, 0.16);
    final impulseX = (delta.dx * scale).clamp(-0.32, 0.32);
    final impulseY = (delta.dy * scale * 0.55).clamp(-0.2, 0.2);
    _ball.applyForce(impulseX, impulseY);
  }

  void _togglePause() {
    if (_isFinished) {
      return;
    }
    setState(() => _isPaused = !_isPaused);
  }

  void _restart() {
    setState(_resetRun);
  }

  @override
  void dispose() {
    _physicsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          if (width > 0 &&
              height > 0 &&
              width != double.infinity &&
              height != double.infinity &&
              (_screenWidth != width || _screenHeight != height)) {
            _screenWidth = width;
            _screenHeight = height;
            if (!_isInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_isInitialized) {
                  _initializeGame();
                }
              });
            }
          }

          return GestureDetector(
            onPanStart: (details) {
              if (_isLaunched) {
                return;
              }
              if (_isFinished || _isPaused) {
                return;
              }
              setState(() {
                _dragStart = details.localPosition;
                _dragCurrent = details.localPosition;
              });
            },
            onPanUpdate: (details) {
              if (_isLaunched) {
                _applyAirControlDelta(details.delta);
                return;
              }
              if (_dragStart == null || _isFinished || _isPaused) {
                return;
              }
              setState(() => _dragCurrent = details.localPosition);
            },
            onPanEnd: (_) {
              if (_dragStart == null || _isFinished || _isPaused || _isLaunched) {
                return;
              }
              final current = _dragCurrent ?? _dragStart!;
              final dragVector = _dragStart! - current;
              setState(() {
                _launchBall(dragVector);
                _dragStart = null;
                _dragCurrent = null;
              });
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF080B1D), Color(0xFF152858), Color(0xFF253B72)],
                      ),
                    ),
                    child: CustomPaint(
                      painter: GamePainter(
                        ball: _ball,
                        rings: _rings,
                        isReadyToLaunch: !_isLaunched,
                        dragStart: _dragStart,
                        dragCurrent: _dragCurrent,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _chip('Score', _score.toString()),
                            const SizedBox(width: 8),
                            _chip('Broken', _broken.toString()),
                            const Spacer(),
                            _iconButton(_isPaused ? Icons.play_arrow : Icons.pause, _togglePause),
                            const SizedBox(width: 8),
                            _iconButton(Icons.refresh, _restart),
                          ],
                        ),
                        const Spacer(),
                        if (!_isLaunched && !_isFinished) _hint('Свайпни, чтобы запустить шар'),
                        if (_isLaunched && !_isFinished)
                          _hint('В полёте можно слегка корректировать траекторию тапом'),
                      ],
                    ),
                  ),
                ),
                if (_isPaused) _pauseOverlay(),
                if (_isFinished)
                  _resultOverlay(
                    victory: _isVictory,
                    score: _score,
                    broken: _broken,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 42, height: 42, child: Icon(icon, color: Colors.white)),
      ),
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePause,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Пауза',
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Тапни по экрану или нажми кнопку ниже',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _togglePause,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Продолжить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultOverlay({
    required bool victory,
    required int score,
    required int broken,
  }) {
    final accent = victory ? const Color(0xFF6C8FFF) : const Color(0xFFFF6F8E);
    final title = victory ? 'Победа' : 'Поражение';
    final subtitle = victory
        ? 'Отличный забег, продолжай держать темп.'
        : 'Кольца сошлись к центру. Попробуй новый заход.';
    return Container(
      color: Colors.black.withValues(alpha: 0.58),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.24),
                      const Color(0xFF1D2D59).withValues(alpha: 0.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: accent.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _resultRow('Score', '$score'),
                    _resultRow('Broken rings', '$broken'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _restart,
                        icon: const Icon(Icons.replay),
                        label: const Text('Сыграть еще'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent.withValues(alpha: 0.9),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.home),
                        label: const Text('Меню'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  GamePainter({
    required this.ball,
    required this.rings,
    required this.isReadyToLaunch,
    required this.dragStart,
    required this.dragCurrent,
  });

  final Ball ball;
  final List<Ring> rings;
  final bool isReadyToLaunch;
  final Offset? dragStart;
  final Offset? dragCurrent;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdropStars(canvas, size);
    for (final ring in rings) {
      _paintRing(canvas, ring);
    }
    _paintBall(canvas);
    _paintAim(canvas);
  }

  void _paintBackdropStars(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x66FFFFFF);
    for (var i = 0; i < 24; i++) {
      final seed = i * 31.0;
      final x = (seed * 17) % size.width;
      final y = (seed * 13) % size.height;
      canvas.drawCircle(Offset(x, y), (i % 3 + 1).toDouble(), paint);
    }
  }

  void _paintRing(Canvas canvas, Ring ring) {
    final center = Offset(ring.x, ring.y);
    final spawn = ring.spawnProgress.clamp(0.0, 1.0);
    final radius = ring.radius + ring.breakProgress * 16 + (1 - spawn) * 16;
    final strokeWidth =
        (ring.thickness * spawn * (1 - ring.breakProgress)).clamp(0.0, 28.0);
    if (strokeWidth < 0.2) {
      return;
    }

    final color = Color.lerp(const Color(0xFF6D88FF), const Color(0xFFFF8E4A), (ring.id % 4) / 4) ??
        const Color(0xFF6D88FF);
    final alpha = (spawn * (1 - ring.breakProgress)).clamp(0.0, 1.0);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..color = color.withValues(alpha: alpha * 0.42);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: alpha);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcStart = ring.gapStartAngle + ring.gapSize;
    final arcSweep = 2 * math.pi - ring.gapSize;
    canvas.drawArc(rect, arcStart, arcSweep, false, glow);
    canvas.drawArc(rect, arcStart, arcSweep, false, paint);
  }

  void _paintBall(Canvas canvas) {
    final center = Offset(ball.x, ball.y);
    final glow = Paint()
      ..color = const Color(0xFF90ECFF).withValues(alpha: 0.46)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, ball.radius + 6, glow);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFF8FD5FF), Color(0xFF4D86FF)],
      ).createShader(Rect.fromCircle(center: center, radius: ball.radius));
    canvas.drawCircle(center, ball.radius, paint);
  }

  void _paintAim(Canvas canvas) {
    if (!isReadyToLaunch || dragStart == null || dragCurrent == null) {
      return;
    }
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.65);
    final start = dragStart!;
    final current = dragCurrent!;
    canvas.drawLine(start, current, linePaint);
    canvas.drawCircle(start, 5, linePaint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
