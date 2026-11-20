// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

class ConnectionControls extends StatelessWidget {
  final bool waiting;
  final bool hasError;
  final String continueLabel;
  final String cancelLabel;
  final VoidCallback onConnect;
  final VoidCallback onCancel;

  const ConnectionControls({
    super.key,
    required this.waiting,
    required this.hasError,
    required this.continueLabel,
    required this.cancelLabel,
    required this.onConnect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: waiting ? null : onConnect,
        child: waiting
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator.adaptive(
                  semanticsLabel: 'Connecting to server',
                ),
              )
            : Text(hasError ? 'Retry connection' : continueLabel),
      ),
      if (waiting) TextButton(onPressed: onCancel, child: Text(cancelLabel)),
    ],
  );
}
