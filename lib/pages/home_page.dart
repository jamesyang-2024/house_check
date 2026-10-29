import 'package:flutter/material.dart';
import '../models.dart';
import 'room_page.dart';
import '../room_style.dart';
import 'scan_page.dart';
import '../location_utils.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationText = '定位中...';
  bool _locating = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppState.instance.load();
    setState(() => _loading = false);
    _autoLocate();
  }
  /// 自动定位（不弹框，直接更新文字）
  Future<void> _autoLocate() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationText = '定位中...';
    });

    final result = await getCurrentLocation(context);

    if (!mounted) return;
    setState(() {
      _locationText = result ?? '定位失败，点击重试';
      _locating = false;
    });
  }

  Future<void> _selectCommunity() async {
    final communities = AppState.instance.communities;
    final result = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择小区',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ...communities.asMap().entries.map((e) {
              final selected = e.key == AppState.instance.currentCommunityIndex;
              return ListTile(
                leading: Icon(Icons.location_city,
                    color: selected ? Colors.blue : Colors.grey),
                title: Text(e.value.name),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(ctx, e.key),
                onLongPress: () {
                  Navigator.pop(ctx);
                  _showCommunityMenu(e.key);
                },
              );
            }),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blue),
              title: const Text('新增小区', style: TextStyle(color: Colors.blue)),
              onTap: () => Navigator.pop(ctx, -1),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;
    if (result == -1) {
      await _addCommunity();
    } else {
      setState(() {
        AppState.instance.currentCommunityIndex = result;
      });
      await AppState.instance.save();
    }
  }

  Future<void> _addCommunity() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新增小区'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入小区名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          TextButton(
            onPressed: () {
              final n = controller.text.trim();
              if (n.isNotEmpty) Navigator.pop(context, n);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      AppState.instance.addCommunity(name);
      await AppState.instance.save();
      setState(() {});
    }
  }
  /// 长按小区 → 修改 / 删除
  Future<void> _showCommunityMenu(int index) async {
    final name = AppState.instance.communities[index].name;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('修改名称'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            if (AppState.instance.communities.length > 1)
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

    if (action == 'edit') {
      await _editCommunity(index);
    } else if (action == 'delete') {
      await _deleteCommunity(index);
    }
  }

  /// 修改小区名称
  Future<void> _editCommunity(int index) async {
    final controller = TextEditingController(
        text: AppState.instance.communities[index].name);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('修改小区名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新的名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final n = controller.text.trim();
              if (n.isNotEmpty) Navigator.pop(context, n);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        AppState.instance.communities[index].name = newName;
      });
      await AppState.instance.save();
    }
  }

  /// 删除小区
  Future<void> _deleteCommunity(int index) async {
    final name = AppState.instance.communities[index].name;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除小区'),
        content: Text('确定删除「$name」吗？\n该小区下的所有检查记录和照片都会被删除。'),
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
      setState(() {
        AppState.instance.deleteCommunity(index);
      });
      await AppState.instance.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rooms = AppState.instance.rooms;
    final communityName = AppState.instance.currentCommunityName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('房屋检查'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ===== 小区选择条 =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_city,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _selectCommunity,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              communityName,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 定位显示（点击可重新定位）
                Material(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _locating ? null : _autoLocate,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 44, maxWidth: 130),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_locating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(Icons.location_on, color: Colors.white, size: 18),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _locationText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 新增小区按钮
                Material(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _addCommunity,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== 房间网格 =====
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final style = getRoomStyle(room.name);
                final hasPhotos =
                room.items.any((e) => e.photos.isNotEmpty);

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RoomPage(roomIndex: index)),
                    ).then((_) => setState(() {})),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: style.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              style.icon,
                              color: style.color,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            room.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasPhotos) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanPage()),
          ).then((_) => setState(() {}));
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        tooltip: '扫一扫',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}