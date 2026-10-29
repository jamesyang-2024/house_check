import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// 获取当前位置的城市名
/// 策略：优先用 GPS 经纬度查，GPS 超时就退回纯 IP 定位
Future<String?> getCurrentLocation(BuildContext context) async {
  try {
    // 1. 检查定位服务
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _toast(context, '请先打开手机的定位服务');
      return null;
    }

    // 2. 检查权限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _toast(context, '定位权限被拒绝');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _toast(context, '定位权限被永久拒绝，请在系统设置中开启');
      return null;
    }

    // 3. 尝试获取 GPS 位置（8 秒超时，比之前短很多）
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      // GPS 失败或超时，pos 保持 null
      pos = null;
    }

    // 4. 用经纬度或 IP 查询城市名
    final result = await _queryCity(pos?.latitude, pos?.longitude);
    if (result != null) return result;

    _toast(context, '定位失败，请检查网络');
    return null;
  } catch (e) {
    _toast(context, '定位失败：$e');
    return null;
  }
}

/// 调用 BigDataCloud 免费 API 查询城市
/// 传经纬度 → 精确到城市
/// 不传 → 自动用请求来源的 IP 定位
Future<String?> _queryCity(double? lat, double? lng) async {
  try {
    final base = 'https://api.bigdatacloud.net/data/reverse-geocode-client';
    final uri = Uri.parse(
      lat != null && lng != null
          ? '$base?latitude=$lat&longitude=$lng&localityLanguage=zh'
          : '$base?localityLanguage=zh',
    );

    final resp = await http.get(uri).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body);
    final city = (data['city'] ?? data['locality'] ?? '') as String;
    final province = (data['principalSubdivision'] ?? '') as String;
    final country = (data['countryName'] ?? '') as String;

    // 组装：优先「省份 城市」，其次「城市」，再次「国家」
    if (province.isNotEmpty && city.isNotEmpty) {
      return '$province $city';
    }
    if (city.isNotEmpty) return city;
    if (province.isNotEmpty) return province;
    if (country.isNotEmpty) return country;
    return null;
  } catch (_) {
    return null;
  }
}

void _toast(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
  );
}