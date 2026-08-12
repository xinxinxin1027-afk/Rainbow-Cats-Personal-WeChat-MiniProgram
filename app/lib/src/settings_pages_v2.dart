import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design.dart';
import 'models.dart';
import 'store.dart';
import 'webdav.dart';
import 'widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.store, super.key});

  final RainbowStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _webDavUrl;
  late final TextEditingController _webDavUsername;
  late final TextEditingController _webDavPassword;
  late final TextEditingController _remoteDirectory;
  late final TextEditingController _fileName;
  late final TextEditingController _serverUrl;
  late final TextEditingController _serverToken;

  final WebDavClient _webDav = WebDavClient();
  final ServerHealthClient _server = ServerHealthClient();
  bool _autoSync = false;
  bool _hidePassword = true;
  bool _hideToken = true;
  bool _busy = false;
  String _busyLabel = '';

  @override
  void initState() {
    super.initState();
    final AppSettings settings = widget.store.settings;
    _webDavUrl = TextEditingController(text: settings.webDavUrl);
    _webDavUsername = TextEditingController(text: settings.webDavUsername);
    _webDavPassword = TextEditingController(text: settings.webDavPassword);
    _remoteDirectory = TextEditingController(text: settings.webDavRemoteDirectory);
    _fileName = TextEditingController(text: settings.webDavFileName);
    _serverUrl = TextEditingController(text: settings.serverUrl);
    _serverToken = TextEditingController(text: settings.serverToken);
    _autoSync = settings.autoSync;
  }

  @override
  void dispose() {
    _webDavUrl.dispose();
    _webDavUsername.dispose();
    _webDavPassword.dispose();
    _remoteDirectory.dispose();
    _fileName.dispose();
    _serverUrl.dispose();
    _serverToken.dispose();
    super.dispose();
  }

  AppSettings get _formValue => AppSettings(
        webDavUrl: _webDavUrl.text.trim(),
        webDavUsername: _webDavUsername.text.trim(),
        webDavPassword: _webDavPassword.text,
        webDavRemoteDirectory: _remoteDirectory.text.trim().isEmpty
            ? 'RainbowCats'
            : _remoteDirectory.text.trim(),
        webDavFileName: _fileName.text.trim().isEmpty
            ? 'rainbow-cats-data.json'
            : _fileName.text.trim(),
        autoSync: _autoSync,
        serverUrl: _serverUrl.text.trim(),
        serverToken: _serverToken.text.trim(),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: <Widget>[
            RainbowTopBar(
              title: '设置与同步',
              store: widget.store,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 34),
                children: <Widget>[
                  RainbowCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: <Widget>[
                        const _SettingsGlyph(icon: Icons.favorite_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '双人空间',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${widget.store.users.take(2).map((UserProfile user) => user.name).join(' × ')} · 仅两个人使用',
                                style: const TextStyle(
                                  color: RainbowDesign.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CreditBadge(widget.store.currentUser.credit, compact: true),
                      ],
                    ),
                  ),
                  const SectionTitle('WebDAV 同步'),
                  RainbowCard(
                    child: Column(
                      children: <Widget>[
                        TextField(
                          key: const ValueKey<String>('webdav-url'),
                          controller: _webDavUrl,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'WebDAV URL',
                            hintText: 'https://dav.example.com/path/',
                            prefixIcon: Icon(Icons.cloud_outlined),
                          ),
                        ),
                        const SizedBox(height: 11),
                        TextField(
                          controller: _webDavUsername,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 11),
                        TextField(
                          controller: _webDavPassword,
                          obscureText: _hidePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              key: const ValueKey<String>('toggle-webdav-password'),
                              tooltip: _hidePassword ? '显示密码' : '隐藏密码',
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _remoteDirectory,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: '远端目录',
                                  hintText: 'RainbowCats',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _fileName,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: '文件名',
                                  hintText: 'rainbow-cats-data.json',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _autoSync,
                          onChanged: _busy
                              ? null
                              : (bool value) => setState(() => _autoSync = value),
                          title: const Text('启动时自动同步'),
                          subtitle: const Text('网络不可用时仍然优先使用本地数据'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledPinkButton(
                    key: const ValueKey<String>('save-settings'),
                    label: _busy ? _busyLabel : '保存全部设置',
                    icon: Icons.save_outlined,
                    enabled: !_busy,
                    onPressed: () => _save(showMessage: true),
                  ),
                  const SectionTitle('同步操作'),
                  _ActionGrid(
                    children: <Widget>[
                      _ActionButton(
                        key: const ValueKey<String>('webdav-test'),
                        icon: Icons.wifi_tethering_rounded,
                        label: '测试连接',
                        onPressed: _busy
                            ? null
                            : () => _remoteAction(
                                  '正在测试…',
                                  (AppSettings settings) => _webDav.testConnection(settings),
                                ),
                      ),
                      _ActionButton(
                        key: const ValueKey<String>('webdav-upload'),
                        icon: Icons.cloud_upload_outlined,
                        label: '上传备份',
                        onPressed: _busy
                            ? null
                            : () => _remoteAction(
                                  '正在上传…',
                                  (AppSettings settings) => _webDav.upload(
                                    settings,
                                    widget.store.exportData(),
                                  ),
                                ),
                      ),
                      _ActionButton(
                        key: const ValueKey<String>('webdav-sync'),
                        icon: Icons.sync_rounded,
                        label: '合并同步',
                        onPressed: _busy ? null : () => _sync(replaceLocal: false),
                      ),
                      _ActionButton(
                        key: const ValueKey<String>('webdav-restore'),
                        icon: Icons.cloud_download_outlined,
                        label: '远端恢复',
                        onPressed: _busy ? null : _confirmRemoteRestore,
                      ),
                      _ActionButton(
                        key: const ValueKey<String>('webdav-delete'),
                        icon: Icons.delete_outline_rounded,
                        label: '删远端备份',
                        danger: true,
                        onPressed: _busy ? null : _confirmDeleteRemote,
                      ),
                    ],
                  ),
                  const SectionTitle('可选 Server API'),
                  RainbowCard(
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _serverUrl,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Base URL',
                            hintText: 'https://api.example.com',
                            prefixIcon: Icon(Icons.dns_outlined),
                          ),
                        ),
                        const SizedBox(height: 11),
                        TextField(
                          controller: _serverToken,
                          obscureText: _hideToken,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'Token（可选）',
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              key: const ValueKey<String>('toggle-server-token'),
                              tooltip: _hideToken ? '显示 Token' : '隐藏 Token',
                              onPressed: () => setState(() => _hideToken = !_hideToken),
                              icon: Icon(
                                _hideToken
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey<String>('server-health'),
                            onPressed: _busy ? null : _testServer,
                            icon: const Icon(Icons.health_and_safety_outlined),
                            label: const Text('测试 /health'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.store.lastSyncMessage != null) ...<Widget>[
                    const SectionTitle('最近同步'),
                    RainbowCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            widget.store.lastSyncOk == true
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_off_outlined,
                            color: widget.store.lastSyncOk == true
                                ? RainbowDesign.sage
                                : RainbowDesign.danger,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(widget.store.lastSyncMessage!)),
                        ],
                      ),
                    ),
                  ],
                  const SectionTitle('本地数据'),
                  RainbowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          '2 人 · ${widget.store.missions.length} 个任务 · '
                          '${widget.store.rewards.length} 个商品 · '
                          '${widget.store.inventory.length} 个仓库记录',
                          style: const TextStyle(color: RainbowDesign.muted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey<String>('copy-backup'),
                          onPressed: _busy ? null : _copyBackup,
                          icon: const Icon(Icons.copy_all_outlined),
                          label: const Text('复制 JSON 备份'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const ValueKey<String>('import-backup'),
                          onPressed: _busy ? null : _importFromClipboard,
                          icon: const Icon(Icons.content_paste_go_outlined),
                          label: const Text('从剪贴板合并 JSON'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const ValueKey<String>('reset-data'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: RainbowDesign.danger,
                          ),
                          onPressed: _busy ? null : _confirmReset,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('重置为初始样例数据'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Rainbow Cats Android 1.0.0\n双人私用 · 本地优先 · WebDAV 可选同步',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: RainbowDesign.muted,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _save({required bool showMessage}) async {
    final ActionResult result = await widget.store.updateSettings(_formValue);
    if (!mounted || !showMessage) return;
    _show(result.ok, result.message);
  }

  Future<void> _remoteAction(
    String label,
    Future<RemoteOperationResult> Function(AppSettings settings) operation,
  ) async {
    setState(() {
      _busy = true;
      _busyLabel = label;
    });
    try {
      await widget.store.updateSettings(_formValue);
      final RemoteOperationResult result = await operation(widget.store.settings);
      widget.store.recordSyncResult(ok: result.ok, message: result.message);
      if (mounted) _show(result.ok, result.message);
    } on Object catch (error) {
      if (mounted) _show(false, '操作失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = '';
        });
      }
    }
  }

  Future<void> _sync({required bool replaceLocal}) => _remoteAction(
        replaceLocal ? '正在恢复…' : '正在同步…',
        (_) => _webDav.synchronize(widget.store, replaceLocal: replaceLocal),
      );

  Future<void> _confirmRemoteRestore() async {
    final bool confirmed = await _confirm(
      title: '从远端恢复',
      message: '远端备份将替换本机任务、商品、积分和仓库。WebDAV 设置会保留。',
      confirmLabel: '恢复',
    );
    if (confirmed) await _sync(replaceLocal: true);
  }

  Future<void> _confirmDeleteRemote() async {
    final bool confirmed = await _confirm(
      title: '删除远端备份',
      message: '只删除 WebDAV 上的 JSON 文件，本机数据不会变化。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!confirmed) return;
    await _remoteAction('正在删除…', _webDav.deleteRemote);
  }

  Future<void> _testServer() async {
    setState(() {
      _busy = true;
      _busyLabel = '正在测试…';
    });
    try {
      await widget.store.updateSettings(_formValue);
      final RemoteOperationResult result = await _server.test(widget.store.settings);
      if (mounted) _show(result.ok, result.message);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = '';
        });
      }
    }
  }

  Future<void> _copyBackup() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.store.exportData()));
      if (mounted) _show(true, 'JSON 备份已复制到剪贴板');
    } on Object catch (error) {
      if (mounted) _show(false, '无法写入剪贴板：$error');
    }
  }

  Future<void> _importFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String source = data?.text?.trim() ?? '';
    if (source.isEmpty) {
      if (mounted) _show(false, '剪贴板里没有 JSON');
      return;
    }
    final ActionResult result = await widget.store.mergeFromJson(source);
    if (mounted) _show(result.ok, result.message);
  }

  Future<void> _confirmReset() async {
    final bool confirmed = await _confirm(
      title: '重置本机数据',
      message: '会恢复两个人、任务、商城和仓库的样例数据；同步设置会保留。',
      confirmLabel: '重置',
      danger: true,
    );
    if (!confirmed) return;
    await widget.store.reset();
    if (mounted) _show(true, '本机数据已重置');
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: danger ? RainbowDesign.danger : RainbowDesign.accentDeep,
                ),
              ),
            ),
          ],
        ),
      ) ??
      false;

  void _show(bool ok, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: Colors.white),
              const SizedBox(width: 9),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

