# Rainbow Cats Android 开发与自检报告

## 1. 项目状态

本次实现保留原微信小程序，并在仓库根目录新增轻量 Flutter Android 客户端 `app/`。产品面向约 2～10 名熟人，不引入大型用户体系、微服务或复杂权限；核心功能离线可用，WebDAV 为可选的小规模备份与合并同步能力。

当前源码已完成业务实现、UI 页面、自动测试定义、Android/Gradle 平台配置、构建脚本和 Release 工作流。实际 Flutter 编译、APK 安装与 GitHub Release 必须以对应 GitHub Actions 运行结果为准；本报告不会把“门禁已配置”写成“门禁已通过”。实时证据见 `VALIDATION_STATUS.md`。

## 2. 代码结构

```text
app/lib/
├── main.dart                 启动、路由、自动同步
├── generated/               从原小程序生成的颜色、标题与资源索引
└── src/
    ├── models.dart           schema 2 模型、设置、删除标记
    ├── store.dart            业务规则、持久化、导入与合并
    ├── webdav.dart           WebDAV 与 Server /health
    ├── pages.dart            原九页及视觉检查目录
    ├── settings_pages.dart   设置、成员、积分明细
    ├── widgets.dart          顶栏、胶囊、卡片、Tab、滑动操作
    └── theme.dart            原视觉主题
```

状态管理保持为单个 `RainbowStore`；小数据量使用 `shared_preferences` 保存 JSON，不引入 ORM 或复杂状态框架。网络直接使用 `dart:io HttpClient`，生产依赖只有 Flutter SDK 与 `shared_preferences`。

## 3. UI 复刻

### 原九页

| 原页面 | Android 实现 |
|---|---|
| MainPage | 首页、成员头像、积分、轮播与快捷统计 |
| Mission | 搜索、未完成/已完成分组、星标、滑动操作与新增 |
| MissionAdd | 新增和编辑、短标题、说明与积分滑杆 |
| MissionDetail | 图片、信息、积分、完成、编辑、星标与删除 |
| Market | 搜索、商品卡片、星标、滑动操作与新增 |
| MarketAdd | 新增和编辑商品 |
| MarketDetail | 兑换、编辑、星标与删除 |
| Account | 当前成员、仓库、使用记录与快捷入口 |
| ItemDetail | 物品详情、使用与删除 |

另外新增三个不改变底部主导航层级的页面：设置与 WebDAV、成员管理、积分明细。

### 视觉来源与约束

构建脚本读取原仓库 `miniprogram/app.json`、页面 JSON、第一方 WXSS 和页面实际引用图片，生成：

- 原导航主色、页面背景与高频圆角；
- 原页面标题；
- Bottom Navigation 普通/选中图标；
- 首页和详情图片；
- Android 启动画面与应用图标回退。

第三方 `node_modules`、`miniprogram_npm` 与 WeUI 打包资源不会被整目录复制，避免 APK 膨胀。界面继续使用粉色顶部栏、微信胶囊式右上操作、白色圆角卡片、浅背景和原四栏结构，没有改成通用 Material 模板。

## 4. 功能完成情况

| 功能 | 源码状态 | 运行证据 |
|---|---|---|
| 四个主导航与原九页 | 已实现 | Widget / Integration / Emulator 门禁已编写 |
| 任务增删改查、搜索、星标、完成 | 已实现 | Store 与 Widget 测试已编写 |
| 原任务积分规则 | 已实现 | Store 测试已编写 |
| 商品增删改查、星标、兑换 | 已实现 | Store 与 Widget 测试已编写 |
| 仓库使用与删除 | 已实现 | Store 测试已编写 |
| 2～10 名成员 | 已实现 | 上下限、切换、编辑、级联删除测试已编写 |
| 本地持久化与 schema 1 迁移 | 已实现 | 恢复、迁移、写入失败测试已编写 |
| JSON 导入、替换、合并和回滚 | 已实现 | 无效 JSON 与结构错误回滚测试已编写 |
| WebDAV 设置与连接测试 | 已实现 | Widget 与本地 HTTP Server 测试已编写 |
| PROPFIND / MKCOL / PUT / GET / DELETE | 已实现 | 本地 HTTP Server 测试已编写 |
| WebDAV 合并、恢复和远端删除 | 已实现 | Store + DAV 测试已编写 |
| Server URL / Bearer Token /health | 客户端已实现 | 本地 HTTP Server 测试已编写 |
| APK Build / Install / Launch | 工作流已配置 | 必须查看真实 Actions 结果 |

## 5. 业务规则

- 设备当前选择一名成员身份操作，允许 2～10 名成员。
- 任务发布者不能完成自己的任务；其他成员完成后，积分按原项目逻辑计入任务发布者。
- 商品发布者不能兑换自己的商品；兑换从当前成员扣分，并生成当前成员仓库物品。
- 已完成任务和已兑换商品不能编辑。
- 完成任务和兑换商品有进行中锁，快速连点只能成功一次。
- 积分变化写入流水；成员手工调分也会产生记录。
- 删除成员会级联处理其任务、商品、库存和流水，并记录同步删除标记。

