import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // 深蓝 → 深紫渐变背景
  for (int y = 0; y < size; y++) {
    final t = y / size;
    final r = (26 + (67 - 26) * t).round();
    final g = (35 + (39 - 35) * t).round();
    final b = (126 + (156 - 126) * t).round();
    for (int x = 0; x < size; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  final white = img.ColorRgb8(255, 255, 255);
  final green = img.ColorRgb8(76, 217, 100);

  // ===== 盾牌轮廓（线条，白色）=====
  const t = 38; // 线条粗细
  // 左上斜
  _line(image, 280, 380, 512, 240, white, t);
  // 右上斜
  _line(image, 512, 240, 744, 380, white, t);
  // 左直边
  _line(image, 280, 380, 280, 580, white, t);
  // 右直边
  _line(image, 744, 380, 744, 580, white, t);
  // 左下斜（收成尖角）
  _line(image, 280, 580, 512, 800, white, t);
  // 右下斜
  _line(image, 744, 580, 512, 800, white, t);

  // ===== 中间的对勾（绿色）=====
  _line(image, 400, 500, 480, 590, green, 46);
  _line(image, 480, 590, 650, 420, green, 46);

  final file = File('assets/icon/app_icon.png');
  file.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  print('✅ 图标已生成: ${file.path}');
}

void _line(img.Image image, int x1, int y1, int x2, int y2,
    img.Color color, int thickness) {
  final steps = (x2 - x1).abs() + (y2 - y1).abs() + 1;
  for (int i = 0; i <= steps; i++) {
    final tt = i / steps;
    final x = (x1 + (x2 - x1) * tt).round();
    final y = (y1 + (y2 - y1) * tt).round();
    img.fillCircle(image, x: x, y: y, radius: thickness ~/ 2, color: color);
  }
}