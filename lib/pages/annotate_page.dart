import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  Stroke({required this.points, required this.color, required this.width});
}

class AnnotatePage extends StatefulWidget {
  final String imagePath;
  const AnnotatePage({super.key, required this.imagePath});

  @override
  State<AnnotatePage> createState() => _AnnotatePageState();
}

class _AnnotatePageState extends State<AnnotatePage> {
  final List<Stroke> _strokes = [];
  Stroke? _current;
  Color _color = Colors.red;
  double _width = 6;
  bool _saving = false;

  Size _displaySize = Size.zero;
  ui.Image? _originalImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() => _originalImage = frame.image);
  }

  void _startStroke(Offset p) {
    setState(() => _current = Stroke(points: [p], color: _color, width: _width));
  }

  void _addPoint(Offset p) {
    if (_current == null) return;
    setState(() => _current!.points.add(p));
  }

  void _endStroke() {
    if (_current == null) return;
    if (_current!.points.length == 1) {
      _current!.points.add(_current!.points[0] + const Offset(0.5, 0.5));
    }
    setState(() {
      _strokes.add(_current!);
      _current = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    setState(() => _strokes.clear());
  }

  Future<void> _save() async {
    if (_originalImage == null || _displaySize == Size.zero) return;
    setState(() => _saving = true);

    try {
      final origW = _originalImage!.width;
      final origH = _originalImage!.height;
      final scaleX = origW / _displaySize.width;
      final scaleY = origH / _displaySize.height;

      final bytes = await File(widget.imagePath).readAsBytes();
      final image = img.decodeImage(bytes)!;

      for (final stroke in _strokes) {
        final color = img.ColorRgba8(
          stroke.color.red,
          stroke.color.green,
          stroke.color.blue,
          255,
        );
        final thickness = (stroke.width * scaleX).round().clamp(1, 60);

        for (int i = 0; i < stroke.points.length - 1; i++) {
          final p1 = stroke.points[i];
          final p2 = stroke.points[i + 1];
          img.drawLine(
            image,
            x1: (p1.dx * scaleX).round(),
            y1: (p1.dy * scaleY).round(),
            x2: (p2.dx * scaleX).round(),
            y2: (p2.dy * scaleY).round(),
            color: color,
            thickness: thickness,
            antialias: true,
          );
        }
      }

      final dir = await getTemporaryDirectory();
      final newPath =
          '${dir.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(newPath).writeAsBytes(img.encodeJpg(image, quality: 90));

      if (mounted) Navigator.pop(context, newPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('标注异常'),
        actions: [
          IconButton(
            onPressed: _strokes.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
          ),
          IconButton(
            onPressed: _strokes.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _originalImage == null
                  ? const CircularProgressIndicator()
                  : LayoutBuilder(
                builder: (context, constraints) {
                  final imgW = _originalImage!.width.toDouble();
                  final imgH = _originalImage!.height.toDouble();
                  final ratio = imgW / imgH;
                  double w = constraints.maxWidth;
                  double h = w / ratio;
                  if (h > constraints.maxHeight) {
                    h = constraints.maxHeight;
                    w = h * ratio;
                  }
                  _displaySize = Size(w, h);

                  return GestureDetector(
                    onPanStart: (d) => _startStroke(d.localPosition),
                    onPanUpdate: (d) => _addPoint(d.localPosition),
                    onPanEnd: (_) => _endStroke(),
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: RawImage(
                              image: _originalImage,
                              fit: BoxFit.fill,
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _StrokePainter(
                                strokes: _strokes,
                                current: _current,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    const colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.white,
      Colors.black,
    ];

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: colors.map((c) {
                final selected = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.grey,
                        width: selected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('粗细',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _width,
                    min: 2,
                    max: 20,
                    activeColor: _color,
                    onChanged: (v) => setState(() => _width = v),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text('${_width.round()}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.check),
                label: Text(_saving ? '保存中...' : '保存标注'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? current;

  _StrokePainter({required this.strokes, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _drawStroke(canvas, s);
    }
    if (current != null) _drawStroke(canvas, current!);
  }

  void _drawStroke(Canvas canvas, Stroke s) {
    if (s.points.isEmpty) return;
    final paint = Paint()
      ..color = s.color
      ..strokeWidth = s.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (s.points.length == 1) {
      canvas.drawCircle(s.points[0], s.width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path()..moveTo(s.points[0].dx, s.points[0].dy);
    for (int i = 1; i < s.points.length; i++) {
      path.lineTo(s.points[i].dx, s.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}