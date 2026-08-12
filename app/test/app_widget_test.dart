import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/main.dart';
import 'package:rainbow_cats/src/media.dart';
import 'package:rainbow_cats/src/store.dart';
import 'package:rainbow_cats/src/widgets.dart';

const String _testImage =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZeeQAAAAASUVORK5CYII=';

void main() {
  RainbowStore buildStore() => RainbowStore(
        MemoryRainbowStorage(),
        clock: () => DateTime(2026, 8, 12, 12),
      )..seedForTest();

  setUp(() {
    RainbowMediaStore.instance.resetForTest();
    RainbowImagePicker.debugPickerOverride = () async => _testImage;
  });

  tearDown(() {
    RainbowImagePicker.debugPickerOverride = null;
    RainbowMediaStore.instance.resetForTest();
  });

  testWidgets('四个底部入口可切换且没有异常', (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();
    for (int index = 0; index < 4; index += 1) {
      await tester.tap(find.byKey(ValueKey<String>('bottom-tab-$index')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('主页面使用圆角玻璃设计且不显示小程序顶部胶囊',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('更多，当前身份 卡比'), findsNothing);
    expect(find.text('你好，卡比'), findsOneWidget);
    expect(find.byType(GlassSurface), findsWidgets);
    expect(find.text('成员管理'), findsNothing);
  });

  testWidgets('首页统计入口进入任务后系统返回会回到首页',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('待完成任务'));
    await tester.pumpAndSettle();
    expect(find.text('未完成'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('你好，卡比'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('设置页保存 WebDAV 且成员管理已彻底移除',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-3')));
    await tester.pumpAndSettle();
    expect(find.text('成员管理'), findsNothing);
    expect(store.users.length, 2);

    await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('双人空间'), findsOneWidget);
    expect(find.text('成员管理'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('webdav-url')),
      'https://dav.example.test/root/',
    );
    await tester.drag(
      find.byKey(const ValueKey<String>('settings-scroll')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-settings')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.settings.webDavUrl, 'https://dav.example.test/root/');
  });

  testWidgets('任务新增后立即出现在任务列表', (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-mission')));
    await tester.pumpAndSettle();
    expect(find.byType(RainbowTopBar), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '新的任务',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-mission')));
    await tester.pumpAndSettle();

    expect(store.missions.first.title, '新的任务');
    expect(find.text('新的任务'), findsOneWidget);
  });

  testWidgets('首页图片右下角编辑按钮可以替换图片', (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('edit-home-image-0')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(RainbowMediaStore.instance.homeImageAt(0), _testImage);
    expect(tester.takeException(), isNull);
  });

  testWidgets('新增商品页是圆角玻璃顶栏且上传图片会保存到商品',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-reward')));
    await tester.pumpAndSettle();

    expect(find.text('添加新商品'), findsOneWidget);
    expect(find.byType(RainbowTopBar), findsOneWidget);
    expect(find.byType(GlassSurface), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('edit-market-form-image')));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-title')),
      '晚安券',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -620));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('save-reward')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('save-reward')));
    await tester.pumpAndSettle();

    expect(store.rewards.first.title, '晚安券');
    expect(store.rewards.first.imageAsset, _testImage);
  });
}
