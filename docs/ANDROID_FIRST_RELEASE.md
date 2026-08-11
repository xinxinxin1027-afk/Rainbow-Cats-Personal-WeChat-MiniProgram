# Rainbow Cats Android 1.0

## 产品范围

本应用服务约 2～10 名熟人，使用 Flutter 单代码库实现 Android 版本。原微信小程序完整保留，Android 客户端不依赖微信 OpenID 或微信云函数，默认离线可用；WebDAV 只负责小规模数据备份和合并同步。

## 页面层级

原九页全部保留：

1. 首页 `MainPage`
2. 任务列表 `Mission`
3. 发布/编辑任务 `MissionAdd`
4. 任务详情 `MissionDetail`
5. 商城列表 `Market`
6. 上架/编辑商品 `MarketAdd`
7. 商品详情 `MarketDetail`
8. 仓库 `Account`
9. 物品详情 `ItemDetail`

增加三个不改变主导航层级的实用页：

10. 设置与 WebDAV
11. 成员管理
12. 积分明细

## 业务规则

- 允许 2～10 名成员，设备当前选择一名身份操作。
- 任务发布者不能完成自己的任务；其他成员完成后，积分仍按原项目规则计入发布者。
- 商品发布者不能兑换自己的商品；兑换从当前成员扣分并产生仓库物品。
- 完成、兑换和使用操作均阻止快速重复执行。
- 删除会记录一年期 tombstone，WebDAV 合并时不会被旧备份立即复活。
- 同 ID 记录发生冲突时，以 `updatedAt` 较新的记录为准；积分流水按唯一 ID 合并。

## 数据与配置

- 主数据以 schema 2 JSON 快照保存在 `shared_preferences`。
- 可读取旧 schema 1 数据，并在下一次保存时迁移。
- WebDAV / Server 设置保存在本机。
- 导出和 WebDAV 同步不包含密码或 Token。
- Server API 当前仅预留 Base URL、Token 和 `/health`，不强制依赖服务器。

## 构建与发布门禁

Release 工作流只有在以下步骤全部成功后才会创建 Release：

1. `dart format --output=none` 完成 Dart 语法解析；
2. `flutter analyze --fatal-infos`；
3. 核心业务、WebDAV、Widget、四尺寸布局测试；
4. Release 和分 ABI APK 构建；
5. `aapt` 与 `apksigner` 验证；
6. Pixel 6 / Android API 35 安装最终 APK；
7. 启动进程检查；
8. 四个主 Tab 点击和截图；
9. 12 页视觉巡检；
10. Integration Test；
11. Logcat 中无 `FATAL EXCEPTION`。

输出包括通用 APK、ARM64/ARMv7/x86_64 APK、SHA-256、签名信息、构建信息和视觉检查压缩包。
