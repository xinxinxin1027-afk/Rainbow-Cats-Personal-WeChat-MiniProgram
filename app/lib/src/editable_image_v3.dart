import 'package:flutter/material.dart';

import 'media.dart';
import 'widgets_v2.dart' show GlassIconButton, OriginalImage;

/// 图片编辑交互的最终实现：图片成功替换后直接以画面变化作为反馈，
/// 不再弹出会遮挡小屏底部主操作按钮的成功 SnackBar；仅失败时提示。
class EditableImage extends StatelessWidget {
  const EditableImage({
    required this.onChanged,
    this.asset,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.enabled = true,
    this.semanticLabel = '编辑图片',
    this.editKey,
    super.key,
  });

  final String? asset;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool enabled;
  final String semanticLabel;
  final Key? editKey;
  final Future<void> Function(String value) onChanged;

  Future<void> _pick(BuildContext context) async {
    try {
      final String? value = await RainbowImagePicker.pick();
      if (value == null || value.isEmpty) return;
      await onChanged(value);
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('图片更新失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          OriginalImage(
            asset: asset,
            height: height,
            width: width,
            fit: fit,
            borderRadius: borderRadius,
          ),
          if (enabled)
            Positioned(
              right: 9,
              bottom: 9,
              child: Semantics(
                button: true,
                label: semanticLabel,
                child: GlassIconButton(
                  key: editKey,
                  tooltip: semanticLabel,
                  icon: Icons.edit_rounded,
                  size: 38,
                  iconSize: 18,
                  tint: Colors.white.withAlpha(136),
                  onPressed: () => _pick(context),
                ),
              ),
            ),
        ],
      );
}
