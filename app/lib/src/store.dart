import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../generated/original_assets.dart';
import 'models.dart';

abstract interface class RainbowStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SharedPreferencesRainbowStorage implements RainbowStorage {
  static const String _key = 'rainbow_cats_snapshot_v2';
  static const String _legacyKey = 'rainbow_cats_snapshot_v1';

  @override
  Future<String?> read() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key) ?? preferences.getString(_legacyKey);
  }

  @override
  Future<void> write(String value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool saved = await preferences.setString(_key, value);
    if (!saved) throw StateError('SharedPreferences 写入失败');
    await preferences.remove(_legacyKey);
  }

  @override
  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
    await preferences.remove(_legacyKey);
  }
}

class MemoryRainbowStorage implements RainbowStorage {
  MemoryRainbowStorage([this.value]);

  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class RainbowStore extends ChangeNotifier {
  RainbowStore(
    this.storage, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const int maxMembers = 10;
  static const int minMembers = 2;

  final RainbowStorage storage;
  final DateTime Function() _clock;
  final Set<String> _pendingOperations = <String>{};
  int _idSequence = 0;
  Future<void> _writeQueue = Future<void>.value();

  bool ready = false;
  String? lastStorageError;
  String? lastSyncMessage;
  bool? lastSyncOk;
  DateTime? lastSyncAt;
  String currentUserId = 'kabi';
  DateTime modifiedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  AppSettings settings = const AppSettings();

  final List<UserProfile> users = <UserProfile>[];
  final List<Mission> missions = <Mission>[];
  final List<Reward> rewards = <Reward>[];
  final List<InventoryItem> inventory = <InventoryItem>[];
  final List<PointEntry> pointEntries = <PointEntry>[];
  final List<Tombstone> tombstones = <Tombstone>[];

  UserProfile get currentUser =>
      users.firstWhere((UserProfile user) => user.id == currentUserId);

  UserProfile get partner => users.firstWhere(
        (UserProfile user) => user.id != currentUserId,
        orElse: () => currentUser,
      );

  UserProfile userById(String id) =>
      users.firstWhere((UserProfile user) => user.id == id);

  List<InventoryItem> get currentInventory => inventory
      .where((InventoryItem item) => item.ownerId == currentUserId)
      .toList()
    ..sort((InventoryItem a, InventoryItem b) =>
        b.acquiredAt.compareTo(a.acquiredAt));

  List<PointEntry> get currentPointEntries => pointEntries
      .where((PointEntry entry) => entry.userId == currentUserId)
      .toList()
    ..sort((PointEntry a, PointEntry b) =>
        b.createdAt.compareTo(a.createdAt));

  Future<void> initialize() async {
    String? raw;
    try {
      raw = await storage.read();
    } on Object catch (error) {
      seedForTest();
      lastStorageError = '本地数据无法读取，已临时使用初始数据：$error';
      try {
        await _save();
      } on Object catch (writeError) {
        lastStorageError = '$lastStorageError；重新保存失败：$writeError';
      }
      ready = true;
      notifyListeners();
      return;
    }

    if (raw == null || raw.trim().isEmpty) {
      seedForTest();
      try {
        await _save();
        lastStorageError = null;
      } on Object catch (error) {
        lastStorageError = '初始数据只能保存在内存中，重启后可能丢失：$error';
      }
      ready = true;
      notifyListeners();
      return;
    }

    try {
      _apply(RainbowSnapshot.decode(raw), includeSettings: true);
    } on Object catch (error) {
      lastStorageError = '本地数据已损坏或格式不兼容，已恢复初始数据：$error';
      try {
        await storage.clear();
      } on Object catch (clearError) {
        lastStorageError = '$lastStorageError；清理失败：$clearError';
      }
      seedForTest();
      try {
        await _save();
      } on Object catch (writeError) {
        lastStorageError = '$lastStorageError；重新保存失败：$writeError';
      }
      ready = true;
      notifyListeners();
      return;
    }

    // 数据已成功解析。迁移写回失败时保留现有内容，绝不退回样例数据。
    try {
      await _save();
      lastStorageError = null;
    } on Object catch (error) {
      lastStorageError = '本地数据已读取，但迁移或保存失败；当前内容仍可使用：$error';
    }
    ready = true;
    notifyListeners();
  }

  void seedForTest() {
    final DateTime now = _clock();
    currentUserId = 'kabi';
    modifiedAt = now;
    settings = const AppSettings();
    users
      ..clear()
      ..addAll(<UserProfile>[
        UserProfile(
          id: 'kabi',
          name: '卡比',
          credit: 120,
          avatarAsset: OriginalAssets.homeAt(0),
          updatedAt: now,
        ),
        UserProfile(
          id: 'wadou',
          name: '瓦豆',
          credit: 95,
          avatarAsset: OriginalAssets.homeAt(1),
          updatedAt: now,
        ),
      ]);
    missions
      ..clear()
      ..addAll(<Mission>[
        Mission(
          id: 'mission-1',
          ownerId: 'kabi',
          title: '一起散步',
          description: '晚饭后沿着熟悉的小路走三十分钟。',
          credit: 20,
          createdAt: now.subtract(const Duration(hours: 3)),
          starred: true,
          updatedAt: now.subtract(const Duration(hours: 3)),
        ),
        Mission(
          id: 'mission-2',
          ownerId: 'wadou',
          title: '记得喝水',
          description: '今天喝够八杯水，完成后告诉我。',
          credit: 12,
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        Mission(
          id: 'mission-3',
          ownerId: 'wadou',
          title: '整理书桌',
          description: '把桌面恢复成清爽的样子。',
          credit: 18,
          createdAt: now.subtract(const Duration(days: 2)),
          completed: true,
          completedAt: now.subtract(const Duration(days: 1, hours: 2)),
          updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        Mission(
          id: 'mission-4',
          ownerId: 'kabi',
          title: '选周末电影',
          description: '准备两部候选电影，晚上一起选。',
          credit: 10,
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
      ]);
    rewards
      ..clear()
      ..addAll(<Reward>[
        Reward(
          id: 'reward-1',
          ownerId: 'wadou',
          title: '奶茶兑换券',
          description: '任选一杯喜欢的奶茶。',
          cost: 35,
          createdAt: now.subtract(const Duration(hours: 5)),
          imageAsset: OriginalAssets.homeAt(0),
          starred: true,
          updatedAt: now.subtract(const Duration(hours: 5)),
        ),
        Reward(
          id: 'reward-2',
          ownerId: 'kabi',
          title: '周末早餐',
          description: '由发布者准备一份周末早餐。',
          cost: 50,
          createdAt: now.subtract(const Duration(days: 1)),
          imageAsset: OriginalAssets.homeAt(1),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        Reward(
          id: 'reward-3',
          ownerId: 'wadou',
          title: '抱抱十分钟',
          description: '随时可用的一次认真抱抱。',
          cost: 20,
          createdAt: now.subtract(const Duration(days: 2)),
          imageAsset: OriginalAssets.homeAt(2),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
      ]);
    inventory
      ..clear()
      ..addAll(<InventoryItem>[
        InventoryItem(
          id: 'inventory-1',
          ownerId: 'kabi',
          rewardTitle: '晚睡一次券',
          description: '周末可晚睡一次。',
          cost: 25,
          acquiredAt: now.subtract(const Duration(days: 4)),
          imageAsset: OriginalAssets.homeAt(2),
          updatedAt: now.subtract(const Duration(days: 4)),
        ),
        InventoryItem(
          id: 'inventory-2',
          ownerId: 'kabi',
          rewardTitle: '点歌券',
          description: '指定一首歌一起听。',
          cost: 15,
          acquiredAt: now.subtract(const Duration(days: 8)),
          used: true,
          usedAt: now.subtract(const Duration(days: 6)),
          updatedAt: now.subtract(const Duration(days: 6)),
        ),
      ]);
    pointEntries
      ..clear()
      ..addAll(<PointEntry>[
        PointEntry(
          id: 'point-1',
          userId: 'kabi',
          amount: 120,
          reason: '初始积分',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
        PointEntry(
          id: 'point-2',
          userId: 'wadou',
          amount: 95,
          reason: '初始积分',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      ]);
    tombstones.clear();
    ready = true;
  }

  void recordSyncResult({required bool ok, required String message}) {
    lastSyncOk = ok;
    lastSyncMessage = message;
    lastSyncAt = _clock();
    notifyListeners();
  }

  Future<void> switchUser() async {
    if (users.length < 2) return;
    final int currentIndex = users.indexWhere(
      (UserProfile user) => user.id == currentUserId,
    );
    final int nextIndex = (currentIndex + 1) % users.length;
    await switchUserTo(users[nextIndex].id);
  }

  Future<void> switchUserTo(String id) async {
    if (!users.any((UserProfile user) => user.id == id)) return;
    currentUserId = id;
    await _commit();
  }

  Future<void> reset() async {
    final AppSettings localSettings = settings;
    seedForTest();
    settings = localSettings;
    await _commit();
  }

  Future<ActionResult> addMember({
    required String name,
    int initialCredit = 0,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return const ActionResult(false, '请输入成员名称');
    if (trimmed.length > 12) return const ActionResult(false, '成员名称最多 12 个字');
    if (users.length >= maxMembers) {
      return const ActionResult(false, '最多添加 10 名成员');
    }
    if (users.any((UserProfile user) => user.name == trimmed)) {
      return const ActionResult(false, '成员名称已存在');
    }
    final DateTime now = _clock();
    final String id = _nextId('user');
    final int safeInitialCredit = initialCredit.clamp(0, 999999).toInt();
    users.add(
      UserProfile(
        id: id,
        name: trimmed,
        credit: safeInitialCredit,
        avatarAsset: OriginalAssets.homeAt(users.length),
        updatedAt: now,
      ),
    );
    if (safeInitialCredit != 0) {
      pointEntries.add(
        PointEntry(
          id: _nextId('point'),
          userId: id,
          amount: safeInitialCredit,
          reason: '初始积分',
          createdAt: now,
        ),
      );
    }
    await _commit();
    return ActionResult(true, '已添加成员 $trimmed');
  }

  Future<ActionResult> updateMember({
    required String id,
    required String name,
    required int credit,
  }) async {
    final UserProfile? user = _user(id);
    if (user == null) return const ActionResult(false, '成员不存在');
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return const ActionResult(false, '请输入成员名称');
    if (trimmed.length > 12) return const ActionResult(false, '成员名称最多 12 个字');
    if (users.any((UserProfile value) =>
        value.id != id && value.name == trimmed)) {
      return const ActionResult(false, '成员名称已存在');
    }
    final int safeCredit = credit.clamp(0, 999999).toInt();
    final int delta = safeCredit - user.credit;
    user
      ..name = trimmed
      ..credit = safeCredit
      ..updatedAt = _clock();
    if (delta != 0) {
      pointEntries.add(
        PointEntry(
          id: _nextId('point'),
          userId: id,
          amount: delta,
          reason: '手动调整积分',
          createdAt: _clock(),
        ),
      );
    }
    await _commit();
    return const ActionResult(true, '成员资料已保存');
  }

  Future<ActionResult> deleteMember(String id) async {
    if (users.length <= minMembers) {
      return const ActionResult(false, '至少保留两名成员');
    }
    final UserProfile? user = _user(id);
    if (user == null) return const ActionResult(false, '成员不存在');
    final DateTime now = _clock();
    _recordTombstone('user', id, now);
    for (final Mission item
        in missions.where((Mission item) => item.ownerId == id).toList()) {
      _recordTombstone('mission', item.id, now);
      missions.remove(item);
    }
    for (final Reward item
        in rewards.where((Reward item) => item.ownerId == id).toList()) {
      _recordTombstone('reward', item.id, now);
      rewards.remove(item);
    }
    for (final InventoryItem item in inventory
        .where((InventoryItem item) => item.ownerId == id)
        .toList()) {
      _recordTombstone('inventory', item.id, now);
      inventory.remove(item);
    }
    pointEntries.removeWhere((PointEntry entry) => entry.userId == id);
    users.remove(user);
    if (currentUserId == id) currentUserId = users.first.id;
    await _commit();
    return ActionResult(true, '已删除成员 ${user.name} 及其关联数据');
  }

  Future<ActionResult> addMission({
    required String title,
    required String description,
    required int credit,
  }) async {
    final ActionResult? invalid = _validateContent(
      title: title,
      description: description,
      value: credit,
      noun: '任务',
    );
    if (invalid != null) return invalid;
    final DateTime now = _clock();
    missions.insert(
      0,
      Mission(
        id: _nextId('mission'),
        ownerId: currentUserId,
        title: title.trim(),
        description: description.trim(),
        credit: credit,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _commit();
    return const ActionResult(true, '任务已发布');
  }

  Future<ActionResult> updateMission({
    required String id,
    required String title,
    required String description,
    required int credit,
  }) async {
    final Mission? mission = _mission(id);
    if (mission == null) return const ActionResult(false, '任务不存在');
    if (mission.ownerId != currentUserId) {
      return const ActionResult(false, '只能编辑自己发布的任务');
    }
    if (mission.completed) return const ActionResult(false, '已完成任务不能编辑');
    final ActionResult? invalid = _validateContent(
      title: title,
      description: description,
      value: credit,
      noun: '任务',
    );
    if (invalid != null) return invalid;
    mission
      ..title = title.trim()
      ..description = description.trim()
      ..credit = credit
      ..updatedAt = _clock();
    await _commit();
    return const ActionResult(true, '任务已保存');
  }

  Future<ActionResult> toggleMissionStar(String id) async {
    final Mission? mission = _mission(id);
    if (mission == null) return const ActionResult(false, '任务不存在');
    mission
      ..starred = !mission.starred
      ..updatedAt = _clock();
    await _commit();
    return ActionResult(true, mission.starred ? '已星标' : '已取消星标');
  }

  Future<ActionResult> deleteMission(String id) async {
    final Mission? mission = _mission(id);
    if (mission == null) return const ActionResult(false, '任务不存在');
    if (mission.ownerId != currentUserId) {
      return const ActionResult(false, '只能删除自己发布的任务');
    }
    missions.remove(mission);
    _recordTombstone('mission', id, _clock());
    await _commit();
    return const ActionResult(true, '任务已删除');
  }

  Future<ActionResult> completeMission(String id) async {
    final String operation = 'complete:$id';
    if (!_pendingOperations.add(operation)) {
      return const ActionResult(false, '操作正在处理中');
    }
    try {
      final Mission? mission = _mission(id);
      if (mission == null) return const ActionResult(false, '任务不存在');
      if (mission.completed) return const ActionResult(false, '任务已经完成');
      if (mission.ownerId == currentUserId) {
        return const ActionResult(false, '只能完成其他成员发布的任务');
      }
      final DateTime now = _clock();
      mission
        ..completed = true
        ..completedAt = now
        ..updatedAt = now;
      final UserProfile publisher = userById(mission.ownerId);
      publisher
        ..credit += mission.credit
        ..updatedAt = now;
      pointEntries.add(
        PointEntry(
          id: _nextId('point'),
          userId: publisher.id,
          amount: mission.credit,
          reason: '任务完成：${mission.title}',
          createdAt: now,
        ),
      );
      await _commit();
      return ActionResult(
        true,
        '完成任务，${publisher.name} 获得 ${mission.credit} 积分',
      );
    } finally {
      _pendingOperations.remove(operation);
    }
  }

  Future<ActionResult> addReward({
    required String title,
    required String description,
    required int cost,
  }) async {
    final ActionResult? invalid = _validateContent(
      title: title,
      description: description,
      value: cost,
      noun: '商品',
    );
    if (invalid != null) return invalid;
    final DateTime now = _clock();
    rewards.insert(
      0,
      Reward(
        id: _nextId('reward'),
        ownerId: currentUserId,
        title: title.trim(),
        description: description.trim(),
        cost: cost,
        createdAt: now,
        updatedAt: now,
        imageAsset: OriginalAssets.homeAt(rewards.length),
      ),
    );
    await _commit();
    return const ActionResult(true, '商品已上架');
  }

  Future<ActionResult> updateReward({
    required String id,
    required String title,
    required String description,
    required int cost,
  }) async {
    final Reward? reward = _reward(id);
    if (reward == null) return const ActionResult(false, '商品不存在');
    if (reward.ownerId != currentUserId) {
      return const ActionResult(false, '只能编辑自己发布的商品');
    }
    if (!reward.available) return const ActionResult(false, '已兑换商品不能编辑');
    final ActionResult? invalid = _validateContent(
      title: title,
      description: description,
      value: cost,
      noun: '商品',
    );
    if (invalid != null) return invalid;
    reward
      ..title = title.trim()
      ..description = description.trim()
      ..cost = cost
      ..updatedAt = _clock();
    await _commit();
    return const ActionResult(true, '商品已保存');
  }

  Future<ActionResult> toggleRewardStar(String id) async {
    final Reward? reward = _reward(id);
    if (reward == null) return const ActionResult(false, '商品不存在');
    reward
      ..starred = !reward.starred
      ..updatedAt = _clock();
    await _commit();
    return ActionResult(true, reward.starred ? '已星标' : '已取消星标');
  }

  Future<ActionResult> deleteReward(String id) async {
    final Reward? reward = _reward(id);
    if (reward == null) return const ActionResult(false, '商品不存在');
    if (reward.ownerId != currentUserId) {
      return const ActionResult(false, '只能删除自己发布的商品');
    }
    rewards.remove(reward);
    _recordTombstone('reward', id, _clock());
    await _commit();
    return const ActionResult(true, '商品已删除');
  }

  Future<ActionResult> buyReward(String id) async {
    final String operation = 'buy:$id';
    if (!_pendingOperations.add(operation)) {
      return const ActionResult(false, '操作正在处理中');
    }
    try {
      final Reward? reward = _reward(id);
      if (reward == null) return const ActionResult(false, '商品不存在');
      if (!reward.available) return const ActionResult(false, '商品已被兑换');
      if (reward.ownerId == currentUserId) {
        return const ActionResult(false, '不能购买自己发布的商品');
      }
      if (currentUser.credit < reward.cost) {
        return const ActionResult(false, '积分不足');
      }
      final DateTime now = _clock();
      currentUser
        ..credit -= reward.cost
        ..updatedAt = now;
      reward
        ..available = false
        ..updatedAt = now;
      inventory.insert(
        0,
        InventoryItem(
          id: _nextId('inventory'),
          ownerId: currentUserId,
          rewardTitle: reward.title,
          description: reward.description,
          cost: reward.cost,
          acquiredAt: now,
          updatedAt: now,
          imageAsset: reward.imageAsset,
        ),
      );
      pointEntries.add(
        PointEntry(
          id: _nextId('point'),
          userId: currentUserId,
          amount: -reward.cost,
          reason: '兑换商品：${reward.title}',
          createdAt: now,
        ),
      );
      await _commit();
      return const ActionResult(true, '兑换成功，已放入仓库');
    } finally {
      _pendingOperations.remove(operation);
    }
  }

  Future<ActionResult> useInventoryItem(String id) async {
    final InventoryItem? target = _inventoryItem(id);
    if (target == null || target.ownerId != currentUserId) {
      return const ActionResult(false, '物品不存在');
    }
    if (target.used) return const ActionResult(false, '物品已经使用');
    final DateTime now = _clock();
    target
      ..used = true
      ..usedAt = now
      ..updatedAt = now;
    await _commit();
    return const ActionResult(true, '已标记为使用');
  }

  Future<ActionResult> deleteInventoryItem(String id) async {
    final InventoryItem? target = _inventoryItem(id);
    if (target == null || target.ownerId != currentUserId) {
      return const ActionResult(false, '物品不存在');
    }
    inventory.remove(target);
    _recordTombstone('inventory', id, _clock());
    await _commit();
    return const ActionResult(true, '仓库记录已删除');
  }

  Future<ActionResult> updateSettings(AppSettings value) async {
    settings = value;
    await _commit();
    return const ActionResult(true, '设置已保存');
  }

  String exportData({bool includeSettings = false}) => _snapshot().encode(
        includeSettings: includeSettings,
        includeSecrets: false,
      );

  Future<ActionResult> replaceFromJson(String source) async {
    final RainbowSnapshot rollback = RainbowSnapshot.decode(
      _snapshot().encode(includeSettings: true, includeSecrets: true),
    );
    try {
      final RainbowSnapshot remote = RainbowSnapshot.decode(source);
      final AppSettings localSettings = settings;
      final String localCurrent = currentUserId;
      _apply(remote, includeSettings: false);
      settings = localSettings;
      if (users.any((UserProfile user) => user.id == localCurrent)) {
        currentUserId = localCurrent;
      }
      await _commit();
      return const ActionResult(true, '数据已从备份恢复');
    } on Object catch (error) {
      _apply(rollback, includeSettings: true);
      notifyListeners();
      return ActionResult(false, '备份格式无效：$error');
    }
  }

  Future<ActionResult> mergeFromJson(String source) async {
    final RainbowSnapshot rollback = RainbowSnapshot.decode(
      _snapshot().encode(includeSettings: true, includeSecrets: true),
    );
    try {
      final RainbowSnapshot remote = RainbowSnapshot.decode(source);
      final int before =
          users.length + missions.length + rewards.length + inventory.length;
      _merge(remote);
      await _commit();
      final int after =
          users.length + missions.length + rewards.length + inventory.length;
      final int added = after > before ? after - before : 0;
      return ActionResult(
        true,
        '同步完成，共保留 $after 条记录，新增 $added 条',
      );
    } on Object catch (error) {
      _apply(rollback, includeSettings: true);
      notifyListeners();
      return ActionResult(false, '同步数据无效：$error');
    }
  }

  Mission? missionById(String id) => _mission(id);
  Reward? rewardById(String id) => _reward(id);
  InventoryItem? inventoryById(String id) => _inventoryItem(id);

  ActionResult? _validateContent({
    required String title,
    required String description,
    required int value,
    required String noun,
  }) {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return ActionResult(false, '请输入$noun名称');
    if (trimmedTitle.length > 12) {
      return ActionResult(false, '$noun名称最多 12 个字');
    }
    if (description.trim().length > 100) {
      return const ActionResult(false, '说明最多 100 个字');
    }
    if (value <= 0) return const ActionResult(false, '积分必须大于 0');
    if (value > 99999) return const ActionResult(false, '积分不能超过 99999');
    return null;
  }

  UserProfile? _user(String id) {
    for (final UserProfile user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  Mission? _mission(String id) {
    for (final Mission mission in missions) {
      if (mission.id == id) return mission;
    }
    return null;
  }

  Reward? _reward(String id) {
    for (final Reward reward in rewards) {
      if (reward.id == id) return reward;
    }
    return null;
  }

  InventoryItem? _inventoryItem(String id) {
    for (final InventoryItem item in inventory) {
      if (item.id == id) return item;
    }
    return null;
  }

  String _nextId(String prefix) =>
      '$prefix-${_clock().microsecondsSinceEpoch}-${_idSequence++}';

  void _recordTombstone(String entity, String id, DateTime deletedAt) {
    tombstones.removeWhere((Tombstone value) =>
        value.entity == entity && value.id == id &&
        !value.deletedAt.isAfter(deletedAt));
    tombstones.add(Tombstone(entity: entity, id: id, deletedAt: deletedAt));
  }

  void _apply(RainbowSnapshot snapshot, {required bool includeSettings}) {
    if (snapshot.users.length < minMembers ||
        snapshot.users.length > maxMembers) {
      throw const FormatException('成员数量必须在 2 到 10 之间');
    }
    users
      ..clear()
      ..addAll(snapshot.users);
    missions
      ..clear()
      ..addAll(snapshot.missions);
    rewards
      ..clear()
      ..addAll(snapshot.rewards);
    inventory
      ..clear()
      ..addAll(snapshot.inventory);
    pointEntries
      ..clear()
      ..addAll(snapshot.pointEntries);
    tombstones
      ..clear()
      ..addAll(snapshot.tombstones);
    currentUserId = users.any(
      (UserProfile user) => user.id == snapshot.currentUserId,
    )
        ? snapshot.currentUserId
        : users.first.id;
    modifiedAt = snapshot.modifiedAt;
    if (includeSettings) settings = snapshot.settings;
    _removeOrphans();
    _applyTombstones();
    if (users.length < minMembers) {
      throw const FormatException('恢复结果少于两名成员');
    }
    if (!users.any((UserProfile user) => user.id == currentUserId)) {
      currentUserId = users.first.id;
    }
  }

  void _merge(RainbowSnapshot remote) {
    final AppSettings localSettings = settings;
    final String localCurrent = currentUserId;
    final Map<String, Tombstone> deletionMap = <String, Tombstone>{};
    for (final Tombstone item in <Tombstone>[...tombstones, ...remote.tombstones]) {
      final Tombstone? previous = deletionMap[item.key];
      if (previous == null || item.deletedAt.isAfter(previous.deletedAt)) {
        deletionMap[item.key] = item;
      }
    }

    final List<UserProfile> mergedUsers = _mergeUpdated<UserProfile>(
      users,
      remote.users,
      idOf: (UserProfile value) => value.id,
      updatedAtOf: (UserProfile value) => value.updatedAt,
    );
    final List<Mission> mergedMissions = _mergeUpdated<Mission>(
      missions,
      remote.missions,
      idOf: (Mission value) => value.id,
      updatedAtOf: (Mission value) => value.updatedAt,
    );
    final List<Reward> mergedRewards = _mergeUpdated<Reward>(
      rewards,
      remote.rewards,
      idOf: (Reward value) => value.id,
      updatedAtOf: (Reward value) => value.updatedAt,
    );
    final List<InventoryItem> mergedInventory = _mergeUpdated<InventoryItem>(
      inventory,
      remote.inventory,
      idOf: (InventoryItem value) => value.id,
      updatedAtOf: (InventoryItem value) => value.updatedAt,
    );
    final Map<String, PointEntry> mergedPoints = <String, PointEntry>{
      for (final PointEntry item in pointEntries) item.id: item,
      for (final PointEntry item in remote.pointEntries) item.id: item,
    };

    users
      ..clear()
      ..addAll(mergedUsers.take(maxMembers));
    missions
      ..clear()
      ..addAll(mergedMissions);
    rewards
      ..clear()
      ..addAll(mergedRewards);
    inventory
      ..clear()
      ..addAll(mergedInventory);
    pointEntries
      ..clear()
      ..addAll(mergedPoints.values);
    tombstones
      ..clear()
      ..addAll(deletionMap.values);
    settings = localSettings;
    currentUserId = users.any((UserProfile user) => user.id == localCurrent)
        ? localCurrent
        : users.any((UserProfile user) => user.id == remote.currentUserId)
            ? remote.currentUserId
            : users.first.id;
    modifiedAt = remote.modifiedAt.isAfter(modifiedAt)
        ? remote.modifiedAt
        : modifiedAt;
    _removeOrphans();
    _applyTombstones();
    if (users.length < minMembers) {
      throw const FormatException('同步结果少于两名成员');
    }
    if (!users.any((UserProfile user) => user.id == currentUserId)) {
      currentUserId = users.first.id;
    }
  }

  List<T> _mergeUpdated<T>(
    List<T> local,
    List<T> remote, {
    required String Function(T value) idOf,
    required DateTime Function(T value) updatedAtOf,
  }) {
    final Map<String, T> values = <String, T>{};
    for (final T item in <T>[...local, ...remote]) {
      final String id = idOf(item);
      final T? existing = values[id];
      if (existing == null ||
          updatedAtOf(item).isAfter(updatedAtOf(existing))) {
        values[id] = item;
      }
    }
    return values.values.toList();
  }

  void _removeOrphans() {
    final Set<String> userIds = users.map((UserProfile user) => user.id).toSet();
    missions.removeWhere((Mission item) => !userIds.contains(item.ownerId));
    rewards.removeWhere((Reward item) => !userIds.contains(item.ownerId));
    inventory.removeWhere((InventoryItem item) => !userIds.contains(item.ownerId));
    pointEntries.removeWhere((PointEntry item) => !userIds.contains(item.userId));
  }

  void _applyTombstones() {
    final Map<String, Tombstone> latest = <String, Tombstone>{};
    for (final Tombstone item in tombstones) {
      final Tombstone? previous = latest[item.key];
      if (previous == null || item.deletedAt.isAfter(previous.deletedAt)) {
        latest[item.key] = item;
      }
    }
    users.removeWhere((UserProfile item) {
      final Tombstone? deletion = latest['user:${item.id}'];
      return deletion != null && !deletion.deletedAt.isBefore(item.updatedAt);
    });
    missions.removeWhere((Mission item) {
      final Tombstone? deletion = latest['mission:${item.id}'];
      return deletion != null && !deletion.deletedAt.isBefore(item.updatedAt);
    });
    rewards.removeWhere((Reward item) {
      final Tombstone? deletion = latest['reward:${item.id}'];
      return deletion != null && !deletion.deletedAt.isBefore(item.updatedAt);
    });
    inventory.removeWhere((InventoryItem item) {
      final Tombstone? deletion = latest['inventory:${item.id}'];
      return deletion != null && !deletion.deletedAt.isBefore(item.updatedAt);
    });
    final DateTime cutoff = _clock().subtract(const Duration(days: 365));
    tombstones
      ..clear()
      ..addAll(latest.values.where(
        (Tombstone item) => item.deletedAt.isAfter(cutoff),
      ));
    _removeOrphans();
  }

  RainbowSnapshot _snapshot() => RainbowSnapshot(
        currentUserId: currentUserId,
        users: users,
        missions: missions,
        rewards: rewards,
        inventory: inventory,
        pointEntries: pointEntries,
        tombstones: tombstones,
        modifiedAt: modifiedAt,
        settings: settings,
      );

  Future<void> _save() {
    final String encoded = _snapshot().encode();
    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => storage.write(encoded));
    return _writeQueue;
  }

  Future<void> _commit() async {
    modifiedAt = _clock();
    notifyListeners();
    try {
      await _save();
      lastStorageError = null;
    } on Object catch (error) {
      // 本地存储失败时保留当前内存状态，避免普通点击直接导致 App 崩溃。
      lastStorageError = '本地保存失败，本次修改可能在重启后丢失：$error';
      notifyListeners();
    }
  }
}
