class Airplane {
  double x;
  double y;
  double velocityY;
  final double width;
  final double height;
  final double speed;

  Airplane({
    required this.x,
    required this.y,
    this.velocityY = 0,
    this.width = 60,
    this.height = 40,
    this.speed = 3,
  });

  void update(double screenHeight) {
    // Применяем гравитацию
    velocityY += 0.3;

    // Обновляем позицию
    y += velocityY;

    // Ограничиваем позицию
    if (y < 0) {
      y = 0;
      velocityY = 0;
    }
    if (y + height > screenHeight) {
      y = screenHeight - height;
      velocityY = 0;
    }

    // Ограничиваем скорость
    velocityY = velocityY.clamp(-8.0, 8.0);
  }

  void moveUp() {
    velocityY -= 5;
  }

  void reset(double startX, double startY) {
    x = startX;
    y = startY;
    velocityY = 0;
  }

  bool checkCollision(double obstacleX, double obstacleY, double obstacleWidth, double obstacleHeight) {
    return x < obstacleX + obstacleWidth &&
        x + width > obstacleX &&
        y < obstacleY + obstacleHeight &&
        y + height > obstacleY;
  }
}
