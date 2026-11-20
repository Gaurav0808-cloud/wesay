// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/widgets/wesay_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _PreviewStep { welcome, phone, verification, profile, complete }

/// Offline design preview, isolated from Matrix authentication and storage.
class SignupPreview extends StatefulWidget {
  final VoidCallback onTestSignIn;

  const SignupPreview({super.key, required this.onTestSignIn});

  @override
  State<SignupPreview> createState() => _SignupPreviewState();
}

class _SignupPreviewState extends State<SignupPreview> {
  static const _avatars = [Icons.face, Icons.pets, Icons.star_outline];
  final _code = TextEditingController();
  final _name = TextEditingController(text: 'Demo user');
  var _step = _PreviewStep.welcome;
  int _avatar = 0;
  String? _error;

  void _goTo(_PreviewStep step) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
  }

  void _back() => _goTo(_PreviewStep.values[_step.index - 1]);

  void _reset() {
    _code.clear();
    _name.text = 'Demo user';
    _avatar = 0;
    _goTo(_PreviewStep.welcome);
  }

  void _verifyDemoCode() {
    if (_code.text != '000000') {
      setState(() => _error = 'Use the sample code 000000. No SMS was sent.');
      return;
    }
    _goTo(_PreviewStep.profile);
  }

  void _finish() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter a made-up name for the preview.');
      return;
    }
    _goTo(_PreviewStep.complete);
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (_step) {
      _PreviewStep.welcome => 'Say hello with WeSay',
      _PreviewStep.phone => 'Your phone number',
      _PreviewStep.verification => 'Demo verification',
      _PreviewStep.profile => 'Try your profile',
      _PreviewStep.complete => 'Preview complete',
    };
    return PopScope(
      canPop: _step == _PreviewStep.welcome,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step != _PreviewStep.welcome) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WeSay'),
          leading: _step == _PreviewStep.welcome
              ? null
              : IconButton(
                  tooltip: 'Previous signup step',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                key: ValueKey(_step),
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
                  Text(title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  if (_step == _PreviewStep.welcome) ...[
                    const Text(
                      'Try the signup screens without connecting to a server. Use only the sample number and a made-up name.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => _goTo(_PreviewStep.phone),
                      child: const Text('Get started'),
                    ),
                  ],
                  if (_step == _PreviewStep.phone) ...[
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.public),
                      title: Text('India'),
                      trailing: Text('+91'),
                    ),
                    TextFormField(
                      key: const ValueKey('demo-phone'),
                      initialValue: '0000000000',
                      readOnly: true,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(
                        labelText: 'Dummy phone number',
                        prefixText: '+91 ',
                        helperText:
                            'Fixed test data. Do not enter a real number.',
                        helperMaxLines: 3,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => _goTo(_PreviewStep.verification),
                      child: const Text('Continue with demo number'),
                    ),
                  ],
                  if (_step == _PreviewStep.verification) ...[
                    const Text(
                      'No code was sent to +91 0000000000. Enter the sample code 000000 to try this screen. This does not verify a phone number.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('demo-code'),
                      controller: _code,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Demo code',
                        errorText: _error,
                        errorMaxLines: 4,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _code.text = '000000',
                      child: const Text('Use sample code'),
                    ),
                    FilledButton(
                      onPressed: _verifyDemoCode,
                      child: const Text('Continue demo'),
                    ),
                  ],
                  if (_step == _PreviewStep.profile) ...[
                    const Text(
                      'Use a made-up name and choose an avatar. This sample profile stays in this screen and is not saved to an account.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('demo-name'),
                      controller: _name,
                      maxLength: 32,
                      textCapitalization: TextCapitalization.words,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Made-up display name',
                        errorText: _error,
                        errorMaxLines: 3,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const Text('Choose a sample avatar'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _avatars.length; i++)
                          ChoiceChip(
                            label: Icon(_avatars[i]),
                            tooltip: 'Avatar ${i + 1}',
                            selected: _avatar == i,
                            onSelected: (_) => setState(() => _avatar = i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _finish,
                      child: const Text('Finish preview'),
                    ),
                  ],
                  if (_step == _PreviewStep.complete) ...[
                    Icon(_avatars[_avatar], size: 56),
                    const SizedBox(height: 16),
                    Text(_name.text.trim(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text(
                      'This was an offline demo. No phone number was verified, no account was created, and no profile was saved. Use an existing test account to test messaging.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _reset,
                      child: const Text('Restart preview'),
                    ),
                  ],
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
      ),
    );
  }
}
