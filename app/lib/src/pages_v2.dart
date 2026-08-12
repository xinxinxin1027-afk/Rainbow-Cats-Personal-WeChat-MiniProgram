import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/original_assets.dart';
import 'design.dart';
import 'media.dart';
import 'models.dart';
import 'settings_pages.dart';
import 'store.dart';
import 'widgets.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({required this.store, required this.onNavigate, super.key});

  final RainbowStore store;
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController(viewportFraction: .93);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RainbowStore store = widget.store;
    final int openMissions =
        store.missions.where((Mission item) => !item.completed).length;
    final int availableRewards =
        store.rewards.where((Reward item) => item.available).length;
    final int unusedItems = store.currentInventory
        .where((InventoryItem item) => !item.used)
        .length;

    return ListView(
      key: const ValueKey<String>('home-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      children: <Widget>[
        RainbowCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              _EditableAvatar(
                user: store.currentUser,
                store: store,
                size: 62,
                editKey: ValueKey<String>('edit-avatar-${store.currentUser.id}'),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '你好，${store.currentUser.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: RainbowDesign.accentDeep,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '今天也和 ${store.partner.name} 好好相处',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: RainbowDesign.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CreditBadge(store.currentUser.credit),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 202,
          child: PageView.builder(
            key: const ValueKey<String>('home-carousel'),
            controller: _controller,
            itemCount: 3,
            onPageChanged: (int value) => setState(() => _page = value),
            itemBuilder: (BuildContext context, int index) {
              final String? asset =
                  RainbowMediaStore.instance.homeImageAt(index) ??
                      OriginalAssets.homeAt(index);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      EditableImage(
                        asset: asset,
                        borderRadius: BorderRadius.circular(28),
                        semanticLabel: '编辑首页图片 ${index + 1}',
                        editKey: ValueKey<String>('edit-home-image-$index'),
                        onChanged: (String value) async {
                          await RainbowMediaStore.instance
                              .setHomeImage(index, value);
                          if (mounted) setState(() {});
                        },
                      ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Colors.black.withAlpha(84),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 19,
                        right: 62,
                        bottom: 18,
                        child: Text(
                          '把喜欢的日常，慢慢收集起来。',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            shadows: <Shadow>[
                              Shadow(color: Color(0x66000000), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(3, (int index) {
            final bool active = index == _page;
            return AnimatedContainer(
              duration: RainbowDesign.normal,
              curve: Curves.easeOutCubic,
              width: active ? 22 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active
                    ? RainbowDesign.accent
                    : RainbowDesign.accentSoft,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SectionTitle('我们的日常'),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                value: openMissions,
                label: '待完成任务',
                onTap: () => widget.onNavigate(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.storefront_outlined,
                value: availableRewards,
                label: '可兑换商品',
                onTap: () => widget.onNavigate(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_outlined,
                value: unusedItems,
                label: '仓库物品',
                onTap: () => widget.onNavigate(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        RainbowCard(
          onTap: () => widget.onNavigate(1),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: RainbowDesign.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: RainbowDesign.accentDeep,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '从一个小任务开始',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '完成彼此发布的任务，把日常变成两个人的小仪式。',
                      style: TextStyle(
                        color: RainbowDesign.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: RainbowDesign.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.user,
    required this.store,
    required this.size,
    required this.editKey,
  });

  final UserProfile user;
  final RainbowStore store;
  final double size;
  final Key editKey;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: EditableImage(
          asset: user.avatarAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(size / 2),
          editKey: editKey,
          semanticLabel: '编辑${user.name}头像',
          onChanged: (String value) async {
            user
              ..avatarAsset = value
              ..updatedAt = DateTime.now();
            await store.updateSettings(store.settings);
          },
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RainbowCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Column(
          children: <Widget>[
            Icon(icon, color: RainbowDesign.accentDeep, size: 24),
            const SizedBox(height: 7),
            Text(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.8, color: RainbowDesign.muted),
            ),
          ],
        ),
      );
}

class MissionListPage extends StatefulWidget {
  const MissionListPage({required this.store, super.key});

  final RainbowStore store;

  @override
  State<MissionListPage> createState() => _MissionListPageState();
}

class _MissionListPageState extends State<MissionListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<Mission> filtered = widget.store.missions.where((Mission item) {
      final String query = _query.trim().toLowerCase();
      return query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList()
      ..sort((Mission a, Mission b) {
        if (a.starred != b.starred) return a.starred ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    final List<Mission> open =
        filtered.where((Mission item) => !item.completed).toList();
    final List<Mission> done =
        filtered.where((Mission item) => item.completed).toList();

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
          children: <Widget>[
            const _PageIntro(
              title: '任务',
              subtitle: '给彼此留一点小期待',
              icon: Icons.favorite_border_rounded,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('mission-search'),
              onChanged: (String value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: '搜索任务',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
            SectionTitle('未完成', count: open.length),
            if (open.isEmpty)
              const EmptyState(label: '暂时没有待完成任务')
            else
              ...open.map(
                (Mission item) => _MissionTile(
                  mission: item,
                  store: widget.store,
                ),
              ),
            SectionTitle('已完成', count: done.length),
            if (done.isEmpty)
              const EmptyState(label: '还没有完成记录')
            else
              ...done.map(
                (Mission item) => _MissionTile(
                  mission: item,
                  store: widget.store,
                ),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: RainbowFloatingButton(
              key: const ValueKey<String>('add-mission'),
              label: '新任务',
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MissionAddPage(store: widget.store),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
        child: Row(
          children: <Widget>[
            GlassSurface(
              radius: 18,
              blur: 16,
              shadow: false,
              tint: RainbowDesign.accentSoft,
              padding: const EdgeInsets.all(11),
              child: Icon(icon, size: 23, color: RainbowDesign.accentDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: RainbowDesign.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission, required this.store});

  final Mission mission;
  final RainbowStore store;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SwipeActionCell(
          actions: <SwipeAction>[
            SwipeAction(
              label: mission.starred ? '取消' : '星标',
              icon: mission.starred ? Icons.star_outline : Icons.star_rounded,
              color: RainbowDesign.amber,
              onTap: () => showResult(context, store.toggleMissionStar(mission.id)),
            ),
            if (mission.ownerId == store.currentUserId)
              SwipeAction(
                label: '删除',
                icon: Icons.delete_outline_rounded,
                color: RainbowDesign.danger,
                onTap: () async {
                  final bool confirmed = await _confirmDelete(
                    context,
                    title: '删除任务',
                    message: '确定删除“${mission.title}”吗？',
                  );
                  if (confirmed && context.mounted) {
                    await showResult(context, store.deleteMission(mission.id));
                  }
                },
              ),
          ],
          child: RainbowCard(
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MissionDetailPage(
                  store: store,
                  missionId: mission.id,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: mission.completed
                        ? RainbowDesign.sageSoft
                        : RainbowDesign.accentSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    mission.completed
                        ? Icons.check_rounded
                        : Icons.favorite_border_rounded,
                    color: mission.completed
                        ? const Color(0xFF607D5C)
                        : RainbowDesign.accentDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              mission.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: mission.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (mission.starred)
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: RainbowDesign.amber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        mission.description.isEmpty ? '暂无说明' : mission.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RainbowDesign.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: <Widget>[
                          Text(
                            store.userById(mission.ownerId).name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: RainbowDesign.muted,
                            ),
                          ),
                          const Spacer(),
                          CreditBadge(mission.credit, compact: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class MissionAddPage extends StatefulWidget {
  const MissionAddPage({required this.store, this.missionId, super.key});

  final RainbowStore store;
  final String? missionId;

  @override
  State<MissionAddPage> createState() => _MissionAddPageState();
}

class _MissionAddPageState extends State<MissionAddPage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  double _credit = 20;
  bool _saving = false;

  Mission? get _editing => widget.missionId == null
      ? null
      : widget.store.missionById(widget.missionId!);

  @override
  void initState() {
    super.initState();
    final Mission? mission = _editing;
    if (mission != null) {
      _title.text = mission.title;
      _description.text = mission.description;
      _credit = mission.credit.toDouble().clamp(1, 100).toDouble();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = _editing != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          RainbowTopBar(
            title: editing ? '编辑任务' : '发布新任务',
            store: widget.store,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
              children: <Widget>[
                const SectionTitle('任务内容'),
                TextField(
                  key: const ValueKey<String>('mission-title'),
                  controller: _title,
                  maxLength: 12,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: '输入任务名称'),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey<String>('mission-description'),
                  controller: _description,
                  maxLines: 5,
                  maxLength: 100,
                  decoration: const InputDecoration(hintText: '补充一点说明'),
                ),
                const SectionTitle('任务积分'),
                RainbowCard(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('完成后获得'),
                          const Spacer(),
                          CreditBadge(_credit.round()),
                        ],
                      ),
                      Slider(
                        key: const ValueKey<String>('mission-credit-slider'),
                        value: _credit,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: _credit.round().toString(),
                        onChanged: (double value) => setState(() => _credit = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledPinkButton(
                  key: const ValueKey<String>('save-mission'),
                  label: _saving
                      ? '正在保存…'
                      : editing
                          ? '保存任务'
                          : '发布任务',
                  icon: editing ? Icons.save_outlined : Icons.send_rounded,
                  enabled: !_saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final Mission? mission = _editing;
    final ActionResult result = mission == null
        ? await widget.store.addMission(
            title: _title.text,
            description: _description.text,
            credit: _credit.round(),
          )
        : await widget.store.updateMission(
            id: mission.id,
            title: _title.text,
            description: _description.text,
            credit: _credit.round(),
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class MissionDetailPage extends StatelessWidget {
  const MissionDetailPage({
    required this.store,
    required this.missionId,
    super.key,
  });

  final RainbowStore store;
  final String missionId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (BuildContext context, _) {
          final Mission? mission = store.missionById(missionId);
          if (mission == null) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: <Widget>[
                  RainbowTopBar(
                    title: '任务详情',
                    store: store,
                    onBack: () => Navigator.pop(context),
                  ),
                  const Expanded(child: EmptyState(label: '任务不存在')),
                ],
              ),
            );
          }
          final bool canComplete =
              !mission.completed && mission.ownerId != store.currentUserId;
          final bool canEdit =
              !mission.completed && mission.ownerId == store.currentUserId;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: <Widget>[
                RainbowTopBar(
                  title: '任务详情',
                  store: store,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    children: <Widget>[
                      RainbowCard(
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(RainbowDesign.radiusLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Container(
                                height: 132,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      RainbowDesign.accent.withAlpha(205),
                                      RainbowDesign.accentSoft,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  mission.completed
                                      ? Icons.check_circle_rounded
                                      : Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 56,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            mission.title,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        if (mission.starred)
                                          const Icon(
                                            Icons.star_rounded,
                                            color: RainbowDesign.amber,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      mission.description.isEmpty
                                          ? '暂无说明'
                                          : mission.description,
                                      style: const TextStyle(height: 1.6),
                                    ),
                                    const SizedBox(height: 18),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    _DetailRow(
                                      label: '发布者',
                                      value: store.userById(mission.ownerId).name,
                                    ),
                                    _DetailRow(
                                      label: '积分',
                                      trailing: CreditBadge(mission.credit),
                                    ),
                                    _DetailRow(
                                      label: '状态',
                                      value: mission.completed ? '已完成' : '未完成',
                                    ),
                                    _DetailRow(
                                      label: '创建时间',
                                      value: _formatDate(mission.createdAt),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledPinkButton(
                        key: const ValueKey<String>('complete-mission'),
                        label: mission.completed
                            ? '任务已完成'
                            : canComplete
                                ? '完成任务'
                                : '等待对方完成',
                        icon: mission.completed
                            ? Icons.check_circle_rounded
                            : Icons.favorite_rounded,
                        enabled: canComplete,
                        onPressed: () => showResult(
                          context,
                          store.completeMission(mission.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey<String>('star-mission'),
                              onPressed: () => showResult(
                                context,
                                store.toggleMissionStar(mission.id),
                              ),
                              icon: Icon(
                                mission.starred
                                    ? Icons.star_outline_rounded
                                    : Icons.star_rounded,
                              ),
                              label: Text(mission.starred ? '取消星标' : '星标'),
                            ),
                          ),
                          if (canEdit) ...<Widget>[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const ValueKey<String>('edit-mission'),
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => MissionAddPage(
                                      store: store,
                                      missionId: mission.id,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('编辑'),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (mission.ownerId == store.currentUserId) ...<Widget>[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          key: const ValueKey<String>('delete-mission'),
                          style: TextButton.styleFrom(
                            foregroundColor: RainbowDesign.danger,
                          ),
                          onPressed: () => _delete(context, mission),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('删除任务'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Future<void> _delete(BuildContext context, Mission mission) async {
    final bool confirmed = await _confirmDelete(
      context,
      title: '删除任务',
      message: '确定删除“${mission.title}”吗？',
    );
    if (!confirmed) return;
    final ActionResult result = await store.deleteMission(mission.id);
    if (!context.mounted) return;
    if (result.ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class MarketPage extends StatefulWidget {
  const MarketPage({required this.store, super.key});

  final RainbowStore store;

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<Reward> rewards = widget.store.rewards.where((Reward item) {
      final String query = _query.trim().toLowerCase();
      return query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList()
      ..sort((Reward a, Reward b) {
        if (a.starred != b.starred) return a.starred ? -1 : 1;
        if (a.available != b.available) return a.available ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
          children: <Widget>[
            const _PageIntro(
              title: '商城',
              subtitle: '把想为对方做的事，变成一张兑换券',
              icon: Icons.storefront_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const ValueKey<String>('market-search'),
                    onChanged: (String value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: '搜索商品',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CreditBadge(widget.store.currentUser.credit),
              ],
            ),
            SectionTitle('全部商品', count: rewards.length),
            if (rewards.isEmpty)
              const EmptyState(label: '暂时没有商品')
            else
              ...rewards.map(
                (Reward item) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: SwipeActionCell(
                    actions: <SwipeAction>[
                      SwipeAction(
                        label: item.starred ? '取消' : '星标',
                        icon: item.starred
                            ? Icons.star_outline_rounded
                            : Icons.star_rounded,
                        color: RainbowDesign.amber,
                        onTap: () => showResult(
                          context,
                          widget.store.toggleRewardStar(item.id),
                        ),
                      ),
                      if (item.ownerId == widget.store.currentUserId)
                        SwipeAction(
                          label: '删除',
                          icon: Icons.delete_outline_rounded,
                          color: RainbowDesign.danger,
                          onTap: () async {
                            final bool confirmed = await _confirmDelete(
                              context,
                              title: '删除商品',
                              message: '确定删除“${item.title}”吗？',
                            );
                            if (confirmed && context.mounted) {
                              await showResult(
                                context,
                                widget.store.deleteReward(item.id),
                              );
                            }
                          },
                        ),
                    ],
                    child: _RewardTile(
                      reward: item,
                      store: widget.store,
                      refresh: () => setState(() {}),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: RainbowFloatingButton(
              key: const ValueKey<String>('add-reward'),
              label: '新商品',
              icon: Icons.add_business_rounded,
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MarketAddPage(store: widget.store),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.reward,
    required this.store,
    required this.refresh,
  });

  final Reward reward;
  final RainbowStore store;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context) => RainbowCard(
        padding: EdgeInsets.zero,
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => MarketDetailPage(
              store: store,
              rewardId: reward.id,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RainbowDesign.radiusLarge),
          child: SizedBox(
            height: 126,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 126,
                  height: 126,
                  child: EditableImage(
                    asset: reward.imageAsset,
                    width: 126,
                    height: 126,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(RainbowDesign.radiusLarge),
                      bottomLeft: Radius.circular(RainbowDesign.radiusLarge),
                    ),
                    editKey: ValueKey<String>('edit-reward-list-${reward.id}'),
                    semanticLabel: '编辑${reward.title}图片',
                    onChanged: (String value) async {
                      reward
                        ..imageAsset = value
                        ..updatedAt = DateTime.now();
                      await store.updateSettings(store.settings);
                      refresh();
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                reward.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (reward.starred)
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: RainbowDesign.amber,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            reward.description.isEmpty ? '暂无说明' : reward.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: RainbowDesign.muted,
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            if (!reward.available)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: RainbowDesign.panel,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '已兑换',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: RainbowDesign.muted,
                                  ),
                                ),
                              )
                            else
                              Text(
                                store.userById(reward.ownerId).name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: RainbowDesign.muted,
                                ),
                              ),
                            const Spacer(),
                            CreditBadge(reward.cost, compact: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class MarketAddPage extends StatefulWidget {
  const MarketAddPage({required this.store, this.rewardId, super.key});

  final RainbowStore store;
  final String? rewardId;

  @override
  State<MarketAddPage> createState() => _MarketAddPageState();
}

class _MarketAddPageState extends State<MarketAddPage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  double _cost = 30;
  bool _saving = false;
  String? _imageAsset;

  Reward? get _editing => widget.rewardId == null
      ? null
      : widget.store.rewardById(widget.rewardId!);

  @override
  void initState() {
    super.initState();
    final Reward? reward = _editing;
    if (reward != null) {
      _title.text = reward.title;
      _description.text = reward.description;
      _cost = reward.cost.toDouble().clamp(1, 100).toDouble();
      _imageAsset = reward.imageAsset;
    } else {
      _imageAsset = OriginalAssets.homeAt(widget.store.rewards.length);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = _editing != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          RainbowTopBar(
            title: editing ? '编辑商品' : '添加新商品',
            store: widget.store,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: <Widget>[
                SizedBox(
                  height: 190,
                  child: EditableImage(
                    asset: _imageAsset,
                    height: 190,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(28),
                    editKey: const ValueKey<String>('edit-market-form-image'),
                    semanticLabel: '编辑商品图片',
                    onChanged: (String value) async {
                      setState(() => _imageAsset = value);
                    },
                  ),
                ),
                const SectionTitle('商品内容'),
                TextField(
                  key: const ValueKey<String>('reward-title'),
                  controller: _title,
                  maxLength: 12,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: '输入商品名称'),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey<String>('reward-description'),
                  controller: _description,
                  maxLines: 5,
                  maxLength: 100,
                  decoration: const InputDecoration(hintText: '说明如何兑换或使用'),
                ),
                const SectionTitle('兑换价格'),
                RainbowCard(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('需要积分'),
                          const Spacer(),
                          CreditBadge(_cost.round()),
                        ],
                      ),
                      Slider(
                        key: const ValueKey<String>('reward-cost-slider'),
                        value: _cost,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: _cost.round().toString(),
                        onChanged: (double value) => setState(() => _cost = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledPinkButton(
                  key: const ValueKey<String>('save-reward'),
                  label: _saving
                      ? '正在保存…'
                      : editing
                          ? '保存商品'
                          : '上架商品',
                  icon: editing ? Icons.save_outlined : Icons.add_business_rounded,
                  enabled: !_saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final Reward? reward = _editing;
    final ActionResult result = reward == null
        ? await widget.store.addReward(
            title: _title.text,
            description: _description.text,
            cost: _cost.round(),
          )
        : await widget.store.updateReward(
            id: reward.id,
            title: _title.text,
            description: _description.text,
            cost: _cost.round(),
          );
    if (result.ok && _imageAsset != null && _imageAsset!.isNotEmpty) {
      final Reward? target = reward ?? widget.store.rewards.firstOrNull;
      if (target != null) {
        target
          ..imageAsset = _imageAsset
          ..updatedAt = DateTime.now();
        await widget.store.updateSettings(widget.store.settings);
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class MarketDetailPage extends StatelessWidget {
  const MarketDetailPage({
    required this.store,
    required this.rewardId,
    super.key,
  });

  final RainbowStore store;
  final String rewardId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (BuildContext context, _) {
          final Reward? reward = store.rewardById(rewardId);
          if (reward == null) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: <Widget>[
                  RainbowTopBar(
                    title: '商品详情',
                    store: store,
                    onBack: () => Navigator.pop(context),
                  ),
                  const Expanded(child: EmptyState(label: '商品不存在')),
                ],
              ),
            );
          }
          final bool isOwner = reward.ownerId == store.currentUserId;
          final bool canBuy = reward.available &&
              !isOwner &&
              store.currentUser.credit >= reward.cost;
          final String buttonLabel = !reward.available
              ? '商品已兑换'
              : isOwner
                  ? '这是你发布的商品'
                  : store.currentUser.credit < reward.cost
                      ? '积分不足'
                      : '立即兑换';
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: <Widget>[
                RainbowTopBar(
                  title: '商品详情',
                  store: store,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    children: <Widget>[
                      RainbowCard(
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(RainbowDesign.radiusLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SizedBox(
                                height: 238,
                                child: EditableImage(
                                  asset: reward.imageAsset,
                                  height: 238,
                                  width: double.infinity,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(RainbowDesign.radiusLarge),
                                    topRight: Radius.circular(RainbowDesign.radiusLarge),
                                  ),
                                  editKey: ValueKey<String>(
                                    'edit-reward-detail-${reward.id}',
                                  ),
                                  semanticLabel: '编辑${reward.title}图片',
                                  onChanged: (String value) async {
                                    reward
                                      ..imageAsset = value
                                      ..updatedAt = DateTime.now();
                                    await store.updateSettings(store.settings);
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            reward.title,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        if (reward.starred)
                                          const Icon(
                                            Icons.star_rounded,
                                            color: RainbowDesign.amber,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      reward.description.isEmpty
                                          ? '暂无说明'
                                          : reward.description,
                                      style: const TextStyle(height: 1.6),
                                    ),
                                    const SizedBox(height: 18),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    _DetailRow(
                                      label: '发布者',
                                      value: store.userById(reward.ownerId).name,
                                    ),
                                    _DetailRow(
                                      label: '价格',
                                      trailing: CreditBadge(reward.cost),
                                    ),
                                    _DetailRow(
                                      label: '状态',
                                      value: reward.available ? '可兑换' : '已兑换',
                                    ),
                                    _DetailRow(
                                      label: '创建时间',
                                      value: _formatDate(reward.createdAt),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledPinkButton(
                        key: const ValueKey<String>('buy-reward'),
                        label: buttonLabel,
                        icon: Icons.shopping_bag_rounded,
                        enabled: canBuy,
                        onPressed: () => showResult(
                          context,
                          store.buyReward(reward.id),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey<String>('star-reward'),
                              onPressed: () => showResult(
                                context,
                                store.toggleRewardStar(reward.id),
                              ),
                              icon: Icon(
                                reward.starred
                                    ? Icons.star_outline_rounded
                                    : Icons.star_rounded,
                              ),
                              label: Text(reward.starred ? '取消星标' : '星标'),
                            ),
                          ),
                          if (isOwner && reward.available) ...<Widget>[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const ValueKey<String>('edit-reward'),
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => MarketAddPage(
                                      store: store,
                                      rewardId: reward.id,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('编辑'),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isOwner) ...<Widget>[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          key: const ValueKey<String>('delete-reward'),
                          style: TextButton.styleFrom(
                            foregroundColor: RainbowDesign.danger,
                          ),
                          onPressed: () => _delete(context, reward),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('删除商品'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Future<void> _delete(BuildContext context, Reward reward) async {
    final bool confirmed = await _confirmDelete(
      context,
      title: '删除商品',
      message: '确定删除“${reward.title}”吗？',
    );
    if (!confirmed) return;
    final ActionResult result = await store.deleteReward(reward.id);
    if (!context.mounted) return;
    if (result.ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({required this.store, super.key});

  final RainbowStore store;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _showUsed = false;

  @override
  Widget build(BuildContext context) {
    final List<InventoryItem> items = widget.store.currentInventory
        .where((InventoryItem item) => item.used == _showUsed)
        .toList();
    final List<UserProfile> pair = widget.store.users.take(2).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: <Widget>[
        const _PageIntro(
          title: '仓库',
          subtitle: '两个人的小收藏与兑换记录',
          icon: Icons.inventory_2_rounded,
        ),
        const SizedBox(height: 12),
        RainbowCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 112,
                height: 70,
                child: Stack(
                  children: <Widget>[
                    if (pair.isNotEmpty)
                      Positioned(
                        left: 0,
                        top: 4,
                        child: _EditableAvatar(
                          user: pair[0],
                          store: widget.store,
                          size: 60,
                          editKey: ValueKey<String>('edit-avatar-${pair[0].id}'),
                        ),
                      ),
                    if (pair.length > 1)
                      Positioned(
                        left: 46,
                        top: 4,
                        child: _EditableAvatar(
                          user: pair[1],
                          store: widget.store,
                          size: 60,
                          editKey: ValueKey<String>('edit-avatar-${pair[1].id}'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pair.map((UserProfile user) => user.name).join(' × '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Rainbow Cats 双人小仓库',
                      style: TextStyle(
                        color: RainbowDesign.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CreditBadge(widget.store.currentUser.credit),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _AccountQuickLink(
                key: const ValueKey<String>('open-ledger'),
                icon: Icons.receipt_long_outlined,
                label: '积分明细',
                onTap: () => Navigator.pushNamed(context, '/ledger'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AccountQuickLink(
                key: const ValueKey<String>('open-settings'),
                icon: Icons.cloud_sync_outlined,
                label: '设置同步',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
          ],
        ),
        const SectionTitle('我的仓库'),
        GlassSurface(
          radius: 22,
          blur: 16,
          shadow: false,
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 42,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _InventoryTab(
                    key: const ValueKey<String>('inventory-unused-tab'),
                    label: '未使用',
                    selected: !_showUsed,
                    onTap: () => setState(() => _showUsed = false),
                  ),
                ),
                Expanded(
                  child: _InventoryTab(
                    key: const ValueKey<String>('inventory-used-tab'),
                    label: '使用记录',
                    selected: _showUsed,
                    onTap: () => setState(() => _showUsed = true),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          EmptyState(label: _showUsed ? '还没有使用记录' : '仓库还是空的')
        else
          ...items.map(
            (InventoryItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RainbowCard(
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ItemDetailPage(
                      store: widget.store,
                      itemId: item.id,
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: EditableImage(
                        asset: item.imageAsset,
                        width: 68,
                        height: 68,
                        borderRadius: BorderRadius.circular(18),
                        editKey:
                            ValueKey<String>('edit-inventory-list-${item.id}'),
                        semanticLabel: '编辑${item.rewardTitle}图片',
                        onChanged: (String value) async {
                          item
                            ..imageAsset = value
                            ..updatedAt = DateTime.now();
                          await widget.store.updateSettings(widget.store.settings);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.rewardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.used ? '已使用' : '可以使用',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.used
                                  ? RainbowDesign.muted
                                  : RainbowDesign.accentDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: RainbowDesign.muted),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountQuickLink extends StatelessWidget {
  const _AccountQuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RainbowCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: RainbowDesign.accentDeep, size: 22),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? RainbowDesign.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? RainbowDesign.accentDeep : RainbowDesign.muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
}

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({
    required this.store,
    required this.itemId,
    super.key,
  });

  final RainbowStore store;
  final String itemId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (BuildContext context, _) {
          final InventoryItem? item = store.inventoryById(itemId);
          if (item == null) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: <Widget>[
                  RainbowTopBar(
                    title: '物品详情',
                    store: store,
                    onBack: () => Navigator.pop(context),
                  ),
                  const Expanded(child: EmptyState(label: '物品不存在')),
                ],
              ),
            );
          }
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: <Widget>[
                RainbowTopBar(
                  title: '物品详情',
                  store: store,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    children: <Widget>[
                      RainbowCard(
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(RainbowDesign.radiusLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SizedBox(
                                height: 228,
                                child: EditableImage(
                                  asset: item.imageAsset,
                                  height: 228,
                                  width: double.infinity,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(RainbowDesign.radiusLarge),
                                    topRight: Radius.circular(RainbowDesign.radiusLarge),
                                  ),
                                  editKey: ValueKey<String>(
                                    'edit-inventory-detail-${item.id}',
                                  ),
                                  semanticLabel: '编辑${item.rewardTitle}图片',
                                  onChanged: (String value) async {
                                    item
                                      ..imageAsset = value
                                      ..updatedAt = DateTime.now();
                                    await store.updateSettings(store.settings);
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.rewardTitle,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item.description.isEmpty
                                          ? '暂无说明'
                                          : item.description,
                                    ),
                                    const SizedBox(height: 18),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    _DetailRow(
                                      label: '兑换价格',
                                      trailing: CreditBadge(item.cost),
                                    ),
                                    _DetailRow(
                                      label: '状态',
                                      value: item.used ? '已使用' : '未使用',
                                    ),
                                    _DetailRow(
                                      label: '获得时间',
                                      value: _formatDate(item.acquiredAt),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledPinkButton(
                        key: const ValueKey<String>('use-inventory'),
                        label: item.used ? '已经使用' : '使用物品',
                        icon: item.used
                            ? Icons.check_circle_rounded
                            : Icons.redeem_rounded,
                        enabled: !item.used,
                        onPressed: () => _use(context, item),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey<String>('delete-inventory'),
                        style: TextButton.styleFrom(
                          foregroundColor: RainbowDesign.danger,
                        ),
                        onPressed: () => _delete(context, item),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('删除仓库记录'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Future<void> _use(BuildContext context, InventoryItem item) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('确认使用'),
            content: const Text('使用后会进入使用记录，不能恢复。'),
            actions: <Widget>[
              TextButton(
                key: const ValueKey<String>('cancel-use-inventory'),
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              TextButton(
                key: const ValueKey<String>('confirm-use-inventory'),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('确认'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      await showResult(context, store.useInventoryItem(item.id));
    }
  }

  Future<void> _delete(BuildContext context, InventoryItem item) async {
    final bool confirmed = await _confirmDelete(
      context,
      title: '删除仓库记录',
      message: '确定删除“${item.rewardTitle}”吗？',
    );
    if (!confirmed) return;
    final ActionResult result = await store.deleteInventoryItem(item.id);
    if (!context.mounted) return;
    if (result.ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(color: RainbowDesign.muted)),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing ??
                    Text(
                      value ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
              ),
            ),
          ],
        ),
      );
}

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '删除',
              style: TextStyle(color: RainbowDesign.danger),
            ),
          ),
        ],
      ),
    ) ??
    false;

class VisualReviewCatalog extends StatefulWidget {
  const VisualReviewCatalog({required this.store, super.key});

  final RainbowStore store;

  static const List<String> pageNames = <String>[
    '01-home',
    '02-mission-list',
    '03-mission-add',
    '04-mission-detail',
    '05-market-list',
    '06-market-add',
    '07-market-detail',
    '08-account',
    '09-item-detail',
    '10-settings',
    '11-point-ledger',
  ];

  @override
  State<VisualReviewCatalog> createState() => _VisualReviewCatalogState();
}

class _VisualReviewCatalogState extends State<VisualReviewCatalog> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = buildVisualPages(widget.store);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          HeroMode(
            enabled: false,
            child: IndexedStack(index: _index, children: pages),
          ),
          Positioned.fill(
            child: Row(
              children: List<Widget>.generate(
                pages.length,
                (int index) => Expanded(
                  child: GestureDetector(
                    key: ValueKey<String>('visual-zone-$index'),
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _index = index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> buildVisualPages(RainbowStore store) => <Widget>[
      RainbowShell(
        key: const ValueKey<String>('visual-home-shell'),
        store: store,
        initialIndex: 0,
        lockedIndex: true,
      ),
      RainbowShell(
        key: const ValueKey<String>('visual-mission-shell'),
        store: store,
        initialIndex: 1,
        lockedIndex: true,
      ),
      MissionAddPage(store: store),
      MissionDetailPage(store: store, missionId: 'mission-1'),
      RainbowShell(
        key: const ValueKey<String>('visual-market-shell'),
        store: store,
        initialIndex: 2,
        lockedIndex: true,
      ),
      MarketAddPage(store: store),
      MarketDetailPage(store: store, rewardId: 'reward-1'),
      RainbowShell(
        key: const ValueKey<String>('visual-account-shell'),
        store: store,
        initialIndex: 3,
        lockedIndex: true,
      ),
      ItemDetailPage(store: store, itemId: 'inventory-1'),
      SettingsPage(store: store),
      PointLedgerPage(store: store),
    ];
