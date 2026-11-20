// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/sign_in/view_model/model/public_homeserver_data.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/sign_in_flows/homeserver_probe.dart';
import 'package:fluffychat/utils/sign_in_flows/oidc_login.dart';
import 'package:fluffychat/utils/sign_in_flows/sso_login.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> connectToHomeserverFlow(
  PublicHomeserverData homeserverData,
  BuildContext context,
  void Function(AsyncSnapshot<bool>) setState,
  bool signUp, {
  HomeserverProbe? probe,
  bool Function()? isActive,
  Future<Client> Function()? loginClientLoader,
}) async {
  bool active() => context.mounted && (isActive?.call() ?? true);
  if (!active()) return;
  final attempt = probe ?? HomeserverProbe();
  setState(AsyncSnapshot.waiting());
  try {
    final homeserverInput = homeserverData.name!;
    var homeserver = Uri.parse(homeserverInput);
    if (homeserver.scheme.isEmpty) {
      homeserver = Uri.https(homeserverInput, '');
    }
    final l10n = L10n.of(context);
    final client =
        await (loginClientLoader?.call() ??
            Matrix.of(context).getLoginClient());
    if (!active()) return;
    final checked = await attempt.check(client, homeserver);
    if (!active()) return;
    // Only a successful, still-current attempt may update the real client.
    client.homeserver = checked.address;
    final loginFlows = checked.loginFlows;
    final authMetadata = checked.authMetadata;

    final regLink = homeserverData.regLink;
    final supportsSso = loginFlows.any((flow) => flow.type == 'm.login.sso');

    if ((kIsWeb || PlatformInfos.isLinux) &&
        (supportsSso || authMetadata != null || (signUp && regLink != null))) {
      if (!context.mounted || !active()) return;
      final consent = await showOkCancelAlertDialog(
        context: context,
        title: l10n.appWantsToUseForLogin(homeserverInput),
        message: l10n.appWantsToUseForLoginDescription,
        okLabel: l10n.continueText,
      );
      if (consent != OkCancelResult.ok) return;
      if (!context.mounted || !active()) return;
    }
    if (!context.mounted || !active()) return;

    if (authMetadata != null && AppSettings.enableMatrixNativeOIDC.value) {
      await oidcLoginFlow(client, context, signUp);
    } else if (supportsSso) {
      await ssoLoginFlow(client, context, signUp, loginFlows);
    } else {
      if (signUp && regLink != null) {
        await launchUrlString(regLink);
      }
      if (!context.mounted || !active()) return;
      final pathSegments = List.of(
        GoRouter.of(context).routeInformationProvider.value.uri.pathSegments,
      );
      if (pathSegments.last != 'home') pathSegments.removeLast();
      pathSegments.add('login');
      context.push('/${pathSegments.join('/')}', extra: client);
      setState(AsyncSnapshot.withData(ConnectionState.done, true));
      return;
    }

    if (!active()) return;
    await AppSettings.defaultHomeserver.setItem(homeserverInput);

    if (context.mounted && active()) {
      setState(AsyncSnapshot.withData(ConnectionState.done, true));
      context.go('/backup');
    }
  } on HomeserverProbeCancelled {
    return;
  } catch (e, s) {
    if (!active()) return;
    Logs().w('Unable to login', e, s);
    setState(AsyncSnapshot.withError(ConnectionState.done, e, s));
    if (!context.mounted || !active()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toLocalizedString(context, ExceptionContext.checkHomeserver),
        ),
      ),
    );
  } finally {
    attempt.cancel();
  }
}
