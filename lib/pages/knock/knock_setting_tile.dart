// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/knock.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class KnockSettingTile extends StatefulWidget {
  final Client client;
  const KnockSettingTile({super.key, required this.client});

  @override
  State<KnockSettingTile> createState() => _KnockSettingTileState();
}

class _KnockSettingTileState extends State<KnockSettingTile> {
  bool _saving = false;

  Future<void> _change(bool value) async {
    setState(() => _saving = true);
    try {
      await widget.client.setKnockEnabled(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save Knock. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: widget.client.accountDataLoading,
    builder: (context, loaded) => StreamBuilder(
      stream: widget.client.onSync.stream,
      builder: (context, _) => SwitchListTile.adaptive(
        key: const Key('knock_switch'),
        secondary: const Icon(Icons.front_hand_outlined),
        title: const Text('Knock'),
        subtitle: Text(
          _saving ? 'Saving for this account…' : 'On: new conversations and group invitations go to Requests. Existing chats keep working. Off: normal messaging in WeSay.',
        ),
        value: widget.client.knockEnabled,
        onChanged:
            _saving ||
                loaded.hasError ||
                loaded.connectionState == ConnectionState.waiting
            ? null
            : _change,
      ),
    ),
  );
}