class _SettingsGlyph extends StatelessWidget {
  const _SettingsGlyph({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => GlassSurface(
        radius: 18,
        blur: 12,
        shadow: false,
        tint: RainbowDesign.accentSoft,
        padding: const EdgeInsets.all(11),
        child: Icon(icon, color: RainbowDesign.accentDeep, size: 23),
      );
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: children
                .map((Widget child) => SizedBox(width: width, child: child))
                .toList(),
          );
        },
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => RainbowCard(
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: danger ? RainbowDesign.danger : RainbowDesign.accentDeep,
              size: 21,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w650,
                  color: onPressed == null ? RainbowDesign.muted : RainbowDesign.text,
                ),
              ),
            ),
          ],
        ),
      );
}

class PointLedgerPage extends StatelessWidget {
  const PointLedgerPage({required this.store, super.key});
  final RainbowStore store;

  @override
  Widget build(BuildContext context) {
    final List<PointEntry> entries = store.currentPointEntries;
    final int income = entries
        .where((PointEntry item) => item.amount > 0)
        .fold<int>(0, (int sum, PointEntry item) => sum + item.amount);
    final int expense = entries
        .where((PointEntry item) => item.amount < 0)
        .fold<int>(0, (int sum, PointEntry item) => sum + item.amount.abs());
    return Scaffold(
      body: Column(
        children: <Widget>[
          RainbowTopBar(
            title: '积分明细',
            store: store,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
              children: <Widget>[
                RainbowCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(child: _LedgerMetric(label: '当前', value: store.currentUser.credit)),
                      const _MetricDivider(),
                      Expanded(child: _LedgerMetric(label: '累计获得', value: income)),
                      const _MetricDivider(),
                      Expanded(child: _LedgerMetric(label: '累计使用', value: expense)),
                    ],
                  ),
                ),
                SectionTitle('记录', count: entries.length),
                if (entries.isEmpty)
                  const EmptyState(label: '还没有积分记录')
                else
                  ...entries.map(
                    (PointEntry entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RainbowCard(
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: entry.amount >= 0
                                    ? RainbowDesign.sageSoft
                                    : RainbowDesign.accentSoft,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                entry.amount >= 0
                                    ? Icons.add_rounded
                                    : Icons.remove_rounded,
                                color: entry.amount >= 0
                                    ? const Color(0xFF607D5C)
                                    : RainbowDesign.accentDeep,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    entry.reason,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w650),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(entry.createdAt),
                                    style: const TextStyle(
                                      color: RainbowDesign.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${entry.amount >= 0 ? '+' : ''}${entry.amount}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: entry.amount >= 0
                                    ? const Color(0xFF607D5C)
                                    : RainbowDesign.accentDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerMetric extends StatelessWidget {
  const _LedgerMetric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: RainbowDesign.muted, fontSize: 11.5)),
        ],
      );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 34,
        color: RainbowDesign.lineWarm,
      );
}

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}
