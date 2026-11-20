// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/signup_preview/signup_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapVisible(WidgetTester tester, String label) async {
  final target = find.text(label).hitTestable();
  for (var attempt = 0; attempt < 30 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offline demo cannot accept real numbers or sign users in', (
    tester,
  ) async {
    var signInRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SignupPreview(onTestSignIn: () => signInRequests++),
      ),
    );
    expect(find.text('No SMS is sent. No account is created.'), findsOneWidget);
    await tapVisible(tester, 'Get started');
    final phone = tester.widget<TextFormField>(
      find.byKey(const ValueKey('demo-phone')),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
    expect(phone.initialValue, '0000000000');
    await tapVisible(tester, 'Continue with demo number');
    expect(signInRequests, 0);
    await tapVisible(tester, 'Restart preview');
    expect(find.text('Get started'), findsOneWidget);
    expect(find.textContaining('Preview complete.'), findsNothing);
    await tapVisible(tester, 'Sign in with an existing test account');
    expect(signInRequests, 1);
  });

  testWidgets('small screen and large text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: SignupPreview(onTestSignIn: () {}),
      ),
    );
    await tapVisible(tester, 'Get started');
    await tapVisible(tester, 'Continue with demo number');
    await tapVisible(tester, 'Restart preview');
    expect(tester.takeException(), isNull);
    await tapVisible(tester, 'Get started');
    await tester.tap(find.byTooltip('Back to welcome'));
    await tester.pumpAndSettle();
    expect(find.text('Say hello with WeSay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
