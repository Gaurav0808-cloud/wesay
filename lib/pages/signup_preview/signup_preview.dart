// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/widgets/wesay_logo.dart';
import 'package:flutter/material.dart';

/// Offline design preview. This widget cannot authenticate or create accounts.
class SignupPreview extends StatefulWidget {
  final VoidCallback onTestSignIn;

  const SignupPreview({super.key, required this.onTestSignIn});

  @override
  State<SignupPreview> createState() => _SignupPreviewState();
}

class _SignupPreviewState extends State<SignupPreview> {
  bool _phoneStep = false;
  bool _continued = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('WeSay'),
        leading: _phoneStep
            ? IconButton(
                tooltip: 'Back to welcome',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _phoneStep = false;
                  _continued = false;
                }),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Align(child: WeSayLogo(size: 88)),
                const SizedBox(height: 24),
                Text(
                  'Offline signup preview',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No SMS is sent. No account is created.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  _phoneStep ? 'Your phone number' : 'Say hello with WeSay',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  _phoneStep
                      ? 'Try the layout with a dummy number. Real phone sign-up is not available yet.'
                      : 'A simpler way to stay in touch. Preview the new welcome and signup screens without connecting to a server.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (_phoneStep) ...[
                  const Text('Country'),
                  const SizedBox(height: 8),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.public),
                    title: Text('India'),
                    trailing: Text('+91'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('demo-phone'),
                    initialValue: '0000000000',
                    readOnly: true,
                    enableInteractiveSelection: false,
                    decoration: InputDecoration(
                      labelText: 'Dummy phone number',
                      prefixText: '+91 ',
                      helperText: 'Fixed test data. Do not enter a real number.',
                      helperMaxLines: 3,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _continued
                        ? null
                        : () => setState(() => _continued = true),
                    child: const Text('Continue with demo number'),
                  ),
                  if (_continued) ...[
                    const SizedBox(height: 24),
                    Semantics(
                      liveRegion: true,
                      child: const Text(
                        'Preview complete. Phone verification and account creation are not connected. No code was sent.',
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _phoneStep = false;
                        _continued = false;
                      }),
                      child: const Text('Restart preview'),
                    ),
                  ],
                ] else
                  FilledButton(
                    onPressed: () => setState(() => _phoneStep = true),
                    child: const Text('Get started'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.onTestSignIn,
                  child: const Text('Sign in with an existing test account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
