class Ball {
  double x;
  double y;
  double velocityX;
  double velocityY;
  final double radius;
  final double gravity;

  Ball({
    required this.x,
    required this.y,
    this.velocityX = 0,
    this.velocityY = 0,
    this.radius = 20,
    this.gravity = 0.5,
  });

  void update(
    double screenWidth,
    double screenHeight, {
    bool bounceBottom = true,
    double bounceDamping = 0.8,
    double maxVelocityX = 10,
    double maxVelocityY = 15,
  }) {
    // Применяем гравитацию
    velocityY += gravity;

    // Обновляем позицию
    x += velocityX;
    y += velocityY;

    // Отскок от стен
    if (x - radius <= 0 && velocityX < 0) {
      velocityX *= -bounceDamping; // Потеря энергии при отскоке
      x = radius;
    } else if (x + radius >= screenWidth && velocityX > 0) {
      velocityX *= -bounceDamping; // Потеря энергии при отскоке
      x = screenWidth - radius;
    }

    if (y - radius <= 0 && velocityY < 0) {
      velocityY *= -bounceDamping;
      y = radius;
    }

    if (bounceBottom && y + radius >= screenHeight && velocityY > 0) {
      velocityY *= -bounceDamping;
      y = screenHeight - radius;
    }

    // Ограничиваем скорость
    velocityX = velocityX.clamp(-maxVelocityX, maxVelocityX);
    velocityY = velocityY.clamp(-maxVelocityY, maxVelocityY);
  }

  void applyForce(double forceX, double forceY) {
    velocityX += forceX;
    velocityY += forceY;
  }

  void reset(double startX, double startY) {
    x = startX;
    y = startY;
    velocityX = 0;
    velocityY = 0;
  }
}
