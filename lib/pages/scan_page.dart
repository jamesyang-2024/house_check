import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models.dart';
import 'item_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _picking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null) return;

    _handled = true;
    _handleResult(raw);
  }

  Future<void> _pickFromGallery() async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() => _picking = false);
        return;
      }

      final capture = await _controller.analyzeImage(picked.path);

      if (capture == null || capture.barcodes.isEmpty) {
        _showError('图片中没有识别到二维码');
        return;
      }

      final raw = capture.barcodes.first.rawValue;
      if (raw == null || raw.isEmpty) {
        _showError('二维码内容为空');
        return;
      }

      _handled = true;
      _handleResult(raw);
    } catch (e) {
      _showError('识别失败：$e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _handleResult(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'housecheck' || uri.host != 'item') {
      _showError('这不是有效的检查项二维码');
      return;
    }

    final community = uri.queryParameters['community'];
    final room = uri.queryParameters['room'];
    final item = uri.queryParameters['item'];

    if (community == null || room == null || item == null) {
      _showError('二维码缺少参数');
      return;
    }

    // 1. 先找同名小区
    final state = AppState.instance;
    int communityIndex = state.communities
        .indexWhere((c) => c.name == community);

    if (communityIndex == -1) {
      // 小区不存在，问用户是否创建
      final ok = await _confirmCreate(
        '未找到小区「$community」',
        '是否创建该小区并打开检查项？',
      );
      if (ok != true) {
        _resetHandle();
        return;
      }
      state.addCommunity(community);
      await state.save();
      communityIndex = state.communities.length - 1;
    }

    state.currentCommunityIndex = communityIndex;

    // 2. 找同名房间
    final rooms = state.communities[communityIndex].rooms;
    int roomIndex = rooms.indexWhere((r) => r.name == room);

    if (roomIndex == -1) {
      final ok = await _confirmCreate(
        '未找到房间「$room」',
        '是否在小区「$community」中创建该房间并打开检查项？',
      );
      if (ok != true) {
        _resetHandle();
        return;
      }
      rooms.add(Room(name: room, icon: '🏠', items: []));
      await state.save();
      roomIndex = rooms.length - 1;
    }

    // 3. 找同名检查项
    final items = rooms[roomIndex].items;
    int itemIndex = items.indexWhere((i) => i.name == item);

    if (itemIndex == -1) {
      final ok = await _confirmCreate(
        '未找到检查项「$item」',
        '是否在「$community / $room」中创建该检查项？',
      );
      if (ok != true) {
        _resetHandle();
        return;
      }
      items.add(InspectionItem(name: item));
      await state.save();
      itemIndex = items.length - 1;
    }

    // 4. 跳转
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemPage(
          roomIndex: roomIndex,
          itemIndex: itemIndex,
        ),
      ),
    );
  }

  Future<bool?> _confirmCreate(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _resetHandle() {
    if (mounted) setState(() => _handled = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _handled = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫一扫'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: '从相册选择',
            onPressed: _picking ? null : _pickFromGallery,
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, _) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                  default:
                    return const Icon(Icons.flash_off);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
            tooltip: '闪光灯',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '将二维码放入框内',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _picking ? null : _pickFromGallery,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _picking ? '识别中...' : '从相册选二维码',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_picking)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}