import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/src/media.dart';
import 'package:rainbow_cats/src/pages.dart';
import 'package:rainbow_cats/src/settings_pages.dart';
import 'package:rainbow_cats/src/store.dart';
import 'package:rainbow_cats/src/theme.dart';
import 'package:rainbow_cats/src/widgets.dart';

const String _image =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZeeQAAAAASUVORK5CYII=';

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      260,
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

void main() {
  testWidgets('生成完整交互视觉状态画廊', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RainbowMediaStore.instance.resetForTest();
    RainbowImagePicker.debugPickerOverride = () async => _image;
    addTearDown(() {
      RainbowImagePicker.debugPickerOverride = null;
      RainbowMediaStore.instance.resetForTest();
    });

    final RainbowStore store = RainbowStore(
      MemoryRainbowStorage(),
      clock: () => DateTime(2026, 8, 12, 12),
    )..seedForTest();
    const Key captureKey = ValueKey<String>('interaction-capture');

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: RainbowTheme.light,
        builder: (BuildContext context, Widget? child) => RepaintBoundary(
          key: captureKey,
          child: LiquidBackground(child: child ?? const SizedBox.shrink()),
        ),
        routes: <String, WidgetBuilder>{
          '/settings': (_) => SettingsPage(store: store),
          '/ledger': (_) => PointLedgerPage(store: store),
        },
        home: RainbowShell(store: store),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 120));
      await expectLater(
        find.byKey(captureKey),
        matchesGoldenFile('../visual_review/interactions/$name.png'),
      );
      expect(tester.takeException(), isNull, reason: '视觉状态 $name 出现异常');
    }

    await shot('12-home-live');
    await tester.tap(find.byKey(const ValueKey<String>('edit-home-image-0')));
    await tester.pumpAndSettle();
    await shot('13-home-image-edited');

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-1')));
    await tester.pumpAndSettle();
    await shot('14-mission-list');
    await tester.tap(find.byKey(const ValueKey<String>('add-mission')));
    await tester.pumpAndSettle();
    await shot('15-mission-add');
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '一起散步',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-description')),
      '晚饭后走二十分钟',
    );
    await shot('16-mission-form-filled');
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('save-mission')),
    );
    await shot('17-mission-created');
    await tester.tap(find.text('一起散步'));
    await tester.pumpAndSettle();
    await shot('18-mission-detail');
    await tester.tap(find.byKey(const ValueKey<String>('top-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-2')));
    await tester.pumpAndSettle();
    await shot('19-market-list');
    await tester.tap(find.byKey(const ValueKey<String>('add-reward')));
    await tester.pumpAndSettle();
    await shot('20-market-add');
    await tester.tap(find.byKey(const ValueKey<String>('edit-market-form-image')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-title')),
      '抱抱券',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-description')),
      '兑换一个不限时长的抱抱',
    );
    await shot('21-market-add-image-filled');
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('save-reward')),
    );
    await shot('22-market-created');

    // 商城使用惰性 ListView；截图画廊只负责验证视觉状态，列表项点击本身
    // 已由 button_matrix_test 覆盖。这里按刚创建的数据 ID 进入详情，避免截图测试
    // 依赖该卡片此刻是否已被 ListView 构建到 widget tree。
    final Reward createdReward = store.rewards.firstWhere(
      (Reward item) => item.title == '抱抱券',
    );
    final BuildContext marketContext = tester.element(find.byType(MarketPage));
    Navigator.of(marketContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MarketDetailPage(
          store: store,
          rewardId: createdReward.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shot('23-market-detail');
    await tester.tap(find.byKey(const ValueKey<String>('top-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-3')));
    await tester.pumpAndSettle();
    await shot('24-account-dual');
    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('open-settings')),
    );
    await shot('25-settings-top');
    final Finder restore = find.byKey(const ValueKey<String>('webdav-restore'));
    await _tapVisible(tester, restore);
    await shot('26-settings-restore-dialog');
    await tester.tap(find.byKey(const ValueKey<String>('dialog-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('top-back')));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('open-ledger')),
    );
    await shot('27-point-ledger');
    await tester.tap(find.byKey(const ValueKey<String>('top-back')));
    await tester.pumpAndSettle();

    final InventoryItem? inventory = store.currentInventory.firstOrNull;
    if (inventory != null) {
      final BuildContext context = tester.element(find.byType(AccountPage));
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ItemDetailPage(store: store, itemId: inventory.id),
        ),
      );
      await tester.pumpAndSettle();
      await shot('28-item-detail');
      if (!inventory.used) {
        await _tapVisible(
          tester,
          find.byKey(const ValueKey<String>('use-inventory')),
        );
        await shot('29-item-use-dialog');
        await tester.tap(
          find.byKey(const ValueKey<String>('cancel-use-inventory')),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey<String>('top-back')));
      await tester.pumpAndSettle();
    }

    final Reward? buyable = store.rewards
        .where((Reward item) =>
            item.ownerId != store.currentUserId && item.available)
        .firstOrNull;
    if (buyable != null) {
      final BuildContext context = tester.element(find.byType(AccountPage));
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MarketDetailPage(store: store, rewardId: buyable.id),
        ),
      );
      await tester.pumpAndSettle();
      await shot('30-buyable-reward');
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('buy-reward')),
      );
      await shot('31-reward-after-buy');
    }
  });
}
