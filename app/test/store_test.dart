import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/main.dart';

void main() {
  test('只能完成对方任务且积分按原逻辑进入发布者', () {
    final s = AppStore()..ready = true;
    final mine = s.missions.firstWhere((m) => m.owner == s.current);
    expect(s.finish(mine), contains('只能'));
    final other = s.missions.firstWhere((m) => m.owner != s.current);
    final owner = s.users.firstWhere((u) => u.id == other.owner);
    final before = owner.credit;
    expect(s.finish(other), contains('任务完成'));
    expect(owner.credit, before + other.points);
    expect(s.finish(other), contains('已经完成'));
  });

  test('商品不能自购、积分不足会阻止、成功兑换进入仓库', () {
    final s = AppStore()..ready = true;
    final mine = s.rewards.firstWhere((r) => r.owner == s.current);
    expect(s.buy(mine), contains('不能购买'));
    final other = s.rewards.firstWhere((r) => r.owner != s.current);
    s.me.credit = 0;
    expect(s.buy(other), contains('积分不足'));
    s.me.credit = 100;
    expect(s.buy(other), '兑换成功');
    expect(s.items.single.owner, s.current);
    expect(s.buy(other), contains('已兑换'));
  });
}
