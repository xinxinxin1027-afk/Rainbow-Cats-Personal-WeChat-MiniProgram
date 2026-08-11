import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/original_style.dart';
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
    _remoteDirectory =
        TextEditingController(text: settings.webDavRemoteDirectory);
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
                children: <Widget>[
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
                            hintText:
                                'https://example.com/remote.php/dav/files/name/',
                            prefixIcon: Icon(Icons.cloud_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _webDavUsername,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _webDavPassword,
                          obscureText: _hidePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword ? '显示密码' : '隐藏密码',
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
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
                                controller: _remoteDirectory,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'Remote Path',
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
                                  labelText: 'File Name',
                                  hintText: 'rainbow-cats-data.json',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _autoSync,
                          onChanged: _busy
                              ? null
                              : (bool value) =>
                                  setState(() => _autoSync = value),
                          title: const Text('启动时自动同步'),
                          subtitle: const Text('失败时不会影响本地使用'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledPinkButton(
                    label: _busy ? _busyLabel : '保存全部设置',
                    icon: Icons.save_outlined,
                    enabled: !_busy,
                    onPressed: () => _save(showMessage: true),
                  ),
                  const SizedBox(height: 12),
                  _ActionGrid(
                    children: <Widget>[
                      _ActionButton(
                        icon: Icons.wifi_tethering_rounded,
                        label: '测试连接',
                        onPressed: _busy
                            ? null
                            : () => _remoteAction(
                                  '正在测试…',
                                  (AppSettings settings) =>
                                      _webDav.testConnection(settings),
                                ),
                      ),
                      _ActionButton(
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
                        icon: Icons.sync_rounded,
                        label: '合并同步',
                        onPressed: _busy
                            ? null
                            : () => _sync(replaceLocal: false),
                      ),
                      _ActionButton(
                        icon: Icons.cloud_download_outlined,
                        label: '远端恢复',
                        onPressed: _busy
                            ? null
                            : () => _confirmRemoteRestore(),
                      ),
                      _ActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: '删远端备份',
                        danger: true,
                        onPressed: _busy
                            ? null
                            : () => _confirmDeleteRemote(),
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
                        const SizedBox(height: 10),
                        TextField(
                          controller: _serverToken,
                          obscureText: _hideToken,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'Token（可选）',
                            prefixIcon:
                                const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              tooltip: _hideToken ? '显示 Token' : '隐藏 Token',
                              onPressed: () =>
                                  setState(() => _hideToken = !_hideToken),
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
                                ? const Color(0xFF4F9561)
                                : const Color(0xFFD14D5A),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.store.lastSyncMessage!,
                              style: const TextStyle(height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SectionTitle('本地数据'),
                  if (widget.store.lastStorageError != null) ...<Widget>[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F1),
                        borderRadius:
                            BorderRadius.circular(OriginalStyle.cardRadius),
                        border: Border.all(color: const Color(0xFFE9A1A8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFD14D5A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.store.lastStorageError!,
                              style: const TextStyle(
                                color: Color(0xFF9C3843),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  RainbowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          '${widget.store.users.length} 名成员 · '
                          '${widget.store.missions.length} 个任务 · '
                          '${widget.store.rewards.length} 个商品 · '
                          '${widget.store.inventory.length} 个仓库记录',
                          style: const TextStyle(
                            color: OriginalStyle.muted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _copyBackup,
                          icon: const Icon(Icons.copy_all_outlined),
                          label: const Text('复制 JSON 备份到剪贴板'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _importFromClipboard,
                          icon: const Icon(Icons.content_paste_go_outlined),
                          label: const Text('从剪贴板合并 JSON 备份'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD14D5A),
                          ),
                          onPressed: _busy ? null : _confirmReset,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('重置为初始样例数据'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Rainbow Cats Android 1.0.0\n数据默认只保存在本机，WebDAV 凭据不会上传到备份。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: OriginalStyle.muted,
                        height: 1.5,
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
      final RemoteOperationResult result =
          await operation(widget.store.settings);
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
        (_) => _webDav.synchronize(
          widget.store,
          replaceLocal: replaceLocal,
        ),
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
    await _remoteAction(
      '正在删除…',
      (AppSettings settings) => _webDav.deleteRemote(settings),
    );
  }

  Future<void> _testServer() async {
    setState(() {
      _busy = true;
      _busyLabel = '正在测试…';
    });
    try {
      await widget.store.updateSettings(_formValue);
      final RemoteOperationResult result =
          await _server.test(widget.store.settings);
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
      await Clipboard.setData(
        ClipboardData(text: widget.store.exportData()),
      );
      if (mounted) _show(true, 'JSON 备份已复制到剪贴板');
    } on Object catch (error) {
      if (mounted) _show(false, '无法写入剪贴板：$error');
    }
  }

  Future<void> _importFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      final String source = data?.text?.trim() ?? '';
      if (source.isEmpty) {
        if (mounted) _show(false, '剪贴板中没有文本');
        return;
      }
      final ActionResult result = await widget.store.mergeFromJson(source);
      if (mounted) _show(result.ok, result.message);
    } on Object catch (error) {
      if (mounted) _show(false, '无法读取剪贴板：$error');
    }
  }

  Future<void> _confirmReset() async {
    final bool confirmed = await _confirm(
      title: '重置本机数据',
      message: '本机任务、商品、积分和仓库会恢复为样例数据，已保存的连接设置会保留。',
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
              style: danger
                  ? TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD14D5A),
                    )
                  : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
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
                ok ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

class MemberManagementPage extends StatelessWidget {
  const MemberManagementPage({required this.store, super.key});

  final RainbowStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: <Widget>[
            RainbowTopBar(
              title: '成员管理',
              store: store,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: store,
                builder: (BuildContext context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                  children: <Widget>[
                    RainbowCard(
                      child: Text(
                        '当前 ${store.users.length} / ${RainbowStore.maxMembers} 名成员。'
                        '切换身份后，任务、积分、商城和仓库都会按该成员显示。',
                        style: const TextStyle(
                          color: OriginalStyle.muted,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SectionTitle('成员列表'),
                    ...store.users.map(
                      (UserProfile user) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RainbowCard(
                          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          child: Row(
                            children: <Widget>[
                              OriginalImage(
                                asset: user.avatarAsset,
                                width: 48,
                                height: 48,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Flexible(
                                          child: Text(
                                            user.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (user.id == store.currentUserId) ...<Widget>[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: OriginalStyle.primary
                                                  .withAlpha(28),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              '当前',
                                              style: TextStyle(
                                                color: OriginalStyle.primaryDark,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    CreditBadge(user.credit, compact: true),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: '成员操作',
                                onSelected: (String value) async {
                                  switch (value) {
                                    case 'switch':
                                      await store.switchUserTo(user.id);
                                      break;
                                    case 'edit':
                                      if (context.mounted) {
                                        await _editMember(context, user);
                                      }
                                      break;
                                    case 'delete':
                                      if (context.mounted) {
                                        await _deleteMember(context, user);
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  if (user.id != store.currentUserId)
                                    const PopupMenuItem<String>(
                                      value: 'switch',
                                      child: ListTile(
                                        dense: true,
                                        leading: Icon(Icons.login_rounded),
                                        title: Text('切换为此成员'),
                                      ),
                                    ),
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('编辑资料'),
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFD14D5A),
                                      ),
                                      title: Text('删除成员'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey<String>('add-member'),
          heroTag: 'add-member',
          onPressed: store.users.length >= RainbowStore.maxMembers
              ? null
              : () => _addMember(context),
          backgroundColor: OriginalStyle.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('添加成员'),
        ),
      );

  Future<void> _addMember(BuildContext context) async {
    final _MemberFormValue? value = await _memberDialog(
      context,
      title: '添加成员',
      name: '',
      credit: 0,
    );
    if (value == null) return;
    final ActionResult result = await store.addMember(
      name: value.name,
      initialCredit: value.credit,
    );
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _editMember(BuildContext context, UserProfile user) async {
    final _MemberFormValue? value = await _memberDialog(
      context,
      title: '编辑成员',
      name: user.name,
      credit: user.credit,
    );
    if (value == null) return;
    final ActionResult result = await store.updateMember(
      id: user.id,
      name: value.name,
      credit: value.credit,
    );
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _deleteMember(BuildContext context, UserProfile user) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text('删除 ${user.name}'),
            content: const Text('该成员发布的任务、商品、仓库和积分流水也会删除。'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD14D5A),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final ActionResult result = await store.deleteMember(user.id);
    if (context.mounted) _showResult(context, result);
  }

  Future<_MemberFormValue?> _memberDialog(
    BuildContext context, {
    required String title,
    required String name,
    required int credit,
  }) async {
    final TextEditingController nameController =
        TextEditingController(text: name);
    final TextEditingController creditController =
        TextEditingController(text: credit.toString());
    final DialogRoute<_MemberFormValue> route = DialogRoute<_MemberFormValue>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('member-name'),
              controller: nameController,
              maxLength: 12,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey<String>('member-credit'),
              controller: creditController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(labelText: '积分'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                _MemberFormValue(
                  nameController.text,
                  int.tryParse(creditController.text) ?? 0,
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final _MemberFormValue? result = await Navigator.of(context).push(route);
    await route.completed;
    nameController.dispose();
    creditController.dispose();
    return result;
  }

  void _showResult(BuildContext context, ActionResult result) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }
}

class PointLedgerPage extends StatelessWidget {
  const PointLedgerPage({required this.store, super.key});

  final RainbowStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: <Widget>[
            RainbowTopBar(
              title: '积分明细',
              store: store,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: store,
                builder: (BuildContext context, _) {
                  final List<PointEntry> entries = store.currentPointEntries;
                  if (entries.isEmpty) {
                    return const EmptyState(label: '还没有积分记录');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (BuildContext context, int index) {
                      final PointEntry entry = entries[index];
                      return RainbowCard(
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: (entry.amount >= 0
                                        ? OriginalStyle.primary
                                        : OriginalStyle.muted)
                                    .withAlpha(24),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                entry.amount >= 0
                                    ? Icons.add_rounded
                                    : Icons.remove_rounded,
                                color: entry.amount >= 0
                                    ? OriginalStyle.primaryDark
                                    : OriginalStyle.muted,
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateLabel(entry.createdAt),
                                    style: const TextStyle(
                                      color: OriginalStyle.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${entry.amount >= 0 ? '+' : ''}${entry.amount}',
                              style: TextStyle(
                                color: entry.amount >= 0
                                    ? OriginalStyle.primaryDark
                                    : const Color(0xFFD14D5A),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );

  static String _dateLabel(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
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
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          style: danger
              ? OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD14D5A),
                )
              : null,
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          label: Text(label, overflow: TextOverflow.ellipsis),
        ),
      );
}

class _MemberFormValue {
  const _MemberFormValue(this.name, this.credit);

  final String name;
  final int credit;
}
