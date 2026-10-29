import 'package:flutter/material.dart';

class RoomStyle {
  final IconData icon;
  final Color color;
  const RoomStyle(this.icon, this.color);
}

RoomStyle getRoomStyle(String name) {
  switch (name) {
    case '厨房':
      return const RoomStyle(Icons.kitchen, Color(0xFFF57C00));
    case '主卧':
      return const RoomStyle(Icons.king_bed, Color(0xFF5C6BC0));
    case '客卧':
      return const RoomStyle(Icons.bed, Color(0xFF42A5F5));
    case '小房间':
      return const RoomStyle(Icons.meeting_room, Color(0xFF26A69A));
    case '卫生间':
      return const RoomStyle(Icons.shower, Color(0xFF29B6F6));
    case '阳台':
      return const RoomStyle(Icons.balcony, Color(0xFF66BB6A));
    case '客厅':
      return const RoomStyle(Icons.weekend, Color(0xFFAB47BC));
    case '书房':
      return const RoomStyle(Icons.menu_book, Color(0xFF8D6E63));
    case '餐厅':
      return const RoomStyle(Icons.dining, Color(0xFFEF5350));
    case '储物间':
      return const RoomStyle(Icons.inventory_2, Color(0xFF78909C));
    default:
      return const RoomStyle(Icons.home, Color(0xFF78909C));
  }
}