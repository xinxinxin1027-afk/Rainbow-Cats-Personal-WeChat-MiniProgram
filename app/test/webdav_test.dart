import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_cats/src/models.dart';
import 'package:rainbow_cats/src/store.dart';
import 'package:rainbow_cats/src/webdav.dart';

void main() {
  group('WebDAV', () {
    late _FakeDavServer server;

    setUp(() async {
      server = await _FakeDavServer.start();
    });

    tearDown(() async {
      await server.close();
    });

    test('连接、建目录、上传、下载和删除全部真实发送请求', () async {
      final AppSettings settings = AppSettings(
        webDavUrl: '${server.baseUrl}dav/root/',
        webDavUsername: 'alice',
        webDavPassword: 'secret',
        webDavRemoteDirectory: 'Rainbow Cats/备份',
        webDavFileName: 'data.json',
      );
      final WebDavClient client = WebDavClient(timeout: const Duration(seconds: 3));

      expect((await client.testConnection(settings)).ok, isTrue);
      expect((await client.upload(settings, '{"hello":"世界"}')).ok, isTrue);
      final RemoteOperationResult downloaded = await client.download(settings);
      expect(downloaded.ok, isTrue);
      expect(downloaded.body, '{"hello":"世界"}');
      expect((await client.deleteRemote(settings)).ok, isTrue);
      expect((await client.download(settings)).statusCode, 404);
      expect(server.methods, containsAll(<String>['MKCOL', 'PROPFIND', 'PUT', 'GET', 'DELETE']));
      expect(
        server.lastAuthorization,
        'Basic ${base64Encode(utf8.encode('alice:secret'))}',
      );
      expect(server.lastPath, contains('Rainbow%20Cats'));
    });

    test('首次同步创建备份，再同步会合并远端数据', () async {
      DateTime firstClock = DateTime(2026, 8, 11, 12);
      final RainbowStore first = RainbowStore(
        MemoryRainbowStorage(),
        clock: () => firstClock,
      )..seedForTest();
      await first.updateSettings(
        AppSettings(
          webDavUrl: server.baseUrl,
          webDavRemoteDirectory: 'RainbowCats',
          webDavFileName: 'sync.json',
        ),
      );
      final WebDavClient client = WebDavClient(timeout: const Duration(seconds: 3));
      final RemoteOperationResult firstResult = await client.synchronize(first);
      expect(firstResult.ok, isTrue);
      expect(firstResult.message, contains('首次同步'));

      DateTime secondClock = DateTime(2026, 8, 11, 13);
      final RainbowStore second = RainbowStore(
        MemoryRainbowStorage(),
        clock: () => secondClock,
      )..seedForTest();
      await second.addMember(name: '小雨', initialCredit: 7);
      await second.updateSettings(
        AppSettings(
          webDavUrl: server.baseUrl,
          webDavRemoteDirectory: 'RainbowCats',
          webDavFileName: 'sync.json',
        ),
      );
      expect((await client.synchronize(second)).ok, isTrue);
      expect(second.users.any((UserProfile user) => user.name == '小雨'), isTrue);
      expect(server.fileContent, contains('小雨'));
    });

    test('401、错误地址和无配置都会给出明确错误', () async {
      server.unauthorized = true;
      final WebDavClient client = WebDavClient(timeout: const Duration(seconds: 2));
      final AppSettings settings = AppSettings(webDavUrl: server.baseUrl);
      final RemoteOperationResult unauthorized = await client.testConnection(settings);
      expect(unauthorized.ok, isFalse);
      expect(unauthorized.message, contains('账号、密码或权限'));

      final RemoteOperationResult malformed = await client.testConnection(
        const AppSettings(webDavUrl: 'not-a-url'),
      );
      expect(malformed.ok, isFalse);
      expect(malformed.message, contains('http://'));

      final RainbowStore store = RainbowStore(MemoryRainbowStorage())..seedForTest();
      expect((await client.synchronize(store)).ok, isFalse);


      final int requestCount = server.methods.length;
      final RemoteOperationResult invalidFile = await client.upload(
        AppSettings(
          webDavUrl: server.baseUrl,
          webDavFileName: '../secret.json',
        ),
        '{}',
      );
      expect(invalidFile.ok, isFalse);
      expect(invalidFile.message, contains('路径分隔符'));
      expect(server.methods, hasLength(requestCount));
    });
  });

  test('Server 健康检查携带 Bearer Token', () async {
    final _FakeDavServer server = await _FakeDavServer.start();
    addTearDown(server.close);
    final ServerHealthClient client =
        ServerHealthClient(timeout: const Duration(seconds: 3));
    final RemoteOperationResult result = await client.test(
      AppSettings(serverUrl: server.baseUrl, serverToken: 'abc-token'),
    );
    expect(result.ok, isTrue);
    expect(server.lastAuthorization, 'Bearer abc-token');
    expect(server.lastPath, '/health');
  });
}

class _FakeDavServer {
  _FakeDavServer(this.server);

  final HttpServer server;
  final List<String> methods = <String>[];
  String? fileContent;
  String? lastAuthorization;
  String? lastPath;
  bool unauthorized = false;
  late final StreamSubscription<HttpRequest> _subscription;

  String get baseUrl => 'http://${server.address.host}:${server.port}/';

  static Future<_FakeDavServer> start() async {
    final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final _FakeDavServer fake = _FakeDavServer(server);
    fake._subscription = server.listen(fake._handle);
    return fake;
  }

  Future<void> _handle(HttpRequest request) async {
    methods.add(request.method);
    lastAuthorization = request.headers.value(HttpHeaders.authorizationHeader);
    lastPath = request.uri.toString();
    if (unauthorized) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }

    switch (request.method) {
      case 'MKCOL':
        request.response.statusCode = HttpStatus.created;
        break;
      case 'PROPFIND':
        request.response.statusCode = 207;
        request.response.write('<d:multistatus xmlns:d="DAV:"/>');
        break;
      case 'PUT':
        fileContent = await utf8.decoder.bind(request).join();
        request.response.statusCode = HttpStatus.created;
        break;
      case 'GET':
        if (request.uri.path == '/health') {
          request.response.statusCode = HttpStatus.ok;
          request.response.write('{"ok":true}');
        } else if (fileContent == null) {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response.statusCode = HttpStatus.ok;
          request.response.write(fileContent);
        }
        break;
      case 'DELETE':
        fileContent = null;
        request.response.statusCode = HttpStatus.noContent;
        break;
      default:
        request.response.statusCode = HttpStatus.methodNotAllowed;
    }
    await request.response.close();
  }

  Future<void> close() async {
    await _subscription.cancel();
    await server.close(force: true);
  }
}
