import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/original_assets.dart';
import '../generated/original_style.dart';
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
  final PageController _controller = PageController(viewportFraction: .92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RainbowStore store = widget.store;
    final List<String?> images = OriginalAssets.homeImages.isEmpty
        ? <String?>[null, null, null]
        : OriginalAssets.homeImages.take(3).cast<String?>().toList();
    final int openMissions =
        store.missions.where((Mission item) => !item.completed).length;
    final int availableRewards =
        store.rewards.where((Reward item) => item.available).length;
    final int unusedItems = store.currentInventory
        .where((InventoryItem item) => !item.used)
        .length;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: <Widget>[
              RainbowCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    OriginalImage(
                      asset: store.currentUser.avatarAsset,
                      width: 58,
                      height: 58,
                      borderRadius: BorderRadius.circular(29),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '你好，${store.currentUser.name}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '今天也要和 ${store.partner.name} 好好相处',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: OriginalStyle.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CreditBadge(store.currentUser.credit),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 184,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (int value) => setState(() => _page = value),
                  itemBuilder: (BuildContext context, int index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        OriginalImage(
                          asset: images[index],
                          borderRadius: BorderRadius.circular(
                            OriginalStyle.cardRadius + 2,
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              OriginalStyle.cardRadius + 2,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Colors.black.withAlpha(100),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Text(
                            '把喜欢的日常，慢慢收集起来。',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(images.length, (int index) {
                  final bool active = index == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: active ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? OriginalStyle.primary
                          : OriginalStyle.divider,
                      borderRadius: BorderRadius.circular(4),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: OriginalStyle.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: OriginalStyle.primaryDark,
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
                          SizedBox(height: 3),
                          Text(
                            '完成对方发布的任务，为日常增加一点仪式感。',
                            style: TextStyle(
                              color: OriginalStyle.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
            Icon(icon, color: OriginalStyle.primaryDark, size: 25),
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
              style: const TextStyle(fontSize: 11, color: OriginalStyle.muted),
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

    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: <Widget>[
              ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                children: <Widget>[
                  TextField(
                    key: const ValueKey<String>('mission-search'),
                    onChanged: (String value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: '搜索任务',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SectionTitle('未完成', count: open.length),
                  if (open.isEmpty)
                    const EmptyState(label: '暂时没有待完成任务')
                  else
                    ...open.map((Mission item) => _MissionTile(
                          mission: item,
                          store: widget.store,
                        )),
                  SectionTitle('已完成', count: done.length),
                  if (done.isEmpty)
                    const EmptyState(label: '还没有完成记录')
                  else
                    ...done.map((Mission item) => _MissionTile(
                          mission: item,
                          store: widget.store,
                        )),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: FloatingActionButton(
                    key: const ValueKey<String>('add-mission'),
                    heroTag: 'add-mission',
                    elevation: 3,
                    backgroundColor: OriginalStyle.primary,
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MissionAddPage(store: widget.store),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
              color: const Color(0xFFFFB54A),
              onTap: () => showResult(
                context,
                store.toggleMissionStar(mission.id),
              ),
            ),
            if (mission.ownerId == store.currentUserId)
              SwipeAction(
                label: '删除',
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFE96B76),
                onTap: () async {
                  final bool confirmed = await _confirmDelete(
                    context,
                    title: '删除任务',
                    message: '确定删除“${mission.title}”吗？',
                  );
                  if (confirmed && context.mounted) {
                    await showResult(
                      context,
                      store.deleteMission(mission.id),
                    );
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: mission.completed
                        ? const Color(0xFFE8F4EA)
                        : OriginalStyle.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    mission.completed
                        ? Icons.check_rounded
                        : Icons.favorite_border_rounded,
                    color: mission.completed
                        ? const Color(0xFF5A9F69)
                        : OriginalStyle.primaryDark,
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
                              color: Color(0xFFFFB54A),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        mission.description.isEmpty ? '暂无说明' : mission.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OriginalStyle.muted,
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
                              color: OriginalStyle.muted,
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
  const MissionAddPage({
    required this.store,
    this.missionId,
    super.key,
  });

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
      body: Column(
        children: <Widget>[
          RainbowTopBar(
            title: editing
                ? '编辑任务'
                : OriginalAssets.pageTitle('MissionAdd', '发布任务'),
            store: widget.store,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
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
                        value: _credit,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: _credit.round().toString(),
                        onChanged: (double value) =>
                            setState(() => _credit = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledPinkButton(
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
              body: Column(
                children: <Widget>[
                  RainbowTopBar(
                    title: OriginalAssets.pageTitle('MissionDetail', '任务详情'),
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
            body: Column(
              children: <Widget>[
                RainbowTopBar(
                  title: OriginalAssets.pageTitle('MissionDetail', '任务详情'),
                  store: store,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      RainbowCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Container(
                              height: 128,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    OriginalStyle.primary.withAlpha(180),
                                    OriginalStyle.primary.withAlpha(55),
                                  ],
                                ),
                              ),
                              child: Icon(
                                mission.completed
                                    ? Icons.check_circle_rounded
                                    : Icons.favorite_rounded,
                                color: Colors.white,
                                size: 58,
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
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      if (mission.starred)
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFB54A),
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
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 14),
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
                      const SizedBox(height: 18),
                      FilledPinkButton(
                        label: mission.completed
                            ? '任务已完成'
                            : canComplete
                                ? '完成任务'
                                : '等待其他成员完成',
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
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD14D5A),
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

    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: <Widget>[
              ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          key: const ValueKey<String>('market-search'),
                          onChanged: (String value) =>
                              setState(() => _query = value),
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
                  const SizedBox(height: 8),
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
                              color: const Color(0xFFFFB54A),
                              onTap: () => showResult(
                                context,
                                widget.store.toggleRewardStar(item.id),
                              ),
                            ),
                            if (item.ownerId == widget.store.currentUserId)
                              SwipeAction(
                                label: '删除',
                                icon: Icons.delete_outline_rounded,
                                color: const Color(0xFFE96B76),
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
                  child: FloatingActionButton(
                    key: const ValueKey<String>('add-reward'),
                    heroTag: 'add-reward',
                    elevation: 3,
                    backgroundColor: OriginalStyle.primary,
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MarketAddPage(store: widget.store),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward, required this.store});
  final Reward reward;
  final RainbowStore store;

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
        child: SizedBox(
          height: 120,
          child: Row(
            children: <Widget>[
              OriginalImage(
                asset: reward.imageAsset,
                width: 120,
                height: 120,
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (reward.starred) ...<Widget>[
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFFFB54A),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (!reward.available)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: OriginalStyle.muted.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '已兑换',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: OriginalStyle.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          reward.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: OriginalStyle.muted,
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                            store.userById(reward.ownerId).name,
                            style: const TextStyle(
                              fontSize: 11,
                              color: OriginalStyle.muted,
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
      );
}

class MarketAddPage extends StatefulWidget {
  const MarketAddPage({
    required this.store,
    this.rewardId,
    super.key,
  });

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
      body: Column(
        children: <Widget>[
          RainbowTopBar(
            title: editing
                ? '编辑商品'
                : OriginalAssets.pageTitle('MarketAdd', '上架商品'),
            store: widget.store,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                OriginalImage(
                  asset: editing
                      ? _editing?.imageAsset
                      : OriginalAssets.homeAt(widget.store.rewards.length),
                  height: 170,
                  borderRadius: BorderRadius.circular(
                    OriginalStyle.cardRadius + 2,
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
                        value: _cost,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: _cost.round().toString(),
                        onChanged: (double value) =>
                            setState(() => _cost = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledPinkButton(
                  label: _saving
                      ? '正在保存…'
                      : editing
                          ? '保存商品'
                          : '上架商品',
                  icon: editing
                      ? Icons.save_outlined
                      : Icons.add_business_rounded,
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
              body: Column(
                children: <Widget>[
                  RainbowTopBar(
                    title: OriginalAssets.pageTitle('MarketDetail', '商品详情'),
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
            body: Column(
              children: <Widget>[
                RainbowTopBar(
                  title: OriginalAssets.pageTitle('MarketDetail', '商品详情'),
                  store: store,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      RainbowCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            OriginalImage(asset: reward.imageAsset, height: 230),
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
                                          color: Color(0xFFFFB54A),
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
                                  const SizedBox(height: 12),
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
                      const SizedBox(height: 18),
                      FilledPinkButton(
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
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD14D5A),
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
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: <Widget>[
              RainbowCard(
                child: Row(
                  children: <Widget>[
                    OriginalImage(
                      asset: widget.store.currentUser.avatarAsset,
                      width: 66,
                      height: 66,
                      borderRadius: BorderRadius.circular(33),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.store.currentUser.name,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Rainbow Cats 的小仓库',
                            style: TextStyle(
                              color: OriginalStyle.muted,
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
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = (constraints.maxWidth - 16) / 3;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _AccountQuickLink(
                        width: width,
                        icon: Icons.receipt_long_outlined,
                        label: '积分明细',
                        onTap: () => Navigator.pushNamed(context, '/ledger'),
                      ),
                      _AccountQuickLink(
                        width: width,
                        icon: Icons.group_outlined,
                        label: '成员管理',
                        onTap: () => Navigator.pushNamed(context, '/members'),
                      ),
                      _AccountQuickLink(
                        width: width,
                        icon: Icons.cloud_sync_outlined,
                        label: '设置同步',
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  );
                },
              ),
              const SectionTitle('我的仓库'),
              Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: OriginalStyle.surface,
                  borderRadius: BorderRadius.circular(OriginalStyle.cardRadius),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _InventoryTab(
                        label: '未使用',
                        selected: !_showUsed,
                        onTap: () => setState(() => _showUsed = false),
                      ),
                    ),
                    Expanded(
                      child: _InventoryTab(
                        label: '使用记录',
                        selected: _showUsed,
                        onTap: () => setState(() => _showUsed = true),
                      ),
                    ),
                  ],
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
                          OriginalImage(
                            asset: item.imageAsset,
                            width: 58,
                            height: 58,
                            borderRadius: BorderRadius.circular(12),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item.used ? '已使用' : '可以使用',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.used
                                        ? OriginalStyle.muted
                                        : OriginalStyle.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountQuickLink extends StatelessWidget {
  const _AccountQuickLink({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: RainbowCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          onTap: onTap,
          child: Column(
            children: <Widget>[
              Icon(icon, color: OriginalStyle.primaryDark, size: 23),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? OriginalStyle.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : OriginalStyle.muted,
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
              body: Column(
                children: <Widget>[
                  RainbowTopBar(
                    title: OriginalAssets.pageTitle('ItemDetail', '物品详情'),
                    store: store,
                    onBack: () => Navigator.pop(context),
                  ),
                  const Expanded(child: EmptyState(label: '物品不存在')),
                ],
              ),
            );
          }
          return Scaffold(
            body: Column(
              children: <Widget>[
                RainbowTopBar(
                  title: OriginalAssets.pageTitle('ItemDetail', '物品详情'),
                  store: store,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      RainbowCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            OriginalImage(asset: item.imageAsset, height: 220),
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
                                  const SizedBox(height: 12),
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
                      const SizedBox(height: 18),
                      FilledPinkButton(
                        label: item.used ? '已经使用' : '使用物品',
                        icon: item.used
                            ? Icons.check_circle_rounded
                            : Icons.redeem_rounded,
                        enabled: !item.used,
                        onPressed: () => _use(context, item),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD14D5A),
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
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              TextButton(
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
              style: TextStyle(color: Color(0xFFE34D59)),
            ),
          ),
        ],
      ),
    ) ??
    false;

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
            Text(label, style: const TextStyle(color: OriginalStyle.muted)),
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
    '11-members',
    '12-point-ledger',
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
      RainbowShell(key: const ValueKey<String>('visual-home-shell'), store: store, initialIndex: 0, lockedIndex: true),
      RainbowShell(key: const ValueKey<String>('visual-mission-shell'), store: store, initialIndex: 1, lockedIndex: true),
      MissionAddPage(store: store),
      MissionDetailPage(store: store, missionId: store.missions.first.id),
      RainbowShell(key: const ValueKey<String>('visual-market-shell'), store: store, initialIndex: 2, lockedIndex: true),
      MarketAddPage(store: store),
      MarketDetailPage(store: store, rewardId: store.rewards.first.id),
      RainbowShell(key: const ValueKey<String>('visual-account-shell'), store: store, initialIndex: 3, lockedIndex: true),
      ItemDetailPage(store: store, itemId: store.currentInventory.first.id),
      SettingsPage(store: store),
      MemberManagementPage(store: store),
      PointLedgerPage(store: store),
    ];
