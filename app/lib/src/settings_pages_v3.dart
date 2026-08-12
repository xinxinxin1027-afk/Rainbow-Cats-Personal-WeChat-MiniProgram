import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design.dart';
import 'dual_mode.dart';
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
  late final TextEditingController _url;
  late final TextEditingController _user;
  late final TextEditingController _password;
  late final TextEditingController _directory;
  late final TextEditingController _file;
  late final TextEditingController _serverUrl;
  late final TextEditingController _serverToken;

  final WebDavClient _dav = WebDavClient();
  final ServerHealthClient _server = ServerHealthClient();
  bool _autoSync = false;
  bool _passwordHidden = true;
  bool _tokenHidden = true;
  bool _busy = false;
  String _busyLabel = '';

  @override
  void initState() {
    super.initState();
    final AppSettings value = widget.store.settings;
    _url = TextEditingController(text: value.webDavUrl);
    _user = TextEditingController(text: value.webDavUsername);
    _password = TextEditingController(text: value.webDavPassword);
    _directory = TextEditingController(text: value.webDavRemoteDirectory);
    _file = TextEditingController(text: value.webDavFileName);
    _serverUrl = TextEditingController(text: value.serverUrl);
    _serverToken = TextEditingController(text: value.serverToken);
    _autoSync = value.autoSync;
  }

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _password.dispose();
    _directory.dispose();
    _file.dispose();
    _serverUrl.dispose();
    _serverToken.dispose();
    super.dispose();
  }

  AppSettings get _settings => AppSettings(
        webDavUrl: _url.text.trim(),
        webDavUsername: _user.text.trim(),
        webDavPassword: _password.text,
        webDavRemoteDirectory:
            _directory.text.trim().isEmpty ? 'RainbowCats' : _directory.text.trim(),
        webDavFileName:
            _file.text.trim().isEmpty ? 'rainbow-cats-data.json' : _file.text.trim(),
        autoSync: _autoSync,
        serverUrl: _serverUrl.text.trim(),
        serverToken: _serverToken.text.trim(),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            RainbowTopBar(
              title: '设置与同步',
              store: widget.store,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey<String>('settings-scroll'),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 34),
                children: <Widget>[
                  RainbowCard(
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: RainbowDesign.accentSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: RainbowDesign.accentDeep,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '双人空间',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${widget.store.users.take(2).map((UserProfile u) => u.name).join(' × ')} · 固定两个人',
                                style: const TextStyle(
                                  color: RainbowDesign.muted,
                                  fontSize: 12,
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
                          controller: _url,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'WebDAV URL',
                            hintText: 'https://dav.example.com/path/',
                            prefixIcon: Icon(Icons.cloud_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey<String>('webdav-user'),
                          controller: _user,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey<String>('webdav-password'),
                          controller: _password,
                          obscureText: _passwordHidden,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              key: const ValueKey<String>('toggle-webdav-password'),
                              onPressed: () => setState(
                                () => _passwordHidden = !_passwordHidden,
                              ),
                              icon: Icon(
                                _passwordHidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                key: const ValueKey<String>('webdav-directory'),
                                controller: _directory,
                                decoration: const InputDecoration(
                                  labelText: '远端目录',
                                  hintText: 'RainbowCats',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                key: const ValueKey<String>('webdav-file'),
                                controller: _file,
                                decoration: const InputDecoration(
                                  labelText: '文件名',
                                  hintText: 'rainbow-cats-data.json',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile.adaptive(
                          key: const ValueKey<String>('auto-sync-switch'),
                          contentPadding: EdgeInsets.zero,
                          value: _autoSync,
                          onChanged: _busy
                              ? null
                              : (bool value) => setState(() => _autoSync = value),
                          title: const Text('启动时自动同步'),
                          subtitle: const Text('失败时仍然优先使用本地数据'),
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
                            : () => _remote(
                                  '正在测试…',
                                  (AppSettings s) => _dav.testConnection(s),
                                ),
                      ),
                      _ActionButton(
                        key: const ValueKey<String>('webdav-upload'),
                        icon: Icons.cloud_upload_outlined,
                        label: '上传备份',
                        onPressed: _busy
                            ? null
                            : () => _remote(
                                  '正在上传…',
                                  (AppSettings s) =>
                                      _dav.upload(s, widget.store.exportData()),
                                ),
                      ),
                      _ActionButton(
                        key: const ValueKey<String>('webdav-sync'),
                        icon: Icons.sync_rounded,
                        label: '合并同步',
                        onPressed: _busy ? null : () => _sync(false),
                      ),
                      _ActionButton(
                        key: const ValueKey<String>('webdav-restore'),
                        icon: Icons.cloud_download_outlined,
                        label: '远端恢复',
                        onPressed: _busy ? null : _confirmRestore,
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
                          key: const ValueKey<String>('server-url'),
                          controller: _serverUrl,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Base URL',
                            hintText: 'https://api.example.com',
                            prefixIcon: Icon(Icons.dns_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey<String>('server-token'),
                          controller: _serverToken,
                          obscureText: _tokenHidden,
                          decoration: InputDecoration(
                            labelText: 'Token（可选）',
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              key: const ValueKey<String>('toggle-server-token'),
                              onPressed: () =>
                                  setState(() => _tokenHidden = !_tokenHidden),
                              icon: Icon(
                                _tokenHidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                          onPressed: _busy ? null : _importBackup,
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
                        height: 1.55,
                        color: RainbowDesign.muted,
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
    final ActionResult result = await widget.store.updateSettings(_settings);
    if (mounted && showMessage) _show(result.ok, result.message);
  }

  Future<void> _remote(
    String label,
    Future<RemoteOperationResult> Function(AppSettings settings) operation,
  ) async {
    setState(() {
      _busy = true;
      _busyLabel = label;
    });
    try {
      await widget.store.updateSettings(_settings);
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

  Future<void> _sync(bool replace) async {
    await _remote(
      replace ? '正在恢复…' : '正在同步…',
      (_) => _dav.synchronize(widget.store, replaceLocal: replace),
    );
    await widget.store.enforceDualUserMode();
  }

  Future<void> _confirmRestore() async {
    if (await _confirm(
      title: '从远端恢复',
      message: '远端备份会替换本机任务、商城、积分和仓库，并自动收敛为两个人。',
      confirmLabel: '恢复',
    )) {
      await _sync(true);
    }
  }

  Future<void> _confirmDeleteRemote() async {
    if (!await _confirm(
      title: '删除远端备份',
      message: '只删除 WebDAV 上的 JSON，本机数据不变。',
      confirmLabel: '删除',
      danger: true,
    )) {
      return;
    }
    await _remote('正在删除…', _dav.deleteRemote);
  }

  Future<void> _testServer() async {
    setState(() {
      _busy = true;
      _busyLabel = '正在测试…';
    });
    try {
      await widget.store.updateSettings(_settings);
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
    await Clipboard.setData(ClipboardData(text: widget.store.exportData()));
    if (mounted) _show(true, 'JSON 备份已复制到剪贴板');
  }

  Future<void> _importBackup() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String source = data?.text?.trim() ?? '';
    if (source.isEmpty) {
      if (mounted) _show(false, '剪贴板里没有 JSON');
      return;
    }
    final ActionResult result = await widget.store.mergeFromJson(source);
    if (result.ok) await widget.store.enforceDualUserMode();
    if (mounted) _show(result.ok, result.message);
  }

  Future<void> _confirmReset() async {
    if (!await _confirm(
      title: '重置本机数据',
      message: '恢复双方、任务、商城与仓库的样例数据；同步设置会保留。',
      confirmLabel: '重置',
      danger: true,
    )) {
      return;
    }
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
              key: const ValueKey<String>('dialog-cancel'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              key: const ValueKey<String>('dialog-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: danger
                      ? RainbowDesign.danger
                      : RainbowDesign.accentDeep,
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
              Icon(
                ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 9),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
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
                  fontWeight: FontWeight.w600,
                  color: onPressed == null
                      ? RainbowDesign.muted
                      : RainbowDesign.text,
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
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          RainbowTopBar(
            title: '积分明细',
            store: store,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
              children: <Widget>[
                RainbowCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(child: _Metric(label: '当前', value: store.currentUser.credit)),
                      const _MetricDivider(),
                      Expanded(child: _Metric(label: '累计获得', value: income)),
                      const _MetricDivider(),
                      Expanded(child: _Metric(label: '累计使用', value: expense)),
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
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _date(entry.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: RainbowDesign.muted,
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11.5, color: RainbowDesign.muted)),
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

String _date(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}
