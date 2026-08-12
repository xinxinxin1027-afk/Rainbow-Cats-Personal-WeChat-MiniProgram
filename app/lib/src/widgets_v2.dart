import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../generated/original_assets.dart';
import 'design.dart';
import 'media.dart';
import 'models.dart';

class LiquidBackground extends StatelessWidget {
  const LiquidBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: RainbowDesign.background,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RainbowDesign.warmBackdropGradient,
              ),
            ),
            const Positioned(
              top: -110,
              right: -85,
              child: _GlowBlob(
                size: 270,
                colors: <Color>[
                  Color(0x66FFD0DB),
                  Color(0x00FFD0DB),
                ],
              ),
            ),
            const Positioned(
              top: 260,
              left: -120,
              child: _GlowBlob(
                size: 300,
                colors: <Color>[
                  Color(0x4DCAE0C4),
                  Color(0x00CAE0C4),
                ],
              ),
            ),
            const Positioned(
              bottom: -130,
              right: -90,
              child: _GlowBlob(
                size: 330,
                colors: <Color>[
                  Color(0x3DECCBD4),
                  Color(0x00ECCBD4),
                ],
              ),
            ),
            child,
          ],
        ),
      );
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      );
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = RainbowDesign.radiusLarge,
    this.blur = 18,
    this.tint,
    this.shadow = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final double blur;
  final Color? tint;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final Color wash = tint ?? Colors.white;
    final Widget glass = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(wash.withAlpha(28), Colors.white.withAlpha(218)),
                Color.alphaBlend(wash.withAlpha(18), Colors.white.withAlpha(150)),
              ],
            ),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withAlpha(138), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              splashColor: RainbowDesign.accent.withAlpha(18),
              highlightColor: Colors.white.withAlpha(24),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow ? RainbowDesign.softShadow : const <BoxShadow>[],
      ),
      child: glass,
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 42,
    this.iconSize = 20,
    this.tint,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final Widget button = GlassSurface(
      radius: size / 2,
      blur: 16,
      shadow: false,
      tint: tint ?? Colors.white,
      padding: EdgeInsets.zero,
      onTap: onPressed,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: iconSize, color: RainbowDesign.text),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class RainbowTopBar extends StatelessWidget {
  const RainbowTopBar({
    required this.title,
    required this.store,
    required this.onBack,
    super.key,
  });

  final String title;
  final dynamic store;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Semantics(
            container: true,
            label: '$title，当前身份 ${store.currentUser.name}',
            child: GlassSurface(
              radius: 24,
              blur: 26,
              tint: RainbowDesign.accentSoft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GlassIconButton(
                        key: const ValueKey<String>('top-back'),
                        tooltip: '返回',
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: onBack,
                        size: 40,
                        iconSize: 18,
                        tint: Colors.white.withAlpha(82),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 52),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RainbowDesign.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class RainbowCard extends StatelessWidget {
  const RainbowCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GlassSurface(
        margin: margin,
        padding: padding,
        onTap: onTap,
        radius: RainbowDesign.radiusLarge,
        blur: 16,
        child: child,
      );
}

class FilledPinkButton extends StatelessWidget {
  const FilledPinkButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: RainbowDesign.fast,
        opacity: enabled ? 1 : .45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: enabled
                ? RainbowDesign.accentGradient
                : const LinearGradient(
                    colors: <Color>[Color(0xFFBEB8B5), Color(0xFFAFA9A6)],
                  ),
            boxShadow: enabled
                ? <BoxShadow>[
                    BoxShadow(
                      color: RainbowDesign.accentDeep.withAlpha(44),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withAlpha(150),
                      blurRadius: 1,
                      offset: const Offset(0, -1),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: 54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(icon ?? Icons.check_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 9),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class RainbowFloatingButton extends StatelessWidget {
  const RainbowFloatingButton({
    required this.onPressed,
    this.label = '添加',
    this.icon = Icons.add_rounded,
    super.key,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => GlassSurface(
        radius: 24,
        blur: 24,
        tint: RainbowDesign.accentSoft,
        padding: EdgeInsets.zero,
        onTap: onPressed,
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: RainbowDesign.accentDeep, size: 22),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: RainbowDesign.accentDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class CreditBadge extends StatelessWidget {
  const CreditBadge(this.credit, {this.compact = false, super.key});

  final int credit;
  final bool compact;

  @override
  Widget build(BuildContext context) => GlassSurface(
        radius: 999,
        blur: 12,
        shadow: false,
        tint: RainbowDesign.accentSoft,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 12,
          vertical: compact ? 5 : 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.favorite_rounded,
              size: compact ? 14 : 16,
              color: RainbowDesign.accentDeep,
            ),
            const SizedBox(width: 4),
            Text(
              '$credit',
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w700,
                color: RainbowDesign.accentDeep,
              ),
            ),
          ],
        ),
      );
}

class OriginalImage extends StatelessWidget {
  const OriginalImage({
    this.asset,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    super.key,
  });

  final String? asset;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFE6EC), Color(0xFFF0EEE6)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.pets_rounded,
          color: RainbowDesign.accentDeep,
          size: 42,
        ),
      ),
    );

    Widget image = fallback;
    final String? source = asset;
    if (source != null && source.isNotEmpty) {
      if (source.startsWith('data:image/')) {
        try {
          final int comma = source.indexOf(',');
          final List<int> bytes = base64Decode(source.substring(comma + 1));
          image = Image.memory(
            Uint8List.fromList(bytes),
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (_, __, ___) => fallback,
          );
        } on Object {
          image = fallback;
        }
      } else if (source.startsWith('http://') || source.startsWith('https://')) {
        image = Image.network(
          source,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } else if (source.startsWith('file://') || source.startsWith('/')) {
        final String path =
            source.startsWith('file://') ? source.substring(7) : source;
        image = Image.file(
          File(path),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } else {
        image = Image.asset(
          source,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    }

    return ClipRRect(
      borderRadius:
          borderRadius ?? BorderRadius.circular(RainbowDesign.radiusMedium),
      child: SizedBox(height: height, width: width, child: image),
    );
  }
}

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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('图片已更新')));
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

class EmptyState extends StatelessWidget {
  const EmptyState({required this.label, this.icon = Icons.pets, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GlassSurface(
                radius: 30,
                shadow: false,
                tint: RainbowDesign.accentSoft,
                padding: const EdgeInsets.all(14),
                child: Icon(icon, size: 34, color: RainbowDesign.accentDeep),
              ),
              const SizedBox(height: 14),
              Text(label, style: const TextStyle(color: RainbowDesign.muted)),
            ],
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.count, super.key});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(3, 16, 3, 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: RainbowDesign.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -.15,
              ),
            ),
            if (count != null) ...<Widget>[
              const SizedBox(width: 7),
              Text('$count', style: const TextStyle(color: RainbowDesign.muted)),
            ],
          ],
        ),
      );
}