## 6. 数据与 WebDAV

- 本地数据为 schema 2 JSON 快照。
- 旧 schema 1 可以读取，并在保存时迁移。
- 同 ID 记录冲突时使用较新的 `updatedAt`。
- 积分流水按唯一 ID 合并。
- 删除使用一年期 tombstone，防止旧备份立即把已删除记录复活。
- 替换或合并失败会恢复完整回滚快照，避免半套数据。
- WebDAV URL、用户名、密码、Remote Path 和文件名均可配置。
- Remote Path 拒绝 `.` / `..`，文件名拒绝路径分隔符。
- 备份和同步 JSON 不包含 WebDAV 密码或 Server Token。
- 网络超时、401/403、404、405、非法 JSON、证书失败等均转为明确提示，不直接崩溃。
- Android Manifest 包含网络权限，并允许用户明确配置的局域网 HTTP WebDAV。

## 7. 稳定性处理

- 损坏本地 JSON 会恢复初始数据。
- 底层存储完全不可用时，App 仍可进入并在内存中继续操作，同时提示重启后可能丢失。
- 本地写入串行化；前一次写入失败不会永久阻塞后续保存。
- 页面异步操作检查 `mounted`，避免页面退出后使用无效 Context。
- 删除有确认弹窗；成功、失败、空数据和加载状态均有反馈。
- 320×568、360×640、393×852、411×891 四种视口纳入布局测试。
- 12 个页面纳入 Golden 与 Emulator 视觉巡检工作流。

## 8. 测试与 Release 门禁

Android CI 依次执行：

1. 纯源码结构检查；
2. 原资源与 Android 工程准备；
3. Dart 语法解析；
4. `flutter analyze --fatal-infos`；
5. Store、WebDAV、Widget 与四尺寸布局测试；
6. Debug / Release APK 构建；
7. `aapt`、`apksigner` 与 SHA-256 验证。

Release 工作流会重新执行上述门禁，并额外执行：

- 通用与 ARM64、ARMv7、x86_64 APK；
- 12 页 Golden 与静态联系表；
- Pixel 6 / Android API 35 安装最终 Release APK；
- 启动进程、四个底部入口、UI dump、截图与 Logcat；
- 12 页 Emulator 视觉巡检；
- Integration Test；
- 只有全部成功后才创建 GitHub Release。

## 9. 配置

### WebDAV

右上角胶囊 → 设置与 WebDAV，填写 URL、Username、Password、Remote Path 和 File Name。保存后可测试连接、上传本机、合并同步、从远端恢复或删除远端备份。

### Server

填写 Base URL 与可选 Token。连接测试请求 `${baseUrl}/health`，Token 使用 `Authorization: Bearer ...`。

### Android 签名

工作流支持固定 JKS Secrets：

- `RAINBOW_KEYSTORE_BASE64`
- `RAINBOW_KEYSTORE_PASSWORD`
- `RAINBOW_KEY_ALIAS`
- `RAINBOW_KEY_PASSWORD`

未配置时仍可生成侧载 APK；需要后续版本无缝覆盖安装时，应使用固定签名。

## 10. 版本与预期 Release 文件

- App 版本：`1.0.0+1`
- Tag：`v1.0.0`
- `rainbow-cats-android-universal.apk`
- `rainbow-cats-android-arm64-v8a.apk`
- `rainbow-cats-android-armeabi-v7a.apk`
- `rainbow-cats-android-x86_64.apk`
- `SHA256SUMS.txt`
- `BUILD_INFO.txt`
- `RELEASE_VALIDATION.md`
- APK badging、签名信息和视觉检查包

## 11. 已知限制

- 暂不开发 iOS。
- WebDAV 是小规模 JSON 合并，不提供实时消息、在线状态或协同编辑。
- 同一条记录在多设备同时修改时采用较新时间戳；设备时间严重错误会影响冲突选择。
- Server 业务 API 尚未定义，当前只提供配置与健康检查；核心 App 不依赖服务器。
- 实际编译、安装、截图和 GitHub Release 状态必须以真实 Actions 运行和 Release 页面为准。

## v1.0.0 最终实测交付

- Release：https://github.com/xinxinxin1027-afk/Rainbow-Cats-Personal-WeChat-MiniProgram/releases/tag/v1.0.0
- APK 源码 Commit：726e9c91fa7cb8620ff195d09bb14700e219443b
- GitHub Actions：https://github.com/xinxinxin1027-afk/Rainbow-Cats-Personal-WeChat-MiniProgram/actions/runs/31496582807
- Flutter 3.44.9 静态分析：✅
- Store / WebDAV / Widget / 48 个页面尺寸组合：✅
- Debug / Release / 分架构 APK 构建：✅
- APK metadata 与签名校验：✅
- Pixel 6 / Android API 35 安装并启动最终 Release APK：✅
- 最终 APK 四个主导航实际点击：✅
- Integration Test：✅
- 视觉基线与原版/Emulator 对照产物：✅
- Universal APK SHA-256：840fb28a91bf57ffaddf1f93c75c383ba12ea8441d3604c04441476c9ba8ba06
