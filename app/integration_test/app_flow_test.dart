import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rainbow_cats/main.dart';
import 'package:rainbow_cats/src/media.dart';
import 'package:rainbow_cats/src/store.dart';

const String _image =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZeeQAAAAASUVORK5CYII=';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('主导航、双人模式、图片编辑、任务商品和设置完整操作',
      (WidgetTester tester) async {
    RainbowImagePicker.debugPickerOverride = () async => _image;
    addTearDown(() => RainbowImagePicker.debugPickerOverride = null);
    final RainbowStore store = RainbowStore(
      MemoryRainbowStorage(),
      clock: () => DateTime(2026, 8, 12, 12),
    )..seedForTest();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    expect(store.users.length, 2);
    expect(find.text('成员管理'), findsNothing);

    for (int index = 0; index < 4; index += 1) {
      await tester.tap(find.byKey(ValueKey<String>('bottom-tab-$index')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('edit-home-image-0')));
    await tester.pumpAndSettle();
    expect(RainbowMediaStore.instance.homeImageAt(0), _image);

    await tester.tap(find.text('待完成任务'));
    await tester.pumpAndSettle();
    expect(find.text('未完成'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('你好，卡比'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-mission')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '集成测试任务',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-mission')));
    await tester.pumpAndSettle();
    expect(store.missions.first.title, '集成测试任务');

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-reward')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('edit-market-form-image')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('reward-title')),
      '集成测试商品',
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-reward')));
    await tester.pumpAndSettle();
    expect(store.rewards.first.title, '集成测试商品');
    expect(store.rewards.first.imageAsset, _image);

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-3')));
    await tester.pumpAndSettle();
    expect(find.text('成员管理'), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('双人空间'), findsOneWidget);
    expect(find.text('WebDAV URL'), findsOneWidget);
    expect(find.text('成员管理'), findsNothing);
  });
}
