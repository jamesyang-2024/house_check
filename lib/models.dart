import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


/// 一张照片记录（带时间 + 备注）
class PhotoRecord {
  String path;
  DateTime time;
  String note;

  PhotoRecord({required this.path, required this.time, this.note = ''});

  Map<String, dynamic> toJson() => {
    'path': path,
    'time': time.toIso8601String(),
    'note': note,
  };

  factory PhotoRecord.fromJson(Map<String, dynamic> json) => PhotoRecord(
    path: json['path'],
    time: DateTime.parse(json['time']),
    note: json['note'] ?? '',
  );
}

/// 检查项
/// 检查项
class InspectionItem {
  String id;
  String name;
  List<PhotoRecord> photos;
  String note;

  InspectionItem({
    String? id,
    required this.name,
    List<PhotoRecord>? photos,
    this.note = '',
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        photos = photos ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photos': photos.map((e) => e.toJson()).toList(),
    'note': note,
  };

  factory InspectionItem.fromJson(Map<String, dynamic> json) => InspectionItem(
    id: json['id'] ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    name: json['name'],
    photos: (json['photos'] as List? ?? [])
        .map((e) => PhotoRecord.fromJson(e))
        .toList(),
    note: json['note'] ?? '',
  );
}

/// 房间
class Room {
  String name;
  String icon;
  List<InspectionItem> items;

  Room({required this.name, this.icon = '🏠', List<InspectionItem>? items})
      : items = items ?? [];

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'items': items.map((e) => e.toJson()).toList()
  };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    name: json['name'],
    icon: json['icon'] ?? '🏠',
    items: (json['items'] as List)
        .map((e) => InspectionItem.fromJson(e))
        .toList(),
  );
}

/// 小区
class Community {
  String name;
  List<Room> rooms;

  Community({required this.name, List<Room>? rooms}) : rooms = rooms ?? [];

  Map<String, dynamic> toJson() =>
      {'name': name, 'rooms': rooms.map((e) => e.toJson()).toList()};

  factory Community.fromJson(Map<String, dynamic> json) => Community(
    name: json['name'],
    rooms: (json['rooms'] as List).map((e) => Room.fromJson(e)).toList(),
  );
}

/// 全局状态
class AppState {
  static final AppState instance = AppState._();
  AppState._();

  List<Community> communities = [];
  int currentCommunityIndex = 0;
  bool _loaded = false;

  Community get currentCommunity => communities[currentCommunityIndex];
  List<Room> get rooms => currentCommunity.rooms;
  String get currentCommunityName => currentCommunity.name;

  Future<void> load() async {
    if (_loaded) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/house_check.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        communities = (data['communities'] as List)
            .map((e) => Community.fromJson(e))
            .toList();
        currentCommunityIndex = data['currentIndex'] ?? 0;
        if (currentCommunityIndex >= communities.length) {
          currentCommunityIndex = 0;
        }
      } catch (_) {
        communities = [Community(name: '默认小区', rooms: _defaultRooms())];
        currentCommunityIndex = 0;
      }
    } else {
      communities = [Community(name: '默认小区', rooms: _defaultRooms())];
      currentCommunityIndex = 0;
    }
    _loaded = true;
  }

  Future<void> save() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/house_check.json');
    await file.writeAsString(jsonEncode({
      'communities': communities.map((e) => e.toJson()).toList(),
      'currentIndex': currentCommunityIndex,
    }));
  }

  void addCommunity(String name) {
    communities.add(Community(name: name, rooms: _defaultRooms()));
    currentCommunityIndex = communities.length - 1;
  }

  Future<String> savePhoto(
      String community, String room, String item, File photo) async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/photos/$community/$room/$item');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    final ext = photo.path.split('.').last;
    final newPath =
        '${photoDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await photo.copy(newPath);
    return newPath;
  }
  void deleteCommunity(int index) {
    if (communities.length <= 1) return;
    communities.removeAt(index);
    if (currentCommunityIndex >= communities.length) {
      currentCommunityIndex = communities.length - 1;
    }
  }

  /// 默认房间和检查项（你可以自己增删）
  List<Room> _defaultRooms() {
    return [
      Room(name: '厨房', icon: '🍳', items: []),
      Room(name: '主卧', icon: '🛏️', items: []),
      Room(name: '客卧', icon: '🛏️', items: []),
      Room(name: '小房间', icon: '🚪', items: []),
      Room(name: '卫生间', icon: '🚿', items: []),
      Room(name: '阳台', icon: '🌿', items: []),
      Room(name: '客厅', icon: '🛋️', items: []),
    ];
  }
}