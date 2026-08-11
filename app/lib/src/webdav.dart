import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';
import 'store.dart';

class RemoteOperationResult {
  const RemoteOperationResult({
    required this.ok,
    required this.message,
    this.body,
    this.statusCode,
  });

  final bool ok;
  final String message;
  final String? body;
  final int? statusCode;
}

class WebDavClient {
  WebDavClient({this.timeout = const Duration(seconds: 18)});

  final Duration timeout;

  Future<RemoteOperationResult> testConnection(AppSettings settings) async {
    try {
      final RemoteOperationResult directory =
          await ensureRemoteDirectory(settings);
      if (!directory.ok) return directory;
      final Uri uri = _directoryUri(settings);
      final _HttpResult response = await _send(
        settings: settings,
        method: 'PROPFIND',
        uri: uri,
        headers: <String, String>{
          'Depth': '0',
          HttpHeaders.contentTypeHeader: 'application/xml; charset=utf-8',
        },
        body: _propFindBody,
      );
      if (_isSuccess(response.statusCode) || response.statusCode == 207) {
        return RemoteOperationResult(
          ok: true,
          message: 'WebDAV 连接成功（HTTP ${response.statusCode}）',
          statusCode: response.statusCode,
        );
      }
      return _failure('连接失败', response);
    } on Object catch (error) {
      return RemoteOperationResult(ok: false, message: _friendly(error));
    }
  }

  Future<RemoteOperationResult> upload(
    AppSettings settings,
    String content,
  ) async {
    try {
      // 先验证文件名和完整 URI，避免非法路径触发任何网络请求。
      final Uri fileUri = _fileUri(settings);
      final RemoteOperationResult directory = await ensureRemoteDirectory(settings);
      if (!directory.ok) return directory;
      final _HttpResult response = await _send(
        settings: settings,
        method: 'PUT',
        uri: fileUri,
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        },
        body: content,
      );
      if (_isSuccess(response.statusCode)) {
        return RemoteOperationResult(
          ok: true,
          message: '备份已上传到 $fileUri',
          statusCode: response.statusCode,
        );
      }
      return _failure('上传失败', response);
    } on Object catch (error) {
      return RemoteOperationResult(ok: false, message: _friendly(error));
    }
  }

  Future<RemoteOperationResult> download(AppSettings settings) async {
    try {
      final _HttpResult response = await _send(
        settings: settings,
        method: 'GET',
        uri: _fileUri(settings),
      );
      if (_isSuccess(response.statusCode)) {
        if (response.body.trim().isEmpty) {
          return const RemoteOperationResult(ok: false, message: '远端备份为空');
        }
        return RemoteOperationResult(
          ok: true,
          message: '备份下载成功',
          body: response.body,
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode == 404) {
        return const RemoteOperationResult(
          ok: false,
          message: '远端还没有 Rainbow Cats 备份',
          statusCode: 404,
        );
      }
      return _failure('下载失败', response);
    } on Object catch (error) {
      return RemoteOperationResult(ok: false, message: _friendly(error));
    }
  }

  Future<RemoteOperationResult> deleteRemote(AppSettings settings) async {
    try {
      final _HttpResult response = await _send(
        settings: settings,
        method: 'DELETE',
        uri: _fileUri(settings),
      );
      if (_isSuccess(response.statusCode) || response.statusCode == 404) {
        return const RemoteOperationResult(ok: true, message: '远端备份已删除');
      }
      return _failure('删除失败', response);
    } on Object catch (error) {
      return RemoteOperationResult(ok: false, message: _friendly(error));
    }
  }

  Future<RemoteOperationResult> ensureRemoteDirectory(
    AppSettings settings,
  ) async {
    try {
      final Uri base = _baseUri(settings);
      final List<String> remoteSegments = _remoteDirectorySegments(settings);
      final List<String> current = <String>[
        ...base.pathSegments.where((String value) => value.isNotEmpty),
      ];
      for (final String segment in remoteSegments) {
        current.add(segment);
        final Uri directory = base.replace(
          pathSegments: <String>[...current, ''],
          query: null,
          fragment: null,
        );
        final _HttpResult response = await _send(
          settings: settings,
          method: 'MKCOL',
          uri: directory,
        );
        if (!_isSuccess(response.statusCode) &&
            response.statusCode != 405 &&
            response.statusCode != 301 &&
            response.statusCode != 302) {
          return _failure('创建远端目录失败', response);
        }
      }
      return const RemoteOperationResult(ok: true, message: '远端目录可用');
    } on Object catch (error) {
      return RemoteOperationResult(ok: false, message: _friendly(error));
    }
  }

  Future<RemoteOperationResult> synchronize(
    RainbowStore store, {
    bool replaceLocal = false,
  }) async {
    final AppSettings settings = store.settings;
    if (!settings.hasWebDav) {
      return const RemoteOperationResult(
        ok: false,
        message: '请先填写 WebDAV 地址并保存',
      );
    }
    final RemoteOperationResult remote = await download(settings);
    if (remote.ok && remote.body != null) {
      final ActionResult merged = replaceLocal
          ? await store.replaceFromJson(remote.body!)
          : await store.mergeFromJson(remote.body!);
      if (!merged.ok) {
        return RemoteOperationResult(ok: false, message: merged.message);
      }
    } else if (remote.statusCode != 404) {
      return remote;
    }
    final RemoteOperationResult uploaded = await upload(
      store.settings,
      store.exportData(),
    );
    if (!uploaded.ok) return uploaded;
    return RemoteOperationResult(
      ok: true,
      message: remote.statusCode == 404
          ? '首次同步完成，已创建远端备份'
          : replaceLocal
              ? '已从远端恢复并重新上传'
              : '本机与远端数据已合并同步',
    );
  }

  Uri _baseUri(AppSettings settings) {
    final String value = settings.webDavUrl.trim();
    if (value.isEmpty) throw const FormatException('WebDAV 地址不能为空');
    final Uri uri = Uri.parse(value);
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('WebDAV 地址必须以 http:// 或 https:// 开头');
    }
    if (uri.host.isEmpty) throw const FormatException('WebDAV 地址缺少主机名');
    return uri;
  }

  Uri _directoryUri(AppSettings settings) {
    final Uri base = _baseUri(settings);
    final List<String> segments = <String>[
      ...base.pathSegments.where((String value) => value.isNotEmpty),
      ..._remoteDirectorySegments(settings),
      '',
    ];
    return base.replace(pathSegments: segments, query: null, fragment: null);
  }

  Uri _fileUri(AppSettings settings) {
    final String fileName = settings.webDavFileName.trim();
    if (fileName.isEmpty) throw const FormatException('远端文件名不能为空');
    if (fileName == '.' ||
        fileName == '..' ||
        fileName.contains('/') ||
        fileName.contains('\\')) {
      throw const FormatException('远端文件名不能包含路径分隔符');
    }
    final Uri directory = _directoryUri(settings);
    final List<String> segments = directory.pathSegments
        .where((String value) => value.isNotEmpty)
        .toList()
      ..add(fileName);
    return directory.replace(pathSegments: segments, query: null, fragment: null);
  }

  List<String> _remoteDirectorySegments(AppSettings settings) {
    final List<String> values = settings.webDavRemoteDirectory
        .split('/')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
    if (values.any((String value) => value == '.' || value == '..')) {
      throw const FormatException('Remote Path 不能包含 . 或 ..');
    }
    return values;
  }

  Future<_HttpResult> _send({
    required AppSettings settings,
    required String method,
    required Uri uri,
    Map<String, String> headers = const <String, String>{},
    String? body,
  }) async {
    final HttpClient client = HttpClient()..connectionTimeout = timeout;
    try {
      final HttpClientRequest request =
          await client.openUrl(method, uri).timeout(timeout);
      request.followRedirects = true;
      request.maxRedirects = 4;
      request.headers.set(HttpHeaders.userAgentHeader, 'RainbowCats/1.0 Android');
      request.headers.set(HttpHeaders.acceptHeader, '*/*');
      final String username = settings.webDavUsername.trim();
      if (username.isNotEmpty || settings.webDavPassword.isNotEmpty) {
        final String credentials = base64Encode(
          utf8.encode('$username:${settings.webDavPassword}'),
        );
        request.headers.set(HttpHeaders.authorizationHeader, 'Basic $credentials');
      }
      headers.forEach((String name, String value) {
        request.headers.set(name, value);
      });
      if (body != null) {
        final List<int> bytes = utf8.encode(body);
        request.contentLength = bytes.length;
        request.add(bytes);
      }
      final HttpClientResponse response = await request.close().timeout(timeout);
      final String responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(timeout, onTimeout: () => '');
      return _HttpResult(response.statusCode, responseBody);
    } finally {
      client.close(force: true);
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  RemoteOperationResult _failure(String prefix, _HttpResult response) {
    String detail;
    switch (response.statusCode) {
      case 401:
      case 403:
        detail = '账号、密码或权限不正确';
        break;
      case 404:
        detail = '地址或远端路径不存在';
        break;
      case 405:
        detail = '服务器不支持该 WebDAV 操作';
        break;
      default:
        detail = response.body.trim().isEmpty
            ? 'HTTP ${response.statusCode}'
            : 'HTTP ${response.statusCode}：${_short(response.body)}';
    }
    return RemoteOperationResult(
      ok: false,
      message: '$prefix：$detail',
      statusCode: response.statusCode,
    );
  }

  String _friendly(Object error) {
    if (error is FormatException) return error.message;
    if (error is TimeoutException) return '连接超时，请检查地址和网络';
    if (error is SocketException) return '无法连接服务器：${error.message}';
    if (error is HandshakeException) return 'HTTPS 证书校验失败';
    if (error is HttpException) return '网络请求失败：${error.message}';
    return '操作失败：$error';
  }

  String _short(String value) {
    final String clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= 120 ? clean : '${clean.substring(0, 120)}…';
  }

  static const String _propFindBody = '''<?xml version="1.0" encoding="utf-8" ?>
<d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>''';
}

class ServerHealthClient {
  ServerHealthClient({this.timeout = const Duration(seconds: 12)});

  final Duration timeout;

  Future<RemoteOperationResult> test(AppSettings settings) async {
    final String raw = settings.serverUrl.trim();
    if (raw.isEmpty) {
      return const RemoteOperationResult(ok: false, message: '请先填写 Server URL');
    }
    try {
      final Uri base = Uri.parse(raw);
      if (!base.hasScheme ||
          base.host.isEmpty ||
          (base.scheme != 'http' && base.scheme != 'https')) {
        throw const FormatException('Server URL 必须是 http:// 或 https:// 地址');
      }
      final Uri health = base.replace(
        pathSegments: <String>[
          ...base.pathSegments.where((String value) => value.isNotEmpty),
          'health',
        ],
        query: null,
        fragment: null,
      );
      final HttpClient client = HttpClient()..connectionTimeout = timeout;
      try {
        final HttpClientRequest request =
            await client.getUrl(health).timeout(timeout);
        if (settings.serverToken.trim().isNotEmpty) {
          request.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer ${settings.serverToken.trim()}',
          );
        }
        final HttpClientResponse response = await request.close().timeout(timeout);
        await response.drain().timeout(timeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return RemoteOperationResult(
            ok: true,
            message: 'Server 连接成功（HTTP ${response.statusCode}）',
            statusCode: response.statusCode,
          );
        }
        return RemoteOperationResult(
          ok: false,
          message: 'Server 返回 HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      } finally {
        client.close(force: true);
      }
    } on TimeoutException {
      return const RemoteOperationResult(ok: false, message: 'Server 连接超时');
    } on SocketException catch (error) {
      return RemoteOperationResult(ok: false, message: '无法连接 Server：${error.message}');
    } on FormatException catch (error) {
      return RemoteOperationResult(ok: false, message: error.message);
    } on Object catch (error) {
      return RemoteOperationResult(ok: false, message: 'Server 测试失败：$error');
    }
  }
}

class _HttpResult {
  const _HttpResult(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
