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

  testWidgets('按钮矩阵：首页、四主导航、三统计入口和首页图片编辑',
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
    await tester.tap(find.byKey(const ValueKey<String>('edit-home-image-0')));
    await tester.pumpAndSettle();
    expect(RainbowMediaStore.instance.homeImageAt(0), _image);

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
    await tester.drag(
      find.byKey(const ValueKey<String>('mission-credit-slider')),
      const Offset(60, 0),
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-mission')));
    await tester.pumpAndSettle();
    expect(value.missions.first.title, '按钮任务');

    await tester.tap(find.text('按钮任务'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('star-mission')));
    await tester.pumpAndSettle();
    expect(value.missions.first.starred, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('edit-mission')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '按钮任务改',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-mission')));
    await tester.pumpAndSettle();
    expect(value.missions.first.title, '按钮任务改');

    await tester.tap(find.byKey(const ValueKey<String>('delete-mission')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(value.missions.any((Mission item) => item.title == '按钮任务改'), isFalse);
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
    await tester.tap(find.byKey(const ValueKey<String>('complete-mission')));
    await tester.pumpAndSettle();
    expect(target.completed, isTrue);
  });

  testWidgets('按钮矩阵：商城新增、图片、滑杆、星标、编辑和删除',
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
    await tester.drag(
      find.byKey(const ValueKey<String>('reward-cost-slider')),
      const Offset(50, 0),
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-reward')));
    await tester.pumpAndSettle();
    final Reward created = value.rewards.first;
    expect(created.imageAsset, _image);

    await tester.tap(find.text('按钮商品'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('star-reward')));
    await tester.pumpAndSettle();
    expect(created.starred, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('edit-reward')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-title')),
      '按钮商品改',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-reward')));
    await tester.pumpAndSettle();
    expect(created.title, '按钮商品改');

    await tester.tap(find.byKey(const ValueKey<String>('delete-reward')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey<String>('buy-reward')));
    await tester.pumpAndSettle();
    expect(target.available, isFalse);
    expect(value.currentUser.credit, lessThan(before));
    expect(value.currentInventory.isNotEmpty, isTrue);
  });

  testWidgets('按钮矩阵：仓库双方头像、积分、设置、使用记录和图片编辑',
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

    await tester.tap(find.byKey(const ValueKey<String>('inventory-used-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('inventory-unused-tab')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('open-ledger')));
    await tester.pumpAndSettle();
    expect(find.text('积分明细'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byKey(const ValueKey<String>('use-inventory')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('cancel-use-inventory')));
    await tester.pumpAndSettle();
    expect(target.used, isFalse);

    await tester.tap(find.byKey(const ValueKey<String>('use-inventory')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('confirm-use-inventory')));
    await tester.pumpAndSettle();
    expect(target.used, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('delete-inventory')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(value.inventoryById(target.id), isNull);
  });

  testWidgets('按钮矩阵：设置页所有本地和无配置网络按钮均可点击',
      (WidgetTester tester) async {
    final RainbowStore value = store();
    await tester.pumpWidget(harness(SettingsPage(store: value)));
    await tester.pumpAndSettle();

    for (final String key in <String>[
      'toggle-webdav-password',
      'toggle-server-token',
      'auto-sync-switch',
      'save-settings',
      'webdav-test',
      'webdav-upload',
      'webdav-sync',
      'server-health',
      'copy-backup',
    ]) {
      final Finder finder = find.byKey(ValueKey<String>(key));
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '按钮 $key 出现异常');
    }

    for (final String key in <String>['webdav-restore', 'webdav-delete', 'reset-data']) {
      final Finder finder = find.byKey(ValueKey<String>(key));
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('dialog-cancel')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('dialog-cancel')));
      await tester.pumpAndSettle();
    }

    await Clipboard.setData(ClipboardData(text: value.exportData()));
    final Finder importButton = find.byKey(const ValueKey<String>('import-backup'));
    await tester.ensureVisible(importButton);
    await tester.tap(importButton);
    await tester.pumpAndSettle();
    expect(value.users.length, 2);
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
