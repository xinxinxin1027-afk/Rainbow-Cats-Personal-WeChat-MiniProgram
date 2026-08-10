import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/main.dart';

void main() {
  for (final size in <Size>[const Size(320,568),const Size(360,640),const Size(393,852),const Size(411,891)]) {
    testWidgets('核心页面无布局溢出 $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      final s=AppStore()..ready=true;
      for (final page in <Widget>[HomePage(s),MissionPage(s),MarketPage(s),AccountPage(s),MissionEditor(s),MissionDetail(s,s.missions.first),RewardEditor(s),RewardDetail(s,s.rewards.first)]) {
        await tester.pumpWidget(MaterialApp(theme:ThemeData(useMaterial3:false),home:page));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      final item=Item('i','a','测试物品','用于布局检查',10);
      await tester.pumpWidget(MaterialApp(home:ItemDetail(s,item)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
