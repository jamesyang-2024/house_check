import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models.dart';

class QrPage extends StatelessWidget {
  final String communityName;
  final String roomName;
  final InspectionItem item;

  const QrPage({
    super.key,
    required this.communityName,
    required this.roomName,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    // 用名字组合作为二维码内容，稳定、永久有效
    final data =
        'housecheck://item?community=${Uri.encodeComponent(communityName)}'
        '&room=${Uri.encodeComponent(roomName)}'
        '&item=${Uri.encodeComponent(item.name)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('检查项二维码'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                communityName,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                '$roomName · ${item.name}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '扫描二维码可直接打开此检查项',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}