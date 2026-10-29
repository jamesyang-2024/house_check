import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import 'annotate_page.dart';
import 'photo_compare_page.dart';

class ItemPage extends StatefulWidget {
  final int roomIndex;
  final int itemIndex;
  const ItemPage({
    super.key,
    required this.roomIndex,
    required this.itemIndex,
  });

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  late InspectionItem item;
  bool _compareMode = false;
  final List<int> _selected = [];

  @override
  void initState() {
    super.initState();
    final room = AppState.instance.rooms[widget.roomIndex];
    item = room.items[widget.itemIndex];
  }

  String _formatTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$mo-$d $hh:$mm';
  }

  String _formatSize(String path) {
    try {
      final bytes = File(path).lengthSync();
      if (bytes < 1024) return '${bytes}B';
      return '${(bytes / 1024).toStringAsFixed(0)}K';
    } catch (_) {
      return '';
    }
  }

  Map<String, List<PhotoRecord>> _groupPhotos() {
    final map = <String, List<PhotoRecord>>{};
    for (final p in item.photos) {
      final key =
          '${p.time.year}年${p.time.month.toString().padLeft(2, '0')}月';
      map.putIfAbsent(key, () => []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.time.compareTo(a.time));
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in keys) k: map[k]!};
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final room = AppState.instance.rooms[widget.roomIndex];
      final community = AppState.instance.currentCommunityName;
      final newPath = await AppState.instance
          .savePhoto(community, room.name, item.name, File(picked.path));

      setState(() {
        item.photos.add(PhotoRecord(path: newPath, time: DateTime.now()));
      });
      await AppState.instance.save();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('拍照失败：$e')));
      }
    }
  }

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      _selected.clear();
    });
  }

  void _onPhotoTap(int index) {
    if (_compareMode) {
      setState(() {
        if (_selected.contains(index)) {
          _selected.remove(index);
        } else {
          if (_selected.length >= 2) return;
          _selected.add(index);
        }
      });
      if (_selected.length == 2) {
        _openCompare();
      }
    } else {
      _showPreview(index);
    }
  }

  void _openCompare() {
    final a = item.photos[_selected[0]];
    final b = item.photos[_selected[1]];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoComparePage(photoA: a, photoB: b),
      ),
    ).then((_) {
      setState(() {
        _selected.clear();
      });
    });
  }

  Future<void> _showPhotoMenu(int index) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.brush, color: Colors.orange),
              title: const Text('标注异常'),
              onTap: () => Navigator.pop(ctx, 'annotate'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.blue),
              title: const Text('添加备注'),
              onTap: () => Navigator.pop(ctx, 'note'),
            ),
            if (item.photos.length >= 2)
              ListTile(
                leading: const Icon(Icons.compare, color: Colors.green),
                title: const Text('与另一张对比'),
                onTap: () => Navigator.pop(ctx, 'compare'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'annotate') {
      await _annotatePhoto(index);
    } else if (action == 'note') {
      await _editPhotoNote(index);
    } else if (action == 'compare') {
      // 进入对比模式，已选中这张，让用户再选第二张
      setState(() {
        _compareMode = true;
        _selected.clear();
        _selected.add(index);
      });
      _snack('再选一张照片进行对比');
    } else if (action == 'delete') {
      await _deletePhoto(index);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _annotatePhoto(int index) async {
    final photo = item.photos[index];
    final newPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AnnotatePage(imagePath: photo.path),
      ),
    );

    if (newPath != null) {
      try {
        final oldFile = File(photo.path);
        if (await oldFile.exists()) await oldFile.delete();
      } catch (_) {}
      setState(() => photo.path = newPath);
      await AppState.instance.save();
    }
  }

  Future<void> _editPhotoNote(int index) async {
    final photo = item.photos[index];
    final controller = TextEditingController(text: photo.note);

    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('添加备注'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '输入这张照片的备注...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (note != null) {
      setState(() => photo.note = note);
      await AppState.instance.save();
    }
  }

  Future<void> _deletePhoto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除照片'),
        content: const Text('确定删除这张照片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final file = File(item.photos[index].path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      setState(() {
        item.photos.removeAt(index);
        _selected.remove(index);
      });
      await AppState.instance.save();
    }
  }

  void _showPreview(int index) {
    final photo = item.photos[index];
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Image.file(File(photo.path)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _deletePhoto(index);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (photo.note.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    photo.note,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupPhotos();

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (item.photos.length >= 2)
            IconButton(
              icon: Icon(_compareMode ? Icons.close : Icons.compare),
              tooltip: _compareMode ? '退出对比' : '对比照片',
              onPressed: _toggleCompareMode,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_compareMode)
            Container(
              color: Colors.green.withValues(alpha: 0.1),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.compare, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selected.isEmpty
                          ? '选两张照片进行对比'
                          : '已选 ${_selected.length}/2 张',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selected.clear()),
                      child: const Text('清空'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (!_compareMode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _takePhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('拍照'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _takePhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('相册'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[300],
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (item.photos.isEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('还没有照片\n长按照片可添加备注',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...grouped.entries.map((entry) {
                    final monthKey = entry.key;
                    final photos = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                monthKey,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${photos.length} 张',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.66,
                          ),
                          itemCount: photos.length,
                          itemBuilder: (context, i) {
                            final photo = photos[i];
                            final realIndex =
                            item.photos.indexOf(photo);
                            final sizeText = _formatSize(photo.path);
                            final isSelected =
                            _selected.contains(realIndex);
                            return GestureDetector(
                              onTap: () => _onPhotoTap(realIndex),
                              onLongPress: _compareMode
                                  ? null
                                  : () => _showPhotoMenu(realIndex),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(6),
                                          child: Image.file(
                                            File(photo.path),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _formatTime(photo.time),
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey[700]),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (sizeText.isNotEmpty)
                                        Text(
                                          sizeText,
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey[500]),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                        ),
                                      if (photo.note.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 3,
                                              vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.orange
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                            BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            photo.note,
                                            style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.deepOrange,
                                                fontWeight:
                                                FontWeight.w500),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isSelected)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.green,
                                              width: 3),
                                          borderRadius:
                                          BorderRadius.circular(6),
                                        ),
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: Container(
                                            margin: const EdgeInsets.all(4),
                                            padding:
                                            const EdgeInsets.all(4),
                                            decoration:
                                            const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}