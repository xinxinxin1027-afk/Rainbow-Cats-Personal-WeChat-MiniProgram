import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rainbow_cats/main.dart';
import 'package:rainbow_cats/src/store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('主导航、任务新增和设置入口可完整操作',
      (WidgetTester tester) async {
    final RainbowStore store = RainbowStore(
      MemoryRainbowStorage(),
      clock: () => DateTime(2026, 8, 11, 12),
    )..seedForTest();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    for (int index = 0; index < 4; index += 1) {
      await tester.tap(find.byKey(ValueKey<String>('bottom-tab-$index')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-mission')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '集成测试任务',
    );
    await tester.tap(find.text('发布任务'));
    await tester.pumpAndSettle();
    expect(store.missions.first.title, '集成测试任务');

    await tester.tap(find.bySemanticsLabel('更多，当前身份 卡比'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置与 WebDAV'));
    await tester.pumpAndSettle();
    expect(find.text('WebDAV URL'), findsOneWidget);
  });
}
