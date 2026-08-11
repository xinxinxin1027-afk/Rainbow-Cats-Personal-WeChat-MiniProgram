import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rainbow_cats/main.dart';
import 'package:rainbow_cats/src/store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('主导航、返回历史、任务新增和设置入口可完整操作',
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

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-0')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text('发布任务'));
    await tester.pumpAndSettle();
    expect(store.missions.first.title, '集成测试任务');

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-3')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('设置同步'));
    await tester.tap(find.text('设置同步'));
    await tester.pumpAndSettle();
    expect(find.text('WebDAV URL'), findsOneWidget);
  });
}
