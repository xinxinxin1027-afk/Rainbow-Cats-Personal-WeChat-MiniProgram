import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/main.dart';
import 'package:rainbow_cats/src/media.dart';
import 'package:rainbow_cats/src/pages.dart';
import 'package:rainbow_cats/src/settings_pages.dart';
import 'package:rainbow_cats/src/store.dart';
import 'package:rainbow_cats/src/theme.dart';
import 'package:rainbow_cats/src/widgets.dart';

const String _image =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZeeQAAAAASUVORK5CYII=';

Future<void> _reveal(
  WidgetTester tester,
  Finder finder, {
  double delta = 260,
}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).last,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _clearFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  RainbowStore store() => RainbowStore(
        MemoryRainbowStorage(),
        clock: () => DateTime(2026, 8, 12, 12),
      )..seedForTest();

  Widget harness(Widget child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: RainbowTheme.light,
        builder: (BuildContext context, Widget? page) => LiquidBackground(
          child: page ?? const SizedBox.shrink(),
        ),
        home: child,
      );

  setUp(() {
    RainbowImagePicker.debugPickerOverride = () async => _image;
    RainbowMediaStore.instance.resetForTest();
  });

  tearDown(() {
    RainbowImagePicker.debugPickerOverride = null;
    RainbowMediaStore.instance.resetForTest();
  });

  testWidgets('按钮矩阵：首页、四主导航、三统计入口和三张首页图片编辑',
      (WidgetTester tester) async {
    final RainbowStore value = store();
    await tester.pumpWidget(RainbowCatsApp(store: value));
    await tester.pumpAndSettle();

    for (int index = 0; index < 4; index++) {
      await tester.tap(find.byKey(ValueKey<String>('bottom-tab-$index')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-0')));
    await tester.pumpAndSettle();
    for (int index = 0; index < 3; index++) {
      if (index > 0) {
        await tester.drag(
          find.byKey(const ValueKey<String>('home-carousel')),
          const Offset(-520, 0),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.byKey(ValueKey<String>('edit-home-image-$index')),
      );
      await tester.pumpAndSettle();
      expect(RainbowMediaStore.instance.homeImageAt(index), _image);
    }

    for (final String label in <String>[
      '待完成任务',
      '可兑换商品',
      '仓库物品',
    ]) {
      await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('按钮矩阵：任务新增、积分滑杆、星标、编辑、删除',
      (WidgetTester tester) async {
    final RainbowStore value = store();
    await tester.pumpWidget(RainbowCatsApp(store: value));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-mission')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '按钮任务',
    );
    await _reveal(
      tester,
      find.byKey(const ValueKey<String>('mission-credit-slider')),
    );
    await tester.drag(
      find.byKey(const ValueKey<String>('mission-credit-slider')),
      const Offset(60, 0),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('save-mission')),
    );
    expect(value.missions.first.title, '按钮任务');

    await tester.tap(find.text('按钮任务'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('star-mission')),
    );
    expect(value.missions.first.starred, isTrue);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('edit-mission')),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '按钮任务改',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('save-mission')),
    );
    expect(value.missions.first.title, '按钮任务改');

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('delete-mission')),
    );
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(
      value.missions.any((Mission item) => item.title == '按钮任务改'),
      isFalse,
    );
  });

  testWidgets('按钮矩阵：完成对方任务', (WidgetTester tester) async {
    final RainbowStore value = store();
    final Mission target = value.missions.firstWhere(
      (Mission item) => item.ownerId != value.currentUserId && !item.completed,
    );
    await tester.pumpWidget(
      harness(MissionDetailPage(store: value, missionId: target.id)),
    );
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('complete-mission')),
    );
    expect(target.completed, isTrue);
  });

  testWidgets('按钮矩阵：商城新增、列表图片、滑杆、星标、编辑和删除',
      (WidgetTester tester) async {
    final RainbowStore value = store();
    await tester.pumpWidget(RainbowCatsApp(store: value));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-reward')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('edit-market-form-image')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-title')),
      '按钮商品',
    );
    await _reveal(
      tester,
      find.byKey(const ValueKey<String>('reward-cost-slider')),
    );
    await tester.drag(
      find.byKey(const ValueKey<String>('reward-cost-slider')),
      const Offset(50, 0),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('save-reward')),
    );
    final Reward created = value.rewards.first;
    expect(created.title, '按钮商品');
    expect(created.imageAsset, _image);

    await _tapVisible(
      tester,
      find.byKey(ValueKey<String>('edit-reward-list-${created.id}')),
    );
    expect(created.imageAsset, _image);
    await tester.tap(find.text('按钮商品'));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('star-reward')),
    );
    expect(created.starred, isTrue);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('edit-reward')),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-title')),
      '按钮商品改',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('save-reward')),
    );
    expect(created.title, '按钮商品改');

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('delete-reward')),
    );
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(value.rewards.contains(created), isFalse);
  });

  testWidgets('按钮矩阵：商品详情图片编辑与兑换', (WidgetTester tester) async {
    final RainbowStore value = store();
    final Reward target = value.rewards.firstWhere(
      (Reward item) => item.ownerId != value.currentUserId && item.available,
    );
    await tester.pumpWidget(
      harness(MarketDetailPage(store: value, rewardId: target.id)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey<String>('edit-reward-detail-${target.id}')),
    );
    await tester.pumpAndSettle();
    expect(target.imageAsset, _image);
    final int before = value.currentUser.credit;
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('buy-reward')),
    );
    expect(target.available, isFalse);
    expect(value.currentUser.credit, lessThan(before));
    expect(value.currentInventory.isNotEmpty, isTrue);
  });

  testWidgets('按钮矩阵：仓库双方头像、列表图片、积分、设置和使用记录',
      (WidgetTester tester) async {
    final RainbowStore value = store();
    await tester.pumpWidget(RainbowCatsApp(store: value));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-3')));
    await tester.pumpAndSettle();

    for (final UserProfile user in value.users.take(2)) {
      await tester.tap(find.byKey(ValueKey<String>('edit-avatar-${user.id}')));
      await tester.pumpAndSettle();
      expect(user.avatarAsset, _image);
    }

    final InventoryItem? listed = value.currentInventory.firstOrNull;
    if (listed != null) {
      await _tapVisible(
        tester,
        find.byKey(ValueKey<String>('edit-inventory-list-${listed.id}')),
      );
      expect(listed.imageAsset, _image);
    }

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('inventory-used-tab')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('inventory-unused-tab')),
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('open-ledger')),
    );
    expect(find.text('积分明细'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('top-back')));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('open-settings')),
    );
    expect(find.text('设置与同步'), findsOneWidget);
  });

  testWidgets('按钮矩阵：物品图片、使用确认取消/确认和删除',
      (WidgetTester tester) async {
    final RainbowStore value = store();
    final InventoryItem target = value.currentInventory.firstWhere(
      (InventoryItem item) => !item.used,
    );
    await tester.pumpWidget(
      harness(ItemDetailPage(store: value, itemId: target.id)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(ValueKey<String>('edit-inventory-detail-${target.id}')),
    );
    await tester.pumpAndSettle();
    expect(target.imageAsset, _image);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('use-inventory')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('cancel-use-inventory')));
    await tester.pumpAndSettle();
    expect(target.used, isFalse);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('use-inventory')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('confirm-use-inventory')));
    await tester.pumpAndSettle();
    expect(target.used, isTrue);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('delete-inventory')),
    );
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(value.inventoryById(target.id), isNull);
  });

  testWidgets('按钮矩阵：设置页全部本地及无配置网络按钮均真实可点击',
      (WidgetTester tester) async {
    final RainbowStore value = store();
    await tester.pumpWidget(harness(SettingsPage(store: value)));
    await tester.pumpAndSettle();

    Future<void> tapAndClear(String key) async {
      await _tapVisible(tester, find.byKey(ValueKey<String>(key)));
      expect(tester.takeException(), isNull, reason: '按钮 $key 出现异常');
      await _clearFeedback(tester);
    }

    await tapAndClear('toggle-webdav-password');
    await tapAndClear('auto-sync-switch');
    await tapAndClear('save-settings');
    await tapAndClear('webdav-test');
    await tapAndClear('webdav-upload');
    await tapAndClear('webdav-sync');

    for (final String key in <String>['webdav-restore', 'webdav-delete']) {
      await _tapVisible(tester, find.byKey(ValueKey<String>(key)));
      expect(find.byKey(const ValueKey<String>('dialog-cancel')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('dialog-cancel')));
      await tester.pumpAndSettle();
    }

    await tapAndClear('toggle-server-token');
    await tapAndClear('server-health');
    await tapAndClear('copy-backup');

    await Clipboard.setData(ClipboardData(text: value.exportData()));
    await tapAndClear('import-backup');
    expect(value.users.length, 2);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('reset-data')),
    );
    expect(find.byKey(const ValueKey<String>('dialog-cancel')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('dialog-cancel')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('按钮矩阵：左滑操作按钮可展开并执行', (WidgetTester tester) async {
    bool starred = false;
    bool deleted = false;
    await tester.pumpWidget(
      harness(
        Center(
          child: SizedBox(
            width: 330,
            height: 100,
            child: SwipeActionCell(
              actions: <SwipeAction>[
                SwipeAction(
                  label: '星标',
                  icon: Icons.star_rounded,
                  color: RainbowDesign.amber,
                  onTap: () => starred = true,
                ),
                SwipeAction(
                  label: '删除',
                  icon: Icons.delete_outline,
                  color: RainbowDesign.danger,
                  onTap: () => deleted = true,
                ),
              ],
              child: const RainbowCard(child: Text('滑动测试')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('滑动测试'), const Offset(-220, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('星标'));
    await tester.pumpAndSettle();
    expect(starred, isTrue);

    await tester.drag(find.text('滑动测试'), const Offset(-220, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
