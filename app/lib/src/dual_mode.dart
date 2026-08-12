import 'store.dart';

/// Rainbow Cats 当前产品形态固定为两个人。
///
/// 旧版曾允许 2~10 人，因此升级时可能读到历史多人快照。
/// 这里在应用入口和远端恢复后收敛到“当前用户 + 对方”两人，
/// 防止已经移除的成员管理能力通过旧数据重新出现。
extension RainbowDualMode on RainbowStore {
  Future<void> enforceDualUserMode() async {
    if (users.length <= 2) return;
    final String current = currentUserId;
    final String partnerId = users
        .firstWhere((user) => user.id != current, orElse: () => users.first)
        .id;
    final List<String> removeIds = users
        .where((user) => user.id != current && user.id != partnerId)
        .map((user) => user.id)
        .toList();
    for (final String id in removeIds) {
      await deleteMember(id);
    }
  }
}
