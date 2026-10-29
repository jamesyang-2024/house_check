import 'package:flutter/material.dart';
import '../models.dart';
import '../room_style.dart';
import 'item_page.dart';
import 'qr_page.dart';

class RoomPage extends StatefulWidget {
  final int roomIndex;
  const RoomPage({super.key, required this.roomIndex});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  Room get room => AppState.instance.rooms[widget.roomIndex];

  Future<void> _addItem() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('添加检查项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '例如：墙面、水龙头、插座',
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
      setState(() {
        room.items.add(InspectionItem(name: name));
      });
      await AppState.instance.save();
    }
  }

  /// 长按检查项 → 重命名 / 删除
  Future<void> _showItemMenu(int index) async {
    final item = room.items[index];
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
              child: Text(item.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.green),
              title: const Text('生成二维码'),
              onTap: () => Navigator.pop(ctx, 'qr'),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('重命名'),
              onTap: () => Navigator.pop(ctx, 'rename'),
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

    if (action == 'qr') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QrPage(
            communityName: AppState.instance.currentCommunityName,
            roomName: room.name,
            item: item,
          ),
        ),
      );
    } else if (action == 'rename') {
      await _renameItem(index);
    } else if (action == 'delete') {
      await _deleteItem(index);
    }
  }

  /// 重命名
  Future<void> _renameItem(int index) async {
    final item = room.items[index];
    final controller = TextEditingController(text: item.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('重命名检查项'),
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
              child: const Text('取消')),
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
        item.name = newName;
      });
      await AppState.instance.save();
    }
  }

  Future<void> _deleteItem(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除检查项'),
        content: Text('确定删除「${room.items[index].name}」吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        room.items.removeAt(index);
      });
      await AppState.instance.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = getRoomStyle(room.name);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: style.color,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(style.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              room.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            tooltip: '添加检查项',
          ),
        ],
      ),
      body: room.items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('还没有检查项',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text('点击右上角 + 添加',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: room.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = room.items[index];
          final photoCount = item.photos.length;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: photoCount > 0
                    ? style.color
                    : Colors.grey[300],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: photoCount > 0 ? Colors.white : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(item.name),
              subtitle: Text(
                photoCount > 0 ? '已拍 $photoCount 张' : '未检查',
                style: TextStyle(
                  color: photoCount > 0 ? style.color : Colors.grey,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_right),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.grey, size: 20),
                    onPressed: () => _deleteItem(index),
                  ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemPage(
                    roomIndex: widget.roomIndex,
                    itemIndex: index,
                  ),
                ),
              ).then((_) => setState(() {})),
              onLongPress: () => _showItemMenu(index),
            ),
          );
        },
      ),
    );
  }
}