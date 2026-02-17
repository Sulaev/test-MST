class Obstacle {
  double x;
  double y;
  final double width;
  final double height;
  final double speed;
  bool passed;

  Obstacle({
    required this.x,
    required this.y,
    this.width = 50,
    this.height = 200,
    this.speed = 3,
    this.passed = false,
  });

  void update() {
    x -= speed;
  }

  bool isOffScreen(double screenWidth) {
    return x + width < 0;
  }

  bool checkPassed(double airplaneX) {
    if (!passed && x + width < airplaneX) {
      passed = true;
      return true;
    }
    return false;
  }
}
