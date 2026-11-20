// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/widgets/wesay_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install has test defaults and no public homeserver', () async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.init(loadWebConfigFile: false);
    expect(AppSettings.applicationName.value, 'WeSay');
    expect(AppSettings.defaultHomeserver.value, isEmpty);
    expect(AppConfig.enableRegistration, isFalse);
    expect(AppConfig.enableBackgroundPush, isFalse);
    expect(AppSettings.autoSendErrorReports.value, isNot(true));
    expect(AppSettings.checkForUpdates.value, isFalse);
  });

  testWidgets('placeholder logo renders at the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: WeSayLogo(size: 64))),
    );
    expect(find.byType(WeSayLogo), findsOneWidget);
    expect(tester.getSize(find.byType(WeSayLogo)), const Size(64, 64));
    expect(tester.takeException(), isNull);
  });
}
