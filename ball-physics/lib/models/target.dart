class Target {
  double x;
  double y;
  final double radius;
  bool collected;

  Target({
    required this.x,
    required this.y,
    this.radius = 15,
    this.collected = false,
  });

  bool checkCollision(double ballX, double ballY, double ballRadius) {
    if (collected) return false;
    
    final dx = x - ballX;
    final dy = y - ballY;
    final distance = (dx * dx + dy * dy);
    final minDistance = (radius + ballRadius) * (radius + ballRadius);
    
    return distance <= minDistance;
  }
}
