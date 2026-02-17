import 'dart:math' as math;

class Ring {
  Ring({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.thickness,
    required this.gapStartAngle,
    required this.gapSize,
    required this.angularVelocity,
    required this.shrinkSpeed,
    required this.initialRadius,
  });

  final int id;
  final double x;
  double y;
  double radius;
  final double thickness;
  double gapStartAngle;
  final double gapSize;
  final double angularVelocity;
  final double shrinkSpeed;
  final double initialRadius;
  bool isBroken = false;
  double breakProgress = 0;
  double spawnProgress = 0;

  void update({bool shrink = true, double shrinkFactor = 1.0}) {
    if (shrink) {
      radius -= shrinkSpeed * shrinkFactor;
    }
    final radiusFactor = (radius / initialRadius).clamp(0.32, 1.25);
    gapStartAngle = _normalize(gapStartAngle + angularVelocity * radiusFactor);
    spawnProgress = (spawnProgress + 0.06).clamp(0.0, 1.0);
    if (isBroken) {
      breakProgress = (breakProgress + 0.08).clamp(0.0, 1.0);
    }
  }

  bool get isGone => isBroken && breakProgress >= 1;

  void shatter() {
    isBroken = true;
    breakProgress = 0;
  }

  bool get isTooSmall => radius <= (thickness * 0.65);

  bool containsAngle(double angle) {
    final normalizedAngle = _normalize(angle);
    final gapEnd = _normalize(gapStartAngle + gapSize);
    if (gapStartAngle <= gapEnd) {
      return normalizedAngle >= gapStartAngle && normalizedAngle <= gapEnd;
    }
    return normalizedAngle >= gapStartAngle || normalizedAngle <= gapEnd;
  }

  double _normalize(double angle) {
    var value = angle % (2 * math.pi);
    if (value < 0) {
      value += 2 * math.pi;
    }
    return value;
  }
}
