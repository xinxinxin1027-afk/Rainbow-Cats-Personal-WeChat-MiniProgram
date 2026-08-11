import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/main.dart';
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
    testWidgets('全部十二页在 ${size.width}x${size.height} 无布局异常',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final RainbowStore store = RainbowStore(
        MemoryRainbowStorage(),
        clock: () => DateTime(2026, 8, 10, 12),
      )..seedForTest();
      for (final Widget page in buildVisualPages(store)) {
        await tester.pumpWidget(
          RainbowCatsApp(
            store: store,
            visualReview: false,
            key: UniqueKey(),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: page,
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
