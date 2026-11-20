// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/pages/sign_in/view_model/model/public_homeserver_data.dart';
import 'package:fluffychat/pages/sign_in/view_model/sign_in_state.dart';
import 'package:fluffychat/utils/sign_in_flows/check_homeserver.dart';
import 'package:fluffychat/utils/sign_in_flows/homeserver_probe.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

class SignInViewModel extends ValueNotifier<SignInState> {
  final MatrixState matrixService;
  final bool signUp;
  final HomeserverProbe Function() probeFactory;
  Future<Client>? _loginClientFuture;
  HomeserverProbe? _connection;
  int _connectionId = 0;
  bool _disposed = false;

  Future<Client> _createLoginClient() async {
    try {
      return await matrixService.getLoginClient();
    } catch (_) {
      _loginClientFuture = null;
      rethrow;
    }
  }

  Future<Client> _getLoginClient() =>
      _loginClientFuture ??= _createLoginClient();

  void cancelConnection() {
    _connectionId++;
    _connection?.cancel();
    _connection = null;
    if (!_disposed) setLoginLoading(const AsyncSnapshot.nothing());
  }

  Future<void> connect(
    BuildContext context,
    PublicHomeserverData server,
  ) async {
    if (value.loginLoading.connectionState == ConnectionState.waiting) return;
    final id = ++_connectionId;
    final attempt = _connection = probeFactory();
    bool current() => !_disposed && id == _connectionId;
    try {
      await connectToHomeserverFlow(
        server,
        context,
        (state) {
          if (current()) setLoginLoading(state);
        },
        signUp,
        probe: attempt,
        isActive: current,
        loginClientLoader: _getLoginClient,
      );
    } finally {
      if (current()) _connection = null;
    }
  }

  final TextEditingController filterTextController = TextEditingController();

  SignInViewModel(
    this.matrixService, {
    required this.signUp,
    this.probeFactory = HomeserverProbe.new,
  }) : super(SignInState()) {
    refreshPublicHomeservers();
    filterTextController.addListener(_filterHomeservers);
  }

  @override
  void dispose() {
    _disposed = true;
    cancelConnection();
    filterTextController.removeListener(_filterHomeservers);
    filterTextController.dispose();
    super.dispose();
  }

  void _filterHomeservers() {
    final filterText = filterTextController.text.trim().toLowerCase();
    final filteredPublicHomeservers =
        value.publicHomeservers.data
            ?.where(
              (homeserver) =>
                  homeserver.name?.toLowerCase().contains(filterText) ?? false,
            )
            .toList() ??
        [];
    if (filterText.length >= 3 &&
        (filterText.contains('.') || filterText.endsWith('localhost')) &&
        Uri.tryParse(filterText) != null &&
        !filteredPublicHomeservers.any(
          (homeserver) => homeserver.name == filterText,
        )) {
      filteredPublicHomeservers.add(PublicHomeserverData(name: filterText));
    }
    value.filteredPublicHomeservers = filteredPublicHomeservers;
    notifyListeners();
  }

  Future<void> refreshPublicHomeservers() async {
    // Test builds use only the configured server or a manually entered address.
    // Do not contact a public directory when opening the sign-in screen.
    final address = AppSettings.defaultHomeserver.value.trim();
    final servers = address.isEmpty
        ? <PublicHomeserverData>[]
        : [PublicHomeserverData(name: address)];
    value.selectedHomeserver = servers.isEmpty ? null : servers.first;
    value.publicHomeservers = AsyncSnapshot.withData(
      ConnectionState.done,
      servers,
    );
    _filterHomeservers();
  }

  void selectHomeserver(PublicHomeserverData? publicHomeserverData) {
    value.selectedHomeserver = publicHomeserverData;
    notifyListeners();
  }

  void setLoginLoading(AsyncSnapshot<bool> loginLoading) {
    if (_disposed) return;
    value.loginLoading = loginLoading;
    notifyListeners();
  }
}
