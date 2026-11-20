// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

typedef HomeserverProbeResult = ({
  Uri address,
  List<LoginFlow> loginFlows,
  GetAuthMetadataResponse? authMetadata,
});

class HomeserverProbeCancelled implements Exception {}

/// An isolated, cancellable pre-login check using the existing Matrix SDK.
/// No account tokens or encryption keys are copied to this temporary client.
class HomeserverProbe {
  final Duration timeout;
  final http.Client Function() _transportFactory;
  final Completer<void> _cancelSignal = Completer<void>();
  http.Client? _transport;
  bool _cancelled = false;
  bool _started = false;

  HomeserverProbe({
    this.timeout = const Duration(seconds: 20),
    http.Client Function()? transportFactory,
  }) : _transportFactory = transportFactory ?? http.Client.new;

  void cancel() {
    _cancelled = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
    _transport?.close();
  }

  Future<HomeserverProbeResult> check(Client loginClient, Uri address) async {
    if (_cancelled) throw HomeserverProbeCancelled();
    if (_started) throw StateError('Use a fresh connection attempt to retry.');
    _started = true;
    final transport = _transport = _transportFactory();
    final probe = Client(
      'WeSay pre-login server check',
      // An unauthenticated check does not read/write the SDK database cache.
      // dispose(closeDatabase: false) preserves the real client's database.
      database: loginClient.database,
      httpClient: transport,
      supportedLoginTypes: loginClient.supportedLoginTypes,
    );
    Future<HomeserverProbeResult> discover() async {
      final (_, _, flows, metadata) = await probe.checkHomeserver(
        address,
        fetchAuthMetadata: true,
      );
      final resolved = probe.homeserver;
      if (resolved == null) throw const FormatException('No homeserver found.');
      return (address: resolved, loginFlows: flows, authMetadata: metadata);
    }

    try {
      final result = await Future.any<HomeserverProbeResult>([
        discover(),
        _cancelSignal.future.then<HomeserverProbeResult>(
          (_) => throw HomeserverProbeCancelled(),
        ),
      ]).timeout(timeout);
      if (_cancelled) throw HomeserverProbeCancelled();
      return result;
    } finally {
      // Future.timeout alone would leave HTTP requests running. Closing this
      // dedicated transport also prevents late discovery from touching the
      // real login client or a later attempt.
      transport.close();
      _transport = null;
      await probe.dispose(closeDatabase: false);
    }
  }
}
