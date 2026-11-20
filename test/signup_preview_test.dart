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

Future<void> toVerification(WidgetTester tester) async {
  await tapVisible(tester, 'Get started');
  await tapVisible(tester, 'Continue with demo number');
}

Future<void> toProfile(WidgetTester tester) async {
  await toVerification(tester);
  await tapVisible(tester, 'Use sample code');
  await tapVisible(tester, 'Continue demo');
}

void main() {
  testWidgets('full dummy flow validates input and never signs in', (
    tester,
  ) async {
    var signInRequests = 0;
    await tester.pumpWidget(
      MaterialApp(home: SignupPreview(onTestSignIn: () => signInRequests++)),
    );
    expect(find.text('No SMS is sent. No account is created.'), findsOneWidget);
    await tapVisible(tester, 'Get started');
    final phone = tester.widget<TextFormField>(
      find.byKey(const ValueKey('demo-phone')),
    );
    expect(phone.initialValue, '0000000000');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
    await tapVisible(tester, 'Continue with demo number');
    await tester.enterText(find.byKey(const ValueKey('demo-code')), '123456');
    await tapVisible(tester, 'Continue demo');
    expect(
      find.text('Use the sample code 000000. No SMS was sent.'),
      findsOneWidget,
    );
    await tapVisible(tester, 'Use sample code');
    await tapVisible(tester, 'Continue demo');
    await tester.enterText(find.byKey(const ValueKey('demo-name')), '  ');
    await tapVisible(tester, 'Finish preview');
    expect(find.text('Enter a made-up name for the preview.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('demo-name')),
      'Test Mango',
    );
    await tester.tap(find.byTooltip('Avatar 2'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Finish preview');
    expect(find.text('Preview complete'), findsOneWidget);
    expect(find.text('Test Mango'), findsOneWidget);
    expect(find.byIcon(Icons.pets), findsOneWidget);
    expect(signInRequests, 0);
    await tapVisible(tester, 'Sign in with an existing test account');
    expect(signInRequests, 1);
  });

  testWidgets('restart clears sample code name and avatar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SignupPreview(onTestSignIn: () {})),
    );
    await toProfile(tester);
    await tester.enterText(
      find.byKey(const ValueKey('demo-name')),
      'Old sample',
    );
    await tester.tap(find.byTooltip('Avatar 3'));
    await tapVisible(tester, 'Finish preview');
    await tapVisible(tester, 'Restart preview');
    await toVerification(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('demo-code')))
          .controller!
          .text,
      isEmpty,
    );
    await tapVisible(tester, 'Use sample code');
    await tapVisible(tester, 'Continue demo');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('demo-name')))
          .controller!
          .text,
      'Demo user',
    );
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip).first).selected,
      isTrue,
    );
  });

  testWidgets('Android back returns to previous demo step', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SignupPreview(onTestSignIn: () {})),
    );
    await toProfile(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Demo verification'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous signup step'));
    await tester.pumpAndSettle();
    expect(find.text('Your phone number'), findsOneWidget);
  });

  testWidgets('full flow supports narrow screens and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: SignupPreview(onTestSignIn: () {}),
      ),
    );
    await toProfile(tester);
    await tapVisible(tester, 'Finish preview');
    await tapVisible(tester, 'Restart preview');
    expect(tester.takeException(), isNull);
    expect(find.text('Say hello with WeSay'), findsOneWidget);
  });
}
