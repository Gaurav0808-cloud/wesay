// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/signup_preview/signup_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    final phone = tester.widget<TextFormField>(
      find.byKey(const ValueKey('demo-phone')),
    );
    expect(tester.widget<EditableText>(find.byType(EditableText)).readOnly, isTrue);
    expect(phone.initialValue, '0000000000');
    await tester.scrollUntilVisible(
      find.text('Continue with demo number'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continue with demo number'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Preview complete.'), findsOneWidget);
    expect(signInRequests, 0);
    await tester.ensureVisible(find.text('Restart preview'));
    await tester.tap(find.text('Restart preview'));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
    expect(find.textContaining('Preview complete.'), findsNothing);
    await tester.ensureVisible(
      find.text('Sign in with an existing test account'),
    );
    await tester.tap(find.text('Sign in with an existing test account'));
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
    await tester.scrollUntilVisible(
      find.text('Get started'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Continue with demo number'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continue with demo number'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Restart preview'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Back to welcome'));
    await tester.pumpAndSettle();
    expect(find.text('Say hello with WeSay'), findsOneWidget);
  });
}
