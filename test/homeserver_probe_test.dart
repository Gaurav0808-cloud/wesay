// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/sign_in/view_model/model/public_homeserver_data.dart';
import 'package:fluffychat/pages/sign_in/view_model/sign_in_view_model.dart';
import 'package:fluffychat/utils/sign_in_flows/homeserver_probe.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoginService extends MatrixState {
  final Future<Client> pending;
  int calls = 0;
  _LoginService(this.pending);
  @override
  Future<Client> getLoginClient() {
    calls++;
    return pending;
  }
}

class _NoDatabase implements DatabaseApi {
  bool wasClosed = false;
  @override
  Future<void> close() async {
    wasClosed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transport extends MockClient {
  bool closed = false;
  _Transport(Future<http.Response> Function(http.Request) handler)
    : super(handler);
  @override
  void close() {
    closed = true;
    super.close();
  }
}

http.Response _json(Map<String, Object?> body, [int status = 200]) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

http.Response _normalResponse(http.Request request) {
  if (request.url.path.endsWith('/versions')) {
    return _json({
      'versions': [Client.supportedVersions.first],
    });
  }
  if (request.url.path.endsWith('/login')) {
    return _json({
      'flows': [
        {'type': 'm.login.password'},
      ],
    });
  }
  return _json({'errcode': 'M_UNRECOGNIZED', 'error': 'Not available'}, 404);
}

void main() {
  testWidgets(
    'cancel and retry share client initialization and never apply stale results',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppSettings.init(loadWebConfigFile: false);
      final pendingClient = Completer<Client>();
      final service = _LoginService(pendingClient.future);
      final networkStarted = Completer<void>();
      final vm = SignInViewModel(
        service,
        signUp: false,
        probeFactory: () => HomeserverProbe(
          transportFactory: () => _Transport((_) {
            if (!networkStarted.isCompleted) networkStarted.complete();
            return Completer<http.Response>().future;
          }),
        ),
      );
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = vm.connect(
        context,
        PublicHomeserverData(name: 'https://first.test.invalid'),
      );
      vm.cancelConnection();
      final second = vm.connect(
        context,
        PublicHomeserverData(name: 'https://second.test.invalid'),
      );
      expect(service.calls, 1);
      final client = Client('login', database: _NoDatabase())
        ..homeserver = Uri.https('prior.test.invalid', '');
      pendingClient.complete(client);
      await networkStarted.future;
      vm.cancelConnection();
      await Future.wait([first, second]);
      expect(vm.value.loginLoading.connectionState, ConnectionState.none);
      expect(vm.value.loginLoading.hasError, isFalse);
      expect(client.homeserver!.host, 'prior.test.invalid');
      vm.dispose();
    },
  );

  test(
    'discovery returns a checked server without modifying the real client or closing its database',
    () async {
      final db = _NoDatabase();
      final client = Client('login', database: db)
        ..homeserver = Uri.https('prior.test.invalid', '');
      final requests = <Uri>[];
      final transport = _Transport((request) async {
        requests.add(request.url);
        expect(request.headers['authorization'], isNull);
        return _normalResponse(request);
      });
      final result = await HomeserverProbe(
        transportFactory: () => transport,
      ).check(client, Uri.https('server.test.invalid', ''));
      expect(result.address.host, 'server.test.invalid');
      expect(result.loginFlows.single.type, 'm.login.password');
      expect(result.authMetadata, isNull);
      expect(client.homeserver!.host, 'prior.test.invalid');
      expect(db.wasClosed, isFalse);
      expect(transport.closed, isTrue);
      expect(requests.any((u) => u.path.endsWith('/versions')), isTrue);
    },
  );

  test('standard Matrix well-known delegation is preserved', () async {
    final client = Client('login', database: _NoDatabase());
    final transport = _Transport((request) async {
      if (request.url.path == '/.well-known/matrix/client') {
        return _json({
          'm.homeserver': {'base_url': 'https://delegate.test.invalid'},
        });
      }
      expect(request.url.host, 'delegate.test.invalid');
      return _normalResponse(request);
    });
    final result = await HomeserverProbe(
      transportFactory: () => transport,
    ).check(client, Uri.https('server.test.invalid', ''));
    expect(result.address.host, 'delegate.test.invalid');
    expect(client.homeserver, isNull);
  });

  test(
    'an unresponsive server times out and closes its dedicated connection',
    () async {
      final client = Client('login', database: _NoDatabase());
      final transport = _Transport((_) => Completer<http.Response>().future);
      final probe = HomeserverProbe(
        timeout: const Duration(milliseconds: 40),
        transportFactory: () => transport,
      );
      await expectLater(
        probe.check(client, Uri.https('offline.test.invalid', '')),
        throwsA(isA<TimeoutException>()),
      );
      expect(transport.closed, isTrue);
      expect(client.homeserver, isNull);
    },
  );

  test(
    'cancel promptly ends a pending check and a late response cannot change the real server',
    () async {
      final client = Client('login', database: _NoDatabase())
        ..homeserver = Uri.https('prior.test.invalid', '');
      final response = Completer<http.Response>();
      final started = Completer<void>();
      late _Transport transport;
      transport = _Transport((request) {
        if (transport.closed) throw http.ClientException('closed');
        if (!started.isCompleted) started.complete();
        return response.future;
      });
      final probe = HomeserverProbe(transportFactory: () => transport);
      final checking = probe.check(client, Uri.https('slow.test.invalid', ''));
      final cancelled = expectLater(
        checking,
        throwsA(isA<HomeserverProbeCancelled>()),
      );
      await started.future;
      probe.cancel();
      await cancelled.timeout(const Duration(seconds: 1));
      response.complete(
        _json({
          'm.homeserver': {'base_url': 'https://late.test.invalid'},
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(transport.closed, isTrue);
      expect(client.homeserver!.host, 'prior.test.invalid');
    },
  );

  test(
    'a cancelled attempt is not reusable and retry uses a new connection',
    () async {
      final client = Client('login', database: _NoDatabase());
      final cancelled = HomeserverProbe()..cancel();
      await expectLater(
        cancelled.check(client, Uri.https('server.test.invalid', '')),
        throwsA(isA<HomeserverProbeCancelled>()),
      );
      final result = await HomeserverProbe(
        transportFactory: () => _Transport((r) async => _normalResponse(r)),
      ).check(client, Uri.https('retry.test.invalid', ''));
      expect(result.address.host, 'retry.test.invalid');
    },
  );

  test('a server error is reported without changing the real client', () async {
    final client = Client('login', database: _NoDatabase())
      ..homeserver = Uri.https('prior.test.invalid', '');
    final transport = _Transport(
      (request) async =>
          _json({'errcode': 'M_UNKNOWN', 'error': 'Unavailable'}, 502),
    );
    await expectLater(
      HomeserverProbe(
        transportFactory: () => transport,
      ).check(client, Uri.https('offline.test.invalid', '')),
      throwsA(isA<Exception>()),
    );
    expect(client.homeserver!.host, 'prior.test.invalid');
    expect(transport.closed, isTrue);
  });
}
