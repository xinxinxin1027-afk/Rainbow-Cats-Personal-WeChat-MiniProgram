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

void phoneTestWidgets(String description, WidgetTesterCallback body) {
  testWidgets(description, (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await body(tester);
  });
}

Future<void> boundedSettle(WidgetTester tester) async {
  for (int index = 0; index < 30; index += 1) {
    await tester.pump(const Duration(milliseconds: 40));
    if (!tester.binding.hasScheduledFrame) return;
  }
}

Finder _verticalScrollable({Key? ownerKey}) {
  Finder result = find.byType(Scrollable);
  if (ownerKey != null) {
    final Finder owned = find.descendant(
      of: find.byKey(ownerKey),
      matching: find.byType(Scrollable),
    );
    if (owned.evaluate().isNotEmpty) result = owned;
  }
  for (final Element element in result.evaluate()) {
    final Scrollable widget = element.widget as Scrollable;
    if (widget.axisDirection == AxisDirection.down ||
        widget.axisDirection == AxisDirection.up) {
      return find.byWidget(widget);
    }
  }
  return result.first;
}

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  Key? scrollOwnerKey,
}) async {
  final Finder scrollable = _verticalScrollable(ownerKey: scrollOwnerKey);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: scrollable,
      maxScrolls: 30,
    );
  }
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: .30,
    duration: Duration.zero,
  );
  await tester.pump();
  final Rect rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThan(900), reason: '按钮没有滚入手机可点击区域：$rect');
}

Future<void> tapVisible(
  WidgetTester tester,
  Finder finder, {
  Key? scrollOwnerKey,
}) async {
  await reveal(tester, finder, scrollOwnerKey: scrollOwnerKey);
  await tester.tap(finder);
  await boundedSettle(tester);
  expect(tester.takeException(), isNull);
}

Future<void> clearFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await boundedSettle(tester);
}

