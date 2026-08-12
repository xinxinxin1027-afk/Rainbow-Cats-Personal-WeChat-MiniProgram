import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/main.dart';
import 'package:rainbow_cats/src/store.dart';

void main() {
  testWidgets('双人模式只能在双方身份之间切换且没有成员管理',
      (WidgetTester tester) async {
    final RainbowStore store = RainbowStore(
      MemoryRainbowStorage(),
      clock: () => DateTime(2026, 8, 12, 12),
    )..seedForTest();
    expect(store.users.length, 2);

    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-3')));
    await tester.pumpAndSettle();

    expect(find.text('成员管理'), findsNothing);
    final String firstId = store.currentUserId;
    final other = store.users.firstWhere((user) => user.id != firstId);

    await tester.tap(find.byKey(const ValueKey<String>('identity-switch')));
    await tester.pumpAndSettle();
    expect(find.text('这台手机是谁在用？'), findsOneWidget);
    expect(find.text('只在你们两个人之间切换，不会新增成员。'), findsOneWidget);
    await tester.tap(find.text(other.name).last);
    await tester.pumpAndSettle();
    expect(store.currentUserId, other.id);
    expect(find.text('成员管理'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('identity-switch')));
    await tester.pumpAndSettle();
    final first = store.users.firstWhere((user) => user.id == firstId);
    await tester.tap(find.text(first.name).last);
    await tester.pumpAndSettle();
    expect(store.currentUserId, firstId);
    expect(store.users.length, 2);
  });
}
