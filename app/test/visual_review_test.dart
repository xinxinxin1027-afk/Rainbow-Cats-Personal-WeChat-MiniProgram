import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/src/pages.dart';
import 'package:rainbow_cats/src/store.dart';
import 'package:rainbow_cats/src/theme.dart';

void main() {
  testWidgets('生成十二页视觉基线', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final RainbowStore store = RainbowStore(
      MemoryRainbowStorage(),
      clock: () => DateTime(2026, 8, 10, 12),
    )..seedForTest();
    final List<Widget> pages = buildVisualPages(store);
    for (int index = 0; index < pages.length; index += 1) {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: RainbowTheme.light,
          home: RepaintBoundary(
            key: ValueKey<String>('visual-page-$index'),
            child: pages[index],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byKey(ValueKey<String>('visual-page-$index')),
        matchesGoldenFile(
          '../visual_review/goldens/${VisualReviewCatalog.pageNames[index]}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
