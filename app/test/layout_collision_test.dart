import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/src/pages.dart';
import 'package:rainbow_cats/src/store.dart';
import 'package:rainbow_cats/src/theme.dart';
import 'package:rainbow_cats/src/widgets.dart';

void main() {
  const List<String> pageNames = <String>[
    '首页',
    '任务',
    '任务新增',
    '任务详情',
    '商城',
    '商品新增',
    '商品详情',
    '仓库',
    '物品详情',
    '设置与同步',
    '积分明细',
  ];
  final List<Size> sizes = <Size>[
    const Size(320, 568),
    const Size(360, 640),
    const Size(393, 852),
    const Size(411, 891),
    const Size(480, 960),
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
            clock: () => DateTime(2026, 8, 12, 12),
          )..seedForTest();
          final List<Widget> pages = buildVisualPages(store);
          expect(pages.length, pageNames.length);
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: RainbowTheme.light,
              builder: (BuildContext context, Widget? child) => LiquidBackground(
                child: child ?? const SizedBox.shrink(),
              ),
              home: pages[index],
            ),
          );
          await tester.pump(const Duration(milliseconds: 420));
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${pageNames[index]} @ ${size.width}x${size.height} 出现布局/渲染异常',
          );
        },
      );
    }
  }
}