void main() {
  RainbowStore buildStore() => RainbowStore(
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

  phoneTestWidgets('按钮矩阵：首页导航、统计入口与三张图片编辑',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await boundedSettle(tester);

    for (int index = 0; index < 4; index++) {
      await tester.tap(find.byKey(ValueKey<String>('bottom-tab-$index')));
      await boundedSettle(tester);
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-0')));
    await boundedSettle(tester);
    for (int index = 0; index < 3; index++) {
      if (index > 0) {
        await tester.drag(
          find.byKey(const ValueKey<String>('home-carousel')),
          const Offset(-360, 0),
        );
        await boundedSettle(tester);
      }
      await tester.tap(find.byKey(ValueKey<String>('edit-home-image-$index')));
      await boundedSettle(tester);
      expect(RainbowMediaStore.instance.homeImageAt(index), _image);
    }

    for (final String label in <String>['待完成任务', '可兑换商品', '仓库物品']) {
      await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-0')));
      await boundedSettle(tester);
      await tester.tap(find.text(label));
      await boundedSettle(tester);
      expect(tester.takeException(), isNull);
    }
  });

  phoneTestWidgets('按钮矩阵：任务新增、滑杆、星标、编辑、完成和删除',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await boundedSettle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-1')));
    await boundedSettle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('add-mission')));
    await boundedSettle(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '按钮任务',
    );
    await reveal(tester, find.byKey(const ValueKey<String>('mission-credit-slider')));
    await tester.drag(
      find.byKey(const ValueKey<String>('mission-credit-slider')),
      const Offset(70, 0),
    );
    await tapVisible(tester, find.byKey(const ValueKey<String>('save-mission')));
    expect(store.missions.first.title, '按钮任务');

    await tester.tap(find.text('按钮任务'));
    await boundedSettle(tester);
    await tapVisible(tester, find.byKey(const ValueKey<String>('star-mission')));
    expect(store.missions.first.starred, isTrue);
    await tapVisible(tester, find.byKey(const ValueKey<String>('edit-mission')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '按钮任务改',
    );
    await tapVisible(tester, find.byKey(const ValueKey<String>('save-mission')));
    expect(store.missions.first.title, '按钮任务改');

    await tester.tap(find.text('按钮任务改'));
    await boundedSettle(tester);
    await tapVisible(tester, find.byKey(const ValueKey<String>('delete-mission')));
    await tester.tap(find.text('删除').last);
    await boundedSettle(tester);
    expect(store.missions.any((Mission item) => item.title == '按钮任务改'), isFalse);

    final Mission partnerMission = store.missions.firstWhere(
      (Mission item) => item.ownerId != store.currentUserId && !item.completed,
    );
    await tester.pumpWidget(
      harness(MissionDetailPage(store: store, missionId: partnerMission.id)),
    );
    await boundedSettle(tester);
    await tapVisible(tester, find.byKey(const ValueKey<String>('complete-mission')));
    expect(partnerMission.completed, isTrue);
  });

  phoneTestWidgets('按钮矩阵：商城新增、图片、滑杆、星标、编辑、兑换和删除',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await boundedSettle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-2')));
    await boundedSettle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('add-reward')));
    await boundedSettle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('edit-market-form-image')));
    await boundedSettle(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-title')),
      '按钮商品',
    );
    await reveal(tester, find.byKey(const ValueKey<String>('reward-cost-slider')));
    await tester.drag(
      find.byKey(const ValueKey<String>('reward-cost-slider')),
      const Offset(60, 0),
    );
    await tapVisible(tester, find.byKey(const ValueKey<String>('save-reward')));
    final Reward created = store.rewards.first;
    expect(created.title, '按钮商品');
    expect(created.imageAsset, _image);

    await tapVisible(
      tester,
      find.byKey(ValueKey<String>('edit-reward-list-${created.id}')),
    );
    await tester.tap(find.text('按钮商品'));
    await boundedSettle(tester);
    await tapVisible(tester, find.byKey(const ValueKey<String>('star-reward')));
    expect(created.starred, isTrue);
    await tapVisible(tester, find.byKey(const ValueKey<String>('edit-reward')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-title')),
      '按钮商品改',
    );
    await tapVisible(tester, find.byKey(const ValueKey<String>('save-reward')));
    expect(created.title, '按钮商品改');
    await tester.tap(find.text('按钮商品改'));
    await boundedSettle(tester);
    await tapVisible(tester, find.byKey(const ValueKey<String>('delete-reward')));
    await tester.tap(find.text('删除').last);
    await boundedSettle(tester);
    expect(store.rewards.contains(created), isFalse);

    final Reward buyable = store.rewards.firstWhere(
      (Reward item) => item.ownerId != store.currentUserId && item.available,
    );
    await tester.pumpWidget(
      harness(MarketDetailPage(store: store, rewardId: buyable.id)),
    );
    await boundedSettle(tester);
    await tester.tap(
      find.byKey(ValueKey<String>('edit-reward-detail-${buyable.id}')),
    );
    await boundedSettle(tester);
    final int before = store.currentUser.credit;
    await tapVisible(tester, find.byKey(const ValueKey<String>('buy-reward')));
    expect(buyable.available, isFalse);
    expect(store.currentUser.credit, lessThan(before));
    expect(store.currentInventory, isNotEmpty);
  });

  phoneTestWidgets('按钮矩阵：双方头像、仓库图片、筛选、积分与设置入口',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await boundedSettle(tester);
    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-3')));
    await boundedSettle(tester);

    for (final UserProfile user in store.users.take(2)) {
      await tester.tap(find.byKey(ValueKey<String>('edit-avatar-${user.id}')));
      await boundedSettle(tester);
      expect(user.avatarAsset, _image);
    }
    final InventoryItem listed = store.currentInventory.first;
    await tapVisible(
      tester,
      find.byKey(ValueKey<String>('edit-inventory-list-${listed.id}')),
    );
    expect(listed.imageAsset, _image);
    await tapVisible(tester, find.byKey(const ValueKey<String>('inventory-used-tab')));
    await tapVisible(tester, find.byKey(const ValueKey<String>('inventory-unused-tab')));
    await tapVisible(tester, find.byKey(const ValueKey<String>('open-ledger')));
    expect(find.text('积分明细'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('top-back')));
    await boundedSettle(tester);
    await tapVisible(tester, find.byKey(const ValueKey<String>('open-settings')));
    expect(find.text('设置与同步'), findsOneWidget);
  });

  phoneTestWidgets('按钮矩阵：仓库物品图片、使用取消/确认和删除',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    final InventoryItem item = store.currentInventory.firstWhere(
      (InventoryItem value) => !value.used,
    );
    await tester.pumpWidget(harness(ItemDetailPage(store: store, itemId: item.id)));
    await boundedSettle(tester);
    await tester.tap(
      find.byKey(ValueKey<String>('edit-inventory-detail-${item.id}')),
    );
    await boundedSettle(tester);
    expect(item.imageAsset, _image);

    await tapVisible(tester, find.byKey(const ValueKey<String>('use-inventory')));
    await tester.tap(find.byKey(const ValueKey<String>('cancel-use-inventory')));
    await boundedSettle(tester);
    expect(item.used, isFalse);
    await tapVisible(tester, find.byKey(const ValueKey<String>('use-inventory')));
    await tester.tap(find.byKey(const ValueKey<String>('confirm-use-inventory')));
    await boundedSettle(tester);
    expect(item.used, isTrue);
    await tapVisible(tester, find.byKey(const ValueKey<String>('delete-inventory')));
    await tester.tap(find.text('删除').last);
    await boundedSettle(tester);
    expect(store.inventoryById(item.id), isNull);
  });

  phoneTestWidgets('按钮矩阵：设置页全部本地和无配置网络操作',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(harness(SettingsPage(store: store)));
    await boundedSettle(tester);
    const Key scrollKey = ValueKey<String>('settings-scroll');

    Future<void> tapSetting(String key) async {
      await tapVisible(
        tester,
        find.byKey(ValueKey<String>(key)),
        scrollOwnerKey: scrollKey,
      );
      await clearFeedback(tester);
    }

    for (final String key in <String>[
      'toggle-webdav-password',
      'auto-sync-switch',
      'save-settings',
      'webdav-test',
      'webdav-upload',
      'webdav-sync',
    ]) {
      await tapSetting(key);
    }
    for (final String key in <String>['webdav-restore', 'webdav-delete']) {
      await tapVisible(
        tester,
        find.byKey(ValueKey<String>(key)),
        scrollOwnerKey: scrollKey,
      );
      expect(find.byKey(const ValueKey<String>('dialog-cancel')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('dialog-cancel')));
      await boundedSettle(tester);
    }
    for (final String key in <String>[
      'toggle-server-token',
      'server-health',
      'copy-backup',
    ]) {
      await tapSetting(key);
    }
    await Clipboard.setData(ClipboardData(text: store.exportData()));
    await tapSetting('import-backup');
    expect(store.users.length, 2);
    await tapVisible(
      tester,
      find.byKey(const ValueKey<String>('reset-data')),
      scrollOwnerKey: scrollKey,
    );
    expect(find.byKey(const ValueKey<String>('dialog-cancel')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('dialog-cancel')));
    await boundedSettle(tester);
  });

  phoneTestWidgets('按钮矩阵：左滑星标和删除动作', (WidgetTester tester) async {
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
    await boundedSettle(tester);
    await tester.drag(find.text('滑动测试'), const Offset(-220, 0));
    await boundedSettle(tester);
    await tester.tap(find.text('星标'));
    await boundedSettle(tester);
    expect(starred, isTrue);
    await tester.drag(find.text('滑动测试'), const Offset(-220, 0));
    await boundedSettle(tester);
    await tester.tap(find.text('删除'));
    await boundedSettle(tester);
    expect(deleted, isTrue);
  });
}
