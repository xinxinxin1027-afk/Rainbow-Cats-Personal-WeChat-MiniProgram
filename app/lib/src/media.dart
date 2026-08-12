import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 图片选择入口。生产环境走系统相册；测试环境可注入固定图片，
/// 从而在不弹系统选择器的情况下覆盖每一个图片编辑按钮。
abstract final class RainbowImagePicker {
  static Future<String?> Function()? debugPickerOverride;

  static Future<String?> pick() async {
    final Future<String?> Function()? override = debugPickerOverride;
    if (override != null) return override();

    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      throw const FormatException('图片仍大于 2MB，请选择尺寸更小的图片');
    }
    final String mime = file.mimeType ?? _mimeFromName(file.name);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static String _mimeFromName(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

/// 首页轮播图没有对应业务实体，单独保存在本地首选项中。
/// 商品、仓库、头像图片仍保存到现有快照字段中。
final class RainbowMediaStore {
  RainbowMediaStore._();

  static final RainbowMediaStore instance = RainbowMediaStore._();
  static const String _prefix = 'rainbow_cats_home_media_';

  final Map<int, String> _homeImages = <int, String>{};
  bool _loaded = false;

  bool get loaded => _loaded;

  Future<void> initialize() async {
    if (_loaded) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      for (int index = 0; index < 3; index += 1) {
        final String? value = prefs.getString('$_prefix$index');
        if (value != null && value.isNotEmpty) _homeImages[index] = value;
      }
    } on Object catch (error) {
      debugPrint('RainbowMediaStore initialize failed: $error');
    }
    _loaded = true;
  }

  String? homeImageAt(int index) => _homeImages[index];

  Future<void> setHomeImage(int index, String value) async {
    if (index < 0 || index > 2 || value.isEmpty) return;
    _homeImages[index] = value;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$index', value);
    } on Object catch (error) {
      debugPrint('RainbowMediaStore save failed: $error');
    }
  }

  @visibleForTesting
  void setHomeImageForTest(int index, String value) {
    _homeImages[index] = value;
    _loaded = true;
  }

  @visibleForTesting
  void resetForTest() {
    _homeImages.clear();
    _loaded = false;
  }
}