class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class SwipeActionCell extends StatefulWidget {
  const SwipeActionCell({required this.child, required this.actions, super.key});

  final Widget child;
  final List<SwipeAction> actions;

  @override
  State<SwipeActionCell> createState() => _SwipeActionCellState();
}

class _SwipeActionCellState extends State<SwipeActionCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RainbowDesign.fast,
  )..addListener(() => setState(() {}));
  double _dragStart = 0;

  double get _maxReveal => widget.actions.length * 76.0;
  double get _offset => -_maxReveal * _controller.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(RainbowDesign.radiusLarge),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _dragStart = _controller.value,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            if (_maxReveal == 0) return;
            _controller.value =
                (_dragStart - details.primaryDelta! / _maxReveal)
                    .clamp(0.0, 1.0)
                    .toDouble();
            _dragStart = _controller.value;
          },
          onHorizontalDragEnd: (DragEndDetails details) {
            final double velocity = details.primaryVelocity ?? 0;
            if (velocity < -250 || _controller.value > .45) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _maxReveal,
                    child: Row(
                      children: widget.actions
                          .map(
                            (SwipeAction action) => SizedBox(
                              width: 76,
                              child: Material(
                                color: action.color,
                                child: InkWell(
                                  onTap: () {
                                    _controller.reverse();
                                    action.onTap();
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(action.icon,
                                          color: Colors.white, size: 21),
                                      const SizedBox(height: 4),
                                      Text(
                                        action.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(_offset, 0),
                child: widget.child,
              ),
            ],
          ),
        ),
      );
}

class RainbowBottomBar extends StatelessWidget {
  const RainbowBottomBar({
    required this.index,
    required this.onChanged,
    super.key,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const List<IconData> _fallback = <IconData>[
    Icons.home_rounded,
    Icons.check_circle_rounded,
    Icons.storefront_rounded,
    Icons.inventory_2_rounded,
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: GlassSurface(
          radius: 28,
          blur: 28,
          padding: const EdgeInsets.all(6),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 55,
              child: Row(
                children: List<Widget>.generate(4, (int itemIndex) {
                  final bool selected = index == itemIndex;
                  final String? asset = selected
                      ? OriginalAssets.selectedTabAt(itemIndex)
                      : OriginalAssets.normalTabAt(itemIndex);
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: OriginalAssets.tabLabelAt(itemIndex),
                      child: InkWell(
                        key: ValueKey<String>('bottom-tab-$itemIndex'),
                        onTap: () => onChanged(itemIndex),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: RainbowDesign.normal,
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: selected
                                ? RainbowDesign.accentSoft.withAlpha(170)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              if (asset == null)
                                Icon(
                                  _fallback[itemIndex],
                                  size: 22,
                                  color: selected
                                      ? RainbowDesign.accentDeep
                                      : RainbowDesign.muted,
                                )
                              else
                                Image.asset(
                                  asset,
                                  width: 23,
                                  height: 23,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _fallback[itemIndex],
                                    size: 22,
                                    color: selected
                                        ? RainbowDesign.accentDeep
                                        : RainbowDesign.muted,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                OriginalAssets.tabLabelAt(itemIndex),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: selected
                                      ? RainbowDesign.accentDeep
                                      : RainbowDesign.muted,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
}

Future<void> showResult(
  BuildContext context,
  Future<ActionResult> action,
) async {
  final ActionResult result = await action;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(result.message)));
}
