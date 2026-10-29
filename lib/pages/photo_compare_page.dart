import 'dart:io';
import 'package:flutter/material.dart';
import '../models.dart';

class PhotoComparePage extends StatefulWidget {
  final PhotoRecord photoA;
  final PhotoRecord photoB;
  const PhotoComparePage({
    super.key,
    required this.photoA,
    required this.photoB,
  });

  @override
  State<PhotoComparePage> createState() => _PhotoComparePageState();
}

class _PhotoComparePageState extends State<PhotoComparePage> {
  double _split = 0.5;

  String _formatTime(DateTime t) {
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$mo-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('照片对比'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final splitX = width * _split;

          return GestureDetector(
            onHorizontalDragUpdate: (d) {
              setState(() {
                _split = (_split + d.delta.dx / width).clamp(0.02, 0.98);
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 底图 B
                Image.file(File(widget.photoB.path), fit: BoxFit.contain),
                // 顶图 A（裁切左半部分）
                ClipRect(
                  clipper: _SplitClipper(_split),
                  child: Image.file(File(widget.photoA.path),
                      fit: BoxFit.contain),
                ),
                // 分隔线
                Positioned(
                  left: splitX - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white),
                ),
                // 拖动图标
                Positioned(
                  left: splitX - 18,
                  top: constraints.maxHeight / 2 - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.code, color: Colors.black87),
                  ),
                ),
                // 左侧标签
                Positioned(
                  left: 12,
                  top: 12,
                  child: _tag('A', _formatTime(widget.photoA.time),
                      widget.photoA.note),
                ),
                // 右侧标签
                Positioned(
                  right: 12,
                  top: 12,
                  child: _tag('B', _formatTime(widget.photoB.time),
                      widget.photoB.note),
                ),
                // 底部提示
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '← 左右拖动查看差异 →',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tag(String label, String time, String note) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label  $time',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (note.isNotEmpty)
            Text(
              note,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double split;
  _SplitClipper(this.split);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * split, size.height);

  @override
  bool shouldReclip(covariant _SplitClipper old) => old.split != split;
}