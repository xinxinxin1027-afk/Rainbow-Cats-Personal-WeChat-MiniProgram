# Rainbow Cats Android v1.0.0

面向约 2～10 名熟人的轻量 Android 首版，优先完整复刻原微信小程序的页面层级、粉色视觉与任务/商城/仓库玩法。

## 当前功能

- 首页、任务、商城、仓库四个主入口；
- 原九页完整流程与返回栈；
- 任务和商品新增、编辑、星标、搜索、删除；
- 任务完成、积分变化、商品兑换、仓库使用记录；
- 最多 10 名成员和本地身份切换；
- 本地离线数据、JSON 备份和损坏恢复；
- WebDAV 连接、上传、下载、合并、恢复和删除；
- Server URL / Token / `/health` 预留；
- 12 页视觉基线、多尺寸布局检查和 Android Emulator 安装测试。

## 安装

下载 `rainbow-cats-android-universal.apk`，在 Android 系统中允许浏览器或文件管理器安装未知来源应用后直接安装。ARM64 手机也可下载体积更小的 `rainbow-cats-android-arm64-v8a.apk`。

首次启动会加载本地样例数据。右上角胶囊可以切换身份、管理成员、查看积分明细并配置 WebDAV。

## WebDAV

进入 **设置与 WebDAV**，填写 URL、Username、Password、Remote Path 和 File Name，保存后先执行“测试连接”。同步数据不会上传 WebDAV 密码或 Server Token。

## 限制

- 当前只发布 Android，不包含 iOS。
- WebDAV 是小规模 JSON 合并同步，不是即时聊天或实时协作服务器。
- Server API 只完成客户端配置与健康检查，核心功能不依赖服务器。
