import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/src/settings_pages.dart';
import 'package:rainbow_cats/src/store.dart';
import 'package:rainbow_cats/src/theme.dart';
import 'package:rainbow_cats/src/widgets.dart';

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

Finder settingsScrollable() => find
    .descendant(
      of: find.byKey(const ValueKey<String>('settings-scroll')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> reveal(WidgetTester tester, Finder finder) async {
  final Finder scrollable = settingsScrollable();
  for (int index = 0; finder.evaluate().isEmpty && index < 32; index += 1) {
    await tester.drag(scrollable, const Offset(0, -180));
    await boundedSettle(tester);
  }
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: .28,
    duration: Duration.zero,
  );
  await tester.pump();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final Finder finder = find.byKey(ValueKey<String>(key));
  await reveal(tester, finder);
  await tester.tap(finder);
  await boundedSettle(tester);
  expect(tester.takeException(), isNull, reason: '设置按钮 $key 触发异常');
}

RainbowStore buildStore() => RainbowStore(
      MemoryRainbowStorage(),
      clock: () => DateTime(2026, 8, 12, 12),
    )..seedForTest();

Widget harness(RainbowStore store) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: RainbowTheme.light,
      builder: (BuildContext context, Widget? page) => LiquidBackground(
        child: page ?? const SizedBox.shrink(),
      ),
      home: SettingsPage(store: store),
    );

void main() {
  phoneTestWidgets('设置按钮：密码显示、自动同步、保存与 Token 显示',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(harness(store));
    await boundedSettle(tester);

    await tapKey(tester, 'toggle-webdav-password');
    await tapKey(tester, 'auto-sync-switch');
    await tapKey(tester, 'save-settings');
    await tester.pump(const Duration(seconds: 5));
    await tapKey(tester, 'toggle-server-token');

    expect(store.settings.autoSync, isTrue);
    expect(tester.takeException(), isNull);
  });

  phoneTestWidgets('设置按钮：WebDAV 无配置操作、确认弹窗与 Server 健康检查',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    await tester.pumpWidget(harness(store));
    await boundedSettle(tester);

    for (final String key in <String>[
      'webdav-test',
      'webdav-upload',
      'webdav-sync',
    ]) {
      await tapKey(tester, key);
      await tester.pump(const Duration(seconds: 5));
      await boundedSettle(tester);
    }

    for (final String key in <String>['webdav-restore', 'webdav-delete']) {
      await tapKey(tester, key);
      expect(find.byKey(const ValueKey<String>('dialog-cancel')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('dialog-cancel')));
      await boundedSettle(tester);
    }

    await tapKey(tester, 'server-health');
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  phoneTestWidgets('设置按钮：复制、剪贴板导入与重置确认',
      (WidgetTester tester) async {
    final RainbowStore store = buildStore();
    String clipboardText = '';
    final TestDefaultBinaryMessenger messenger =
        tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform,
        (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        final Object? arguments = call.arguments;
        if (arguments is Map<Object?, Object?>) {
          clipboardText = arguments['text']?.toString() ?? '';
        }
        return null;
      }
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': clipboardText};
      }
      if (call.method == 'Clipboard.hasStrings') return true;
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(harness(store));
    await boundedSettle(tester);

    await tapKey(tester, 'copy-backup');
    expect(clipboardText, isNotEmpty);
    await tester.pump(const Duration(seconds: 5));

    await tapKey(tester, 'import-backup');
    await tester.pump(const Duration(seconds: 5));
    expect(store.users.length, 2);

    await tapKey(tester, 'reset-data');
    expect(find.byKey(const ValueKey<String>('dialog-cancel')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('dialog-cancel')));
    await boundedSettle(tester);
    expect(tester.takeException(), isNull);
  });
}
