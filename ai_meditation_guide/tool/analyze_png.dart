import 'dart:io';
import 'package:image/image.dart' as img;

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'assets/icon_foreground.png';
  final bytes = File(path).readAsBytesSync();
  final image = img.decodePng(bytes);
  if (image == null) {
    stderr.writeln('Failed to decode: '+path);
    exit(1);
  }
  int minA = 255;
  int maxA = 0;
  int nonZero = 0;
  int opaque = 0;
  final total = image.width * image.height;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final a = p.a.toInt();
      if (a < minA) minA = a;
      if (a > maxA) maxA = a;
      if (a > 0) nonZero++;
      if (a == 255) opaque++;
    }
  }
  print('path=$path size=${image.width}x${image.height} minA=$minA maxA=$maxA nonZero=$nonZero (${(nonZero/total*100).toStringAsFixed(2)}%) opaque=$opaque (${(opaque/total*100).toStringAsFixed(2)}%)');
}
