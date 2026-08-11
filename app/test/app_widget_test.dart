import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/main.dart';
import 'package:rainbow_cats/src/store.dart';

void main() {
  RainbowStore buildStore() => RainbowStore(
        MemoryRainbowStorage(),
        clock: () => DateTime(2026, 8, 11, 12),
      )..seedForTest();

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

  testWidgets('可以从胶囊进入设置并保存 WebDAV 配置',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('更多，当前身份 卡比'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置与 WebDAV'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('webdav-url')),
      'https://dav.example.test/root/',
    );
    await tester.ensureVisible(find.text('保存全部设置'));
    await tester.tap(find.text('保存全部设置'));
    await tester.pumpAndSettle();
    expect(store.settings.webDavUrl, 'https://dav.example.test/root/');
    expect(find.text('设置已保存'), findsOneWidget);
  });

  testWidgets('任务新增后立即出现在任务列表', (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('bottom-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-mission')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('mission-title')),
      '新的任务',
    );
    await tester.tap(find.text('发布任务'));
    await tester.pumpAndSettle();

    expect(store.missions.first.title, '新的任务');
    expect(find.text('新的任务'), findsOneWidget);
  });

  testWidgets('成员管理支持新增第三名成员', (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(RainbowCatsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('更多，当前身份 卡比'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('成员管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加成员'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('member-name')),
      '小雨',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(store.users.any((user) => user.name == '小雨'), isTrue);
    expect(find.text('小雨'), findsOneWidget);
  });
}
