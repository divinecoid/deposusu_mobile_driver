import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 800, height: 600);
  img.fill(image, color: img.ColorRgb8(0, 0, 0));
  
  img.drawString(
    image,
    '29 May 2026, 12:00:00',
    font: img.arial48,
    x: 10,
    y: 10,
    color: img.ColorRgb8(255, 165, 0),
  );
  print("Success");
}
