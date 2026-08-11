import 'package:flutter/material.dart';

import '../generated/original_assets.dart';
import '../generated/original_style.dart';
import 'models.dart';
import 'store.dart';

class RainbowTopBar extends StatelessWidget {
  const RainbowTopBar({
    required this.title,
    required this.store,
    this.onBack,
    this.showCapsule = true,
    super.key,
  });

  final String title;
  final RainbowStore store;
  final VoidCallback? onBack;
  final bool showCapsule;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: OriginalStyle.primary,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  left: 4,
                  child: SizedBox(
                    width: 92,
                    child: onBack == null
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: '返回',
                              onPressed: onBack,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 100),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .3,
                    ),
                  ),
                ),
                if (showCapsule)
                  Positioned(
                    right: 10,
                    child: WeChatCapsule(store: store),
                  ),
              ],
            ),
          ),
        ),
      );
}

class WeChatCapsule extends StatelessWidget {
  const WeChatCapsule({required this.store, super.key});

  final RainbowStore store;

  Future<void> _open(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .78,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '当前身份：${store.currentUser.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: store.users
                      .map(
                        (UserProfile user) => ChoiceChip(
                          selected: user.id == store.currentUserId,
                          label: Text(user.name),
                          avatar: user.id == store.currentUserId
                              ? const Icon(Icons.check_rounded, size: 16)
                              : null,
                          onSelected: user.id == store.currentUserId
                              ? null
                              : (_) async {
                                  Navigator.pop(sheetContext);
                                  await store.switchUserTo(user.id);
                                },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/members');
                  },
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('成员管理'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/ledger');
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('积分明细'),
                ),
                const SizedBox(height: 8),
                FilledPinkButton(
                  label: '设置与 WebDAV',
                  icon: Icons.settings_outlined,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final bool? confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext dialogContext) => AlertDialog(
                        title: const Text('重置样例数据'),
                        content: const Text(
                          '任务、商品、积分和仓库将恢复到初始状态；连接设置会保留。',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text('重置'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) await store.reset();
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('重置样例数据'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '更多，当前身份 ${store.currentUser.name}',
        child: Material(
          color: Colors.white.withAlpha(245),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 84,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Icon(Icons.more_horiz_rounded, size: 20),
                  SizedBox(
                    height: 18,
                    child: VerticalDivider(width: 1, thickness: .6),
                  ),
                  Icon(Icons.radio_button_unchecked_rounded, size: 17),
                ],
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
  Widget build(BuildContext context) => Container(
        margin: margin,
        decoration: BoxDecoration(
          color: OriginalStyle.surface,
          borderRadius: BorderRadius.circular(OriginalStyle.cardRadius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(OriginalStyle.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
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
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon ?? Icons.check_rounded, size: 19),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: OriginalStyle.primary,
            disabledBackgroundColor: OriginalStyle.muted.withAlpha(80),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OriginalStyle.cardRadius),
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
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 12,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: OriginalStyle.primary.withAlpha(28),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.favorite_rounded,
              size: compact ? 14 : 16,
              color: OriginalStyle.primaryDark,
            ),
            const SizedBox(width: 4),
            Text(
              '$credit',
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w700,
                color: OriginalStyle.primaryDark,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            OriginalStyle.primary.withAlpha(70),
            OriginalStyle.primary.withAlpha(20),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.pets_rounded,
          color: OriginalStyle.primaryDark,
          size: 42,
        ),
      ),
    );
    final Widget image = asset == null || asset!.isEmpty
        ? fallback
        : Image.asset(
            asset!,
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (_, __, ___) => fallback,
          );
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: SizedBox(height: height, width: width, child: image),
    );
  }
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
              Icon(icon, size: 52, color: OriginalStyle.primary.withAlpha(120)),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(color: OriginalStyle.muted)),
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
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 9),
        child: Row(
          children: <Widget>[
            Container(
              width: 4,
              height: 17,
              decoration: BoxDecoration(
                color: OriginalStyle.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (count != null) ...<Widget>[
              const SizedBox(width: 6),
              Text('$count', style: const TextStyle(color: OriginalStyle.muted)),
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
  const SwipeActionCell({
    required this.child,
    required this.actions,
    super.key,
  });

  final Widget child;
  final List<SwipeAction> actions;

  @override
  State<SwipeActionCell> createState() => _SwipeActionCellState();
}

class _SwipeActionCellState extends State<SwipeActionCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..addListener(() => setState(() {}));
  double _dragStart = 0;

  double get _maxReveal => widget.actions.length * 72.0;
  double get _offset => -_maxReveal * _controller.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(OriginalStyle.cardRadius),
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
                              width: 72,
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
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List<Widget>.generate(4, (int itemIndex) {
                final bool selected = index == itemIndex;
                final String? asset = selected
                    ? OriginalAssets.selectedTabAt(itemIndex)
                    : OriginalAssets.normalTabAt(itemIndex);
                return Expanded(
                  child: InkWell(
                    key: ValueKey<String>('bottom-tab-$itemIndex'),
                    onTap: () => onChanged(itemIndex),
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: OriginalAssets.tabLabelAt(itemIndex),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (asset == null)
                            Icon(
                              _fallback[itemIndex],
                              size: 24,
                              color: selected
                                  ? OriginalStyle.primaryDark
                                  : OriginalStyle.muted,
                            )
                          else
                            Image.asset(
                              asset,
                              width: 25,
                              height: 25,
                              errorBuilder: (_, __, ___) => Icon(
                                _fallback[itemIndex],
                                size: 24,
                                color: selected
                                    ? OriginalStyle.primaryDark
                                    : OriginalStyle.muted,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            OriginalAssets.tabLabelAt(itemIndex),
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? OriginalStyle.primaryDark
                                  : OriginalStyle.muted,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      );
}

Future<void> showResult(BuildContext context, Future<ActionResult> action) async {
  final ActionResult result = await action;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(result.message)));
}
