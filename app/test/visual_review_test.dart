import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pages=<String,Widget Function(AppStore)>{
    '01_home':(s)=>HomePage(s),'02_mission':(s)=>MissionPage(s),'03_mission_add':(s)=>MissionEditor(s),
    '04_mission_detail':(s)=>MissionDetail(s,s.missions.first),'05_market':(s)=>MarketPage(s),'06_market_add':(s)=>RewardEditor(s),
    '07_market_detail':(s)=>RewardDetail(s,s.rewards.first),'08_account':(s)=>AccountPage(s),
    '09_item_detail':(s)=>ItemDetail(s,Item('i','a','奶茶券','兑换一杯喜欢的奶茶',30)),
  };
  for(final e in pages.entries){
    testWidgets('视觉稿 ${e.key}',(tester)async{
      await tester.binding.setSurfaceSize(const Size(393,852));
      final s=AppStore()..ready=true;
      await tester.pumpWidget(MaterialApp(theme:ThemeData(useMaterial3:false,scaffoldBackgroundColor:bg),home:RepaintBoundary(key:const Key('shot'),child:e.value(s))));
      await tester.pump();
      await expectLater(find.byKey(const Key('shot')),matchesGoldenFile('../visual_review/goldens/${e.key}.png'));
    });
  }
}
