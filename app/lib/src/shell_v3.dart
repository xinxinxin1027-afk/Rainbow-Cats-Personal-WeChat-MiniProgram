import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design.dart';
import 'pages_v2.dart';
import 'store.dart';
import 'widgets.dart';

/// 最终双人主壳：保留四个主入口与 Android 返回历史，
/// 仅在仓库页提供“我是谁”的两人切换，不再暴露成员新增/删除管理。
class RainbowShell extends StatefulWidget {
  const RainbowShell({
    required this.store,
    this.initialIndex = 0,
    this.lockedIndex = false,
    super.key,
  });

  final RainbowStore store;
  final int initialIndex;
  final bool lockedIndex;

  @override
  State<RainbowShell> createState() => _RainbowShellState();
}

class _RainbowShellState extends State<RainbowShell> {
  static const MethodChannel _lifecycleChannel =
      MethodChannel('rainbow_cats/app_lifecycle');

  late int _index = widget.initialIndex;
  late final List<int> _tabHistory = <int>[widget.initialIndex];
  bool _handlingBack = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(store: widget.store, onNavigate: _setIndex),
      MissionListPage(store: widget.store),
      MarketPage(store: widget.store),
      AccountPage(store: widget.store),
    ];
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || _handlingBack) return;
        unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            SafeArea(
              bottom: false,
              child: IndexedStack(index: _index, children: pages),
            ),
            if (_index == 3 && !widget.lockedIndex)
              Positioned(
                top: 18,
                right: 14,
                child: SafeArea(
                  bottom: false,
                  child: _IdentitySwitchButton(
                    store: widget.store,
                    onChanged: () {
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: RainbowBottomBar(
          index: _index,
          onChanged: widget.lockedIndex ? (_) {} : _setIndex,
        ),
      ),
    );
  }

  void _setIndex(int index) {
    if (!mounted || widget.lockedIndex || index == _index) return;
    setState(() {
      _index = index;
      _tabHistory.remove(index);
      _tabHistory.add(index);
    });
  }

  Future<void> _handleBack() async {
    _handlingBack = true;
    try {
      if (_tabHistory.length > 1) {
        if (!mounted) return;
        setState(() {
          _tabHistory.removeLast();
          _index = _tabHistory.last;
        });
        return;
      }
      try {
        await _lifecycleChannel.invokeMethod<bool>('moveToBackground');
      } on MissingPluginException {
        await SystemNavigator.pop();
      }
    } finally {
      _handlingBack = false;
    }
  }
}

class _IdentitySwitchButton extends StatelessWidget {
  const _IdentitySwitchButton({
    required this.store,
    required this.onChanged,
  });

  final RainbowStore store;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => GlassSurface(
        radius: 20,
        blur: 20,
        shadow: false,
        tint: RainbowDesign.accentSoft,
        padding: EdgeInsets.zero,
        onTap: () => _showPicker(context),
        child: Semantics(
          button: true,
          label: '切换当前身份，当前 ${store.currentUser.name}',
          child: Container(
            key: const ValueKey<String>('identity-switch'),
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: RainbowDesign.accentDeep,
                ),
                const SizedBox(width: 5),
                Text(
                  store.currentUser.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: RainbowDesign.accentDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _showPicker(BuildContext context) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(36),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GlassSurface(
            radius: 30,
            blur: 30,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  '这台手机是谁在用？',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                const Text(
                  '只在你们两个人之间切换，不会新增成员。',
                  style: TextStyle(fontSize: 12, color: RainbowDesign.muted),
                ),
                const SizedBox(height: 14),
                ...store.users.take(2).map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RainbowCard(
                          onTap: () => Navigator.pop(sheetContext, user.id),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            key: ValueKey<String>('identity-user-${user.id}'),
                            children: <Widget>[
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: RainbowDesign.accentSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  user.id == store.currentUserId
                                      ? Icons.check_rounded
                                      : Icons.favorite_border_rounded,
                                  color: RainbowDesign.accentDeep,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (user.id == store.currentUserId)
                                const Text(
                                  '当前',
                                  style: TextStyle(
                                    color: RainbowDesign.muted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || selected == store.currentUserId) return;
    await store.switchUserTo(selected);
    onChanged();
  }
}
