import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/src/pages.dart';
import 'package:rainbow_cats/src/store.dart';

void main() {
  final List<Size> sizes = <Size>[
    const Size(320, 568),
    const Size(360, 640),
    const Size(393, 852),
    const Size(411, 891),
  ];

  for (final Size size in sizes) {
    for (int index = 0; index < pageNames.length; index += 1) {
      testWidgets(
        '${pageNames[index]} 在 ${size.width}x${size.height} 无布局异常',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final RainbowStore store = RainbowStore(
            MemoryRainbowStorage(),
            clock: () => DateTime(2026, 8, 10, 12),
          )..seedForTest();
          final List<Widget> pages = buildVisualPages(store);
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              home: pages[index],
            ),
          );
          await tester.pump(const Duration(milliseconds: 250));
          final Object? exception = tester.takeException();
          expect(
            exception,
            isNull,
            reason:
                '${pageNames[index]} @ ${size.width}x${size.height} 出现布局/渲染异常',
          );
        },
      );
    }
  }
}
