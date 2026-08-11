#!/usr/bin/env python3
from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"{label}: expected source block not found in {path}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


pages = Path("app/lib/src/pages.dart")
replace_once(
    pages,
    "import 'package:flutter/material.dart';\n",
    "import 'dart:async';\n\nimport 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n",
    "pages imports",
)

old_shell = '''class _RainbowShellState extends State<RainbowShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(store: widget.store, onNavigate: _setIndex),
      MissionListPage(store: widget.store),
      MarketPage(store: widget.store),
      AccountPage(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: RainbowBottomBar(
        index: _index,
        onChanged: widget.lockedIndex ? (_) {} : _setIndex,
      ),
    );
  }

  void _setIndex(int index) {
    if (!mounted || widget.lockedIndex) return;
    setState(() => _index = index);
  }
}
'''
new_shell = '''class _RainbowShellState extends State<RainbowShell> {
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
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: pages),
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
'''
replace_once(pages, old_shell, new_shell, "RainbowShell navigation")

# 主页面彻底移除小程序式顶部标题栏；二级页面仍保留正常返回标题栏。
root_top_bars = (
    "        RainbowTopBar(title: OriginalAssets.pageTitle('MainPage', OriginalAssets.tabLabelAt(0)), store: store),\n",
    "        RainbowTopBar(title: OriginalAssets.pageTitle('Mission', OriginalAssets.tabLabelAt(1)), store: widget.store),\n",
    "        RainbowTopBar(title: OriginalAssets.pageTitle('Market', OriginalAssets.tabLabelAt(2)), store: widget.store),\n",
    "        RainbowTopBar(title: OriginalAssets.pageTitle('Account', OriginalAssets.tabLabelAt(3)), store: widget.store),\n",
)
text = pages.read_text(encoding="utf-8")
for item in root_top_bars:
    if item not in text:
        raise SystemExit(f"root top bar not found: {item.strip()}")
    text = text.replace(item, "", 1)
pages.write_text(text, encoding="utf-8")

widgets = Path("app/lib/src/widgets.dart")
widget_text = widgets.read_text(encoding="utf-8")
start = widget_text.find("class RainbowTopBar extends StatelessWidget")
end = widget_text.find("class RainbowCard extends StatelessWidget")
if start < 0 or end <= start:
    raise SystemExit("unable to locate legacy top bar/capsule block")
new_top_bar = '''class RainbowTopBar extends StatelessWidget {
  const RainbowTopBar({
    required this.title,
    required this.store,
    required this.onBack,
    super.key,
  });

  final String title;
  final RainbowStore store;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: '$title，当前身份 ${store.currentUser.name}',
        child: ColoredBox(
          color: OriginalStyle.primary,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Positioned(
                    left: 4,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

'''
widgets.write_text(widget_text[:start] + new_top_bar + widget_text[end:], encoding="utf-8")

settings = Path("app/lib/src/settings_pages.dart")
settings_text = settings.read_text(encoding="utf-8")
count = settings_text.count("              showCapsule: false,\n")
if count != 3:
    raise SystemExit(f"expected 3 showCapsule arguments, found {count}")
settings.write_text(
    settings_text.replace("              showCapsule: false,\n", ""),
    encoding="utf-8",
)

print("UX_HOTFIX_V1=APPLIED")
