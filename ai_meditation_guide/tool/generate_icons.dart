import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() async {
  final sourceFile = File('assets/Image.png');
  final sourceBytes = await sourceFile.readAsBytes();
  final sourceImage = img.decodeImage(sourceBytes)!;

  const size = 1024;
  
  // Создаём iOS иконку с белым фоном и свечениями
  final iosIcon = img.Image(width: size, height: size, numChannels: 4);
  
  // Белый фон
  img.fill(iosIcon, color: img.ColorRgba8(255, 255, 255, 255));
  
  // Фиолетовое свечение сверху по центру (вокруг фиолетового камня)
  _drawGlow(iosIcon, 
    centerX: (size * 0.5).toInt(),
    centerY: (size * 0.18).toInt(),
    radiusX: (size * 0.35).toInt(),
    radiusY: (size * 0.12).toInt(),
    color: img.ColorRgba8(203, 167, 255, 180), // #CBA7FF
    blur: 180,
  );
  
  // Зелёное свечение СНИЗУ СЛЕВА от камней
  _drawGlow(iosIcon, 
    centerX: (size * 0.28).toInt(),  // Слева
    centerY: (size * 0.72).toInt(),  // Снизу
    radiusX: (size * 0.35).toInt(),
    radiusY: (size * 0.18).toInt(),
    color: img.ColorRgba8(119, 201, 126, 180), // #77C97E
    blur: 180,
  );
  
  // Камни крупнее и ближе к центру (фокус на камнях)
  final scaledSize = (size * 0.98).toInt();
  final scaled = img.copyResize(sourceImage, width: scaledSize, height: scaledSize);
  final x = (size - scaledSize) ~/ 2;
  final y = ((size - scaledSize) ~/ 2) + (size * 0.04).toInt();
  img.compositeImage(iosIcon, scaled, dstX: x, dstY: y);
  
  await File('assets/icon_ios.png').writeAsBytes(img.encodePng(iosIcon));
  print('Created icon_ios.png');

  // Создаём foreground для Android (прозрачный фон, только камни + свечения)
  final foreground = img.Image(width: size, height: size, numChannels: 4);
  img.fill(foreground, color: img.ColorRgba8(0, 0, 0, 0));
  
  // Фиолетовое свечение сверху
  _drawGlow(foreground, 
    centerX: (size * 0.5).toInt(),
    centerY: (size * 0.18).toInt(),
    radiusX: (size * 0.30).toInt(),
    radiusY: (size * 0.10).toInt(),
    color: img.ColorRgba8(203, 167, 255, 140),
    blur: 150,
  );
  
  // Зелёное свечение снизу слева
  _drawGlow(foreground, 
    centerX: (size * 0.28).toInt(),
    centerY: (size * 0.70).toInt(),
    radiusX: (size * 0.30).toInt(),
    radiusY: (size * 0.15).toInt(),
    color: img.ColorRgba8(119, 201, 126, 140),
    blur: 150,
  );
  
  img.compositeImage(foreground, scaled, dstX: x, dstY: y);
  
  await File('assets/icon_foreground.png').writeAsBytes(img.encodePng(foreground));
  print('Created icon_foreground.png');
  
  print('Done! Now run: dart pub global run flutter_launcher_icons');
}

void _drawGlow(img.Image image, {
  required int centerX,
  required int centerY,
  required int radiusX,
  required int radiusY,
  required img.Color color,
  required int blur,
}) {
  final r = (color as img.ColorRgba8).r;
  final g = color.g;
  final b = color.b;
  final a = color.a;
  
  for (var py = 0; py < image.height; py++) {
    for (var px = 0; px < image.width; px++) {
      final dx = (px - centerX) / (radiusX + blur);
      final dy = (py - centerY) / (radiusY + blur);
      final dist = math.sqrt(dx * dx + dy * dy);
      
      if (dist < 1.0) {
        // Gaussian-like falloff
        final intensity = math.exp(-dist * dist * 3) * (a / 255);
        final existing = image.getPixel(px, py);
        
        final newR = ((existing.r * (1 - intensity)) + (r * intensity)).clamp(0, 255).toInt();
        final newG = ((existing.g * (1 - intensity)) + (g * intensity)).clamp(0, 255).toInt();
        final newB = ((existing.b * (1 - intensity)) + (b * intensity)).clamp(0, 255).toInt();
        final newA = math.max(existing.a.toInt(), (intensity * 255).toInt());
        
        image.setPixel(px, py, img.ColorRgba8(newR, newG, newB, newA));
      }
    }
  }
}
