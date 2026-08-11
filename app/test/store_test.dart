import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/src/models.dart';
import 'package:rainbow_cats/src/store.dart';

void main() {
  DateTime now() => DateTime(2026, 8, 11, 12);

  group('本地数据与成员', () {
    test('损坏的持久化数据会自动恢复', () async {
      final MemoryRainbowStorage storage = MemoryRainbowStorage('{broken');
      final RainbowStore store = RainbowStore(storage, clock: now);
      await store.initialize();
      expect(store.ready, isTrue);
      expect(store.users, hasLength(2));
      expect(storage.value, isNotNull);
      expect(store.lastStorageError, contains('本地数据已损坏'));
    });


    test('底层存储完全失败时仍可进入 App 并继续内存操作', () async {
      final RainbowStore store = RainbowStore(
        _FailingStorage(),
        clock: now,
      );
      await store.initialize();

      expect(store.ready, isTrue);
      expect(store.users, hasLength(2));
      expect(store.lastStorageError, isNotNull);
      expect(
        (await store.addMission(
          title: '仅内存任务',
          description: '',
          credit: 1,
        ))
            .ok,
        isTrue,
      );
      expect(store.missions.first.title, '仅内存任务');
      expect(store.lastStorageError, contains('重启后丢失'));
    });

    test('数据读取成功但写回失败时保留原内容', () async {
      final RainbowStore seed = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      final String source = seed.exportData(includeSettings: true);
      final RainbowStore store = RainbowStore(
        _ReadOnlyStorage(source),
        clock: now,
      );
      await store.initialize();

      expect(store.ready, isTrue);
      expect(store.users.map((UserProfile user) => user.name), containsAll(<String>['卡比', '瓦豆']));
      expect(store.missions, isNotEmpty);
      expect(store.lastStorageError, contains('当前内容仍可使用'));
    });

    test('一次写入失败不会永久阻塞后续保存', () async {
      final _FlakyStorage storage = _FlakyStorage();
      final RainbowStore store = RainbowStore(storage, clock: now)
        ..seedForTest();

      expect(
        (await store.addMission(
          title: '第一次写入',
          description: '',
          credit: 1,
        ))
            .ok,
        isTrue,
      );
      expect(store.lastStorageError, isNotNull);
      expect(
        (await store.addMission(
          title: '第二次写入',
          description: '',
          credit: 1,
        ))
            .ok,
        isTrue,
      );
      expect(store.lastStorageError, isNull);
      expect(storage.value, contains('第二次写入'));
      expect(storage.value, contains('第一次写入'));
    });

    test('旧版 schema 1 本地数据可以无损迁移', () async {
      final String legacy = jsonEncode(<String, Object?>{
        'currentUserId': 'wadou',
        'users': <Object?>[
          <String, Object?>{'id': 'kabi', 'name': '卡比', 'credit': 11},
          <String, Object?>{'id': 'wadou', 'name': '瓦豆', 'credit': 22},
        ],
        'missions': <Object?>[],
        'rewards': <Object?>[],
        'inventory': <Object?>[],
      });
      final MemoryRainbowStorage storage = MemoryRainbowStorage(legacy);
      final RainbowStore store = RainbowStore(storage, clock: now);
      await store.initialize();

      expect(store.currentUserId, 'wadou');
      expect(store.userById('kabi').credit, 11);
      expect(store.userById('wadou').credit, 22);
      expect(storage.value, contains('"schema": 2'));
    });

    test('支持 2 到 10 名成员、切换、编辑和级联删除', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      for (int index = 3; index <= 10; index += 1) {
        expect(
          (await store.addMember(name: '成员$index', initialCredit: index)).ok,
          isTrue,
        );
      }
      expect(store.users, hasLength(10));
      expect((await store.addMember(name: '第十一人')).ok, isFalse);

      final UserProfile target = store.users.last;
      await store.switchUserTo(target.id);
      expect(store.currentUserId, target.id);
      expect(
        (await store.updateMember(id: target.id, name: '小十', credit: 88)).ok,
        isTrue,
      );
      expect(store.currentUser.name, '小十');
      expect(store.currentUser.credit, 88);

      await store.addMission(title: '待删除成员任务', description: '', credit: 5);
      final String missionId = store.missions.first.id;
      expect((await store.deleteMember(target.id)).ok, isTrue);
      expect(store.users, hasLength(9));
      expect(store.missionById(missionId), isNull);
      expect(store.currentUserId, isNot(target.id));
    });

    test('至少保留两名成员', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      expect((await store.deleteMember(store.users.last.id)).ok, isFalse);
      expect(store.users, hasLength(2));
    });

    test('角色切换、设置和数据可持久化', () async {
      final MemoryRainbowStorage storage = MemoryRainbowStorage();
      final RainbowStore store = RainbowStore(storage, clock: now)
        ..seedForTest();
      await store.switchUser();
      await store.updateSettings(
        const AppSettings(
          webDavUrl: 'https://dav.example.test/root/',
          webDavUsername: 'user',
          webDavPassword: 'secret',
          serverUrl: 'https://api.example.test',
          serverToken: 'token',
          autoSync: true,
        ),
      );

      final RainbowStore restored = RainbowStore(storage, clock: now);
      await restored.initialize();
      expect(restored.currentUserId, 'wadou');
      expect(restored.settings.webDavUrl, contains('dav.example'));
      expect(restored.settings.webDavPassword, 'secret');
      expect(restored.settings.autoSync, isTrue);
    });
  });

  group('任务、积分、商城和仓库', () {
    test('任务可以新增、编辑、星标和删除', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      expect(
        (await store.addMission(
          title: '测试任务',
          description: '任务说明',
          credit: 25,
        ))
            .ok,
        isTrue,
      );
      final Mission mission = store.missions.first;
      expect(
        (await store.updateMission(
          id: mission.id,
          title: '修改任务',
          description: '新说明',
          credit: 30,
        ))
            .ok,
        isTrue,
      );
      expect(mission.title, '修改任务');
      expect((await store.toggleMissionStar(mission.id)).ok, isTrue);
      expect(mission.starred, isTrue);
      expect((await store.deleteMission(mission.id)).ok, isTrue);
      expect(store.missionById(mission.id), isNull);
      expect(store.tombstones.any((item) => item.id == mission.id), isTrue);

      final Mission partner = store.missions.firstWhere(
        (Mission item) => item.ownerId != store.currentUserId,
      );
      expect(
        (await store.updateMission(
          id: partner.id,
          title: '越权修改',
          description: '',
          credit: 1,
        ))
            .ok,
        isFalse,
      );
      expect((await store.deleteMission(partner.id)).ok, isFalse);
    });

    test('只能完成其他成员任务，且积分按原规则记到发布者', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      final Mission own =
          store.missions.firstWhere((Mission item) => item.ownerId == 'kabi');
      final Mission partner = store.missions.firstWhere(
        (Mission item) => item.ownerId == 'wadou' && !item.completed,
      );
      final int before = store.userById('wadou').credit;
      expect((await store.completeMission(own.id)).ok, isFalse);
      expect((await store.completeMission(partner.id)).ok, isTrue);
      expect(store.userById('wadou').credit, before + partner.credit);
      expect((await store.completeMission(partner.id)).ok, isFalse);
      expect(
        store.pointEntries.any(
          (PointEntry entry) =>
              entry.userId == 'wadou' && entry.amount == partner.credit,
        ),
        isTrue,
      );
    });

    test('快速重复点击任务完成只有一次成功', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      final Mission mission = store.missions.firstWhere(
        (Mission item) => item.ownerId == 'wadou' && !item.completed,
      );
      final int before = store.userById('wadou').credit;
      final List<ActionResult> results = await Future.wait(<Future<ActionResult>>[
        store.completeMission(mission.id),
        store.completeMission(mission.id),
      ]);

      expect(results.where((ActionResult result) => result.ok), hasLength(1));
      expect(store.userById('wadou').credit, before + mission.credit);
    });

    test('商品可以新增、编辑、星标、兑换并进入仓库', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      expect(
        (await store.addReward(
          title: '测试商品',
          description: '商品说明',
          cost: 15,
        ))
            .ok,
        isTrue,
      );
      final Reward own = store.rewards.first;
      expect(
        (await store.updateReward(
          id: own.id,
          title: '修改商品',
          description: '新说明',
          cost: 18,
        ))
            .ok,
        isTrue,
      );
      expect((await store.toggleRewardStar(own.id)).ok, isTrue);
      expect(own.starred, isTrue);
      expect((await store.buyReward(own.id)).ok, isFalse);

      final Reward partner = store.rewards.firstWhere(
        (Reward item) => item.ownerId == 'wadou' && item.available,
      );
      final int beforeCredit = store.currentUser.credit;
      final int beforeItems = store.currentInventory.length;
      expect((await store.buyReward(partner.id)).ok, isTrue);
      expect(store.currentUser.credit, beforeCredit - partner.cost);
      expect(store.currentInventory, hasLength(beforeItems + 1));
      expect((await store.buyReward(partner.id)).ok, isFalse);
      expect(
        (await store.updateReward(
          id: partner.id,
          title: '越权修改',
          description: '',
          cost: 1,
        ))
            .ok,
        isFalse,
      );
      expect((await store.deleteReward(partner.id)).ok, isFalse);
    });

    test('快速重复兑换只有一次扣分和入库', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      final Reward reward = store.rewards.firstWhere(
        (Reward item) => item.ownerId == 'wadou' && item.available,
      );
      final int beforeCredit = store.currentUser.credit;
      final int beforeItems = store.currentInventory.length;
      final List<ActionResult> results = await Future.wait(<Future<ActionResult>>[
        store.buyReward(reward.id),
        store.buyReward(reward.id),
      ]);

      expect(results.where((ActionResult result) => result.ok), hasLength(1));
      expect(store.currentUser.credit, beforeCredit - reward.cost);
      expect(store.currentInventory, hasLength(beforeItems + 1));
    });

    test('仓库物品只能使用一次并可以删除记录', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      final InventoryItem item =
          store.currentInventory.firstWhere((InventoryItem value) => !value.used);
      expect((await store.useInventoryItem(item.id)).ok, isTrue);
      expect(item.used, isTrue);
      expect((await store.useInventoryItem(item.id)).ok, isFalse);
      expect((await store.deleteInventoryItem(item.id)).ok, isTrue);
      expect(store.inventoryById(item.id), isNull);
    });

    test('输入校验符合原项目短标题与正积分规则', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      expect(
        (await store.addMission(title: '', description: '', credit: 1)).ok,
        isFalse,
      );
      expect(
        (await store.addMission(
          title: '一二三四五六七八九十十一十二十三',
          description: '',
          credit: 1,
        ))
            .ok,
        isFalse,
      );
      expect(
        (await store.addReward(title: '商品', description: '', cost: 0)).ok,
        isFalse,
      );
    });
  });

  group('导入、合并和删除同步', () {
    test('远端较新记录覆盖本机，设置和密钥仍保留在本机', () async {
      DateTime localTime = DateTime(2026, 8, 11, 12);
      final RainbowStore local = RainbowStore(
        MemoryRainbowStorage(),
        clock: () => localTime,
      )..seedForTest();
      await local.updateSettings(
        const AppSettings(
          webDavUrl: 'https://local.example/dav/',
          webDavPassword: 'local-secret',
        ),
      );

      DateTime remoteTime = DateTime(2026, 8, 11, 13);
      final RainbowStore remote = RainbowStore(
        MemoryRainbowStorage(),
        clock: () => remoteTime,
      )..seedForTest();
      await remote.updateMission(
        id: 'mission-1',
        title: '远端新标题',
        description: '远端更新',
        credit: 40,
      );
      await remote.addMember(name: '远端成员', initialCredit: 3);

      expect((await local.mergeFromJson(remote.exportData())).ok, isTrue);
      expect(local.missionById('mission-1')!.title, '远端新标题');
      expect(local.users.any((UserProfile user) => user.name == '远端成员'), isTrue);
      expect(local.settings.webDavPassword, 'local-secret');
      expect(local.exportData(), isNot(contains('local-secret')));
    });

    test('较新的删除标记不会被旧远端记录复活', () async {
      DateTime clock = DateTime(2026, 8, 11, 12);
      final RainbowStore local = RainbowStore(
        MemoryRainbowStorage(),
        clock: () => clock,
      )..seedForTest();
      final String deletedId = local.missions.first.id;
      clock = clock.add(const Duration(hours: 2));
      expect((await local.deleteMission(deletedId)).ok, isTrue);

      final RainbowStore oldRemote = RainbowStore(
        MemoryRainbowStorage(),
        clock: () => DateTime(2026, 8, 11, 12),
      )..seedForTest();
      expect((await local.mergeFromJson(oldRemote.exportData())).ok, isTrue);
      expect(local.missionById(deletedId), isNull);
    });

    test('替换导入错误 JSON 不崩溃且保持现有数据', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      final int before = store.missions.length;
      final ActionResult result = await store.replaceFromJson('{bad');
      expect(result.ok, isFalse);
      expect(store.missions, hasLength(before));
    });


    test('结构可解析但恢复结果无效时也会完整回滚', () async {
      final RainbowStore store = RainbowStore(MemoryRainbowStorage(), clock: now)
        ..seedForTest();
      final String before = store.exportData();
      final Map<String, Object?> invalid =
          Map<String, Object?>.from(jsonDecode(before) as Map);
      invalid['tombstones'] = store.users
          .map(
            (UserProfile user) => <String, Object?>{
              'entity': 'user',
              'id': user.id,
              'deletedAt': DateTime(2099).toIso8601String(),
            },
          )
          .toList();

      final ActionResult result = await store.replaceFromJson(jsonEncode(invalid));
      expect(result.ok, isFalse);
      expect(store.users, hasLength(2));
      expect(store.exportData(), before);
    });
  });
}



class _FlakyStorage implements RainbowStorage {
  String? value;
  int writes = 0;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    writes += 1;
    if (writes == 1) throw StateError('first write failed');
    this.value = value;
  }
}

class _ReadOnlyStorage implements RainbowStorage {
  _ReadOnlyStorage(this.value);

  final String value;

  @override
  Future<void> clear() async => throw StateError('clear blocked');

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => throw StateError('write blocked');
}

class _FailingStorage implements RainbowStorage {
  @override
  Future<void> clear() async => throw StateError('clear failed');

  @override
  Future<String?> read() async => throw StateError('read failed');

  @override
  Future<void> write(String value) async => throw StateError('write failed');
}
