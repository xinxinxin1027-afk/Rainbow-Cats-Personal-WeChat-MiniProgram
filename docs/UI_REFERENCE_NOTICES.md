# UI 参考与许可说明

本项目的 2026 UI 重构参考了以下公开项目的视觉语言。此文件需要随相关派生 UI 代码保留。

## dwell-on-something

参考仓库：`xinwithyu/dwell-on-something`

参考内容：`web/index.html` 中的暖色纸张背景、圆角卡片、低对比度描边、浮动玻璃层级、轻阴影与留白比例。实现已转换为 Flutter / Material 组件，并根据 Rainbow Cats 的粉色品牌色重新设计。

上游采用 **PolyForm Noncommercial License 1.0.0**。本项目按情侣私人、非商业用途使用其设计/实现思路。依照上游 Required Notice 要求保留：

> Copyright 2026 xinwithyu (https://github.com/xinwithyu)

许可条款：https://polyformproject.org/licenses/noncommercial/1.0.0

若未来将 Rainbow Cats 用于商业用途，需要重新评估该参考实现的许可兼容性，或彻底替换对应派生部分。

## liquid-glass-effect-macos

参考仓库：`lucasromerodb/liquid-glass-effect-macos`

在本次检查时，该仓库未提供明确的 LICENSE 文件/许可证声明。因此 **没有复制其源码、CSS、着色器或其他可版权代码**。

Rainbow Cats 仅参考“液态玻璃”的公开视觉概念，在 Flutter 中独立实现：`BackdropFilter` 模糊、透明渐变、高光边缘、柔和阴影、背景色团与圆角层级。相关实现位于 `app/lib/src/design.dart` 与 `app/lib/src/widgets_v2.dart`。

## 本项目实现边界

- 不依赖 WebView 包装参考网页。
- 不运行上游 JavaScript/CSS。
- 所有交互、无障碍语义、图片选择、Android 返回生命周期仍为 Flutter/Android 原生实现。
- 图片编辑使用系统图片选择器；用户图片不会上传到第三方参考项目。
