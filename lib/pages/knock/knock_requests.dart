// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/knock.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

/// A pending request deliberately uses plain IDs, without remote avatars,
/// room names, link previews, timelines or a message composer.
class KnockRequestTile extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  const KnockRequestTile({super.key, required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.front_hand_outlined),
    title: Text(
      knockInviter(room) ?? 'Unknown sender',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: const Text('New conversation or group invitation'),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class KnockRequestsPage extends StatelessWidget {
  const KnockRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return StreamBuilder(
      stream: client.onSync.stream,
      builder: (context, _) {
        final requests = client.knockRequests;
        return Scaffold(
          appBar: AppBar(title: const Text('Requests')),
          body: !client.knockEnabled
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Knock is off for this account. Invitations appear in the normal chat list.',
                    ),
                  ),
                )
              : requests.isEmpty
              ? const Center(child: Text('No pending requests'))
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, i) => KnockRequestTile(
                    room: requests[i],
                    onTap: () => context.push('/rooms/${requests[i].id}'),
                  ),
                ),
        );
      },
    );
  }
}

/// Guards the chat route itself, including links and notification navigation.
/// The normal chat/controller is constructed only after consent or with Knock off.
class KnockChatGate extends StatelessWidget {
  final Room room;
  final Widget Function() childBuilder;
  const KnockChatGate({
    super.key,
    required this.room,
    required this.childBuilder,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: room.client.accountDataLoading,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return const Scaffold(
          body: Center(
            child: Text(
              'Could not load account settings. Reopen the app to retry.',
            ),
          ),
        );
      }
      return StreamBuilder(
        stream: room.client.onSync.stream,
        builder: (context, _) {
          final current = room.client.getRoomById(room.id) ?? room;
          return current.client.isKnockRequest(current)
              ? KnockRequestPage(room: current)
              : childBuilder();
        },
      );
    },
  );
}

class KnockRequestPage extends StatefulWidget {
  final Room room;
  const KnockRequestPage({super.key, required this.room});

  @override
  State<KnockRequestPage> createState() => _KnockRequestPageState();
}

class _KnockRequestPageState extends State<KnockRequestPage> {
  bool _busy = false;
  String? _error;

  Future<void> _run(
    Future<void> Function(Room) action, {
    bool open = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(widget.room).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      context.go(open ? '/rooms/${widget.room.id}' : '/rooms/requests');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not complete this action. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block sender?'),
        content: const Text(
          'This blocks this Matrix account across your chats and declines this invitation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block sender'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _run(blockKnock);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Knock request')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.front_hand_outlined, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Someone wants to connect',
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 12),
          SelectableText(knockInviter(widget.room) ?? 'Unknown sender'),
          const SizedBox(height: 12),
          const Text(
            'Accept to join this conversation or group. Messages and media are not shown here before acceptance.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Only accept if you recognise the sender and want to join. A display name does not prove identity.',
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_busy) const Center(child: CircularProgressIndicator()),
          FilledButton(
            onPressed: _busy ? null : () => _run(acceptKnock, open: true),
            child: const Text('Accept'),
          ),
          OutlinedButton(
            onPressed: _busy ? null : () => _run(rejectKnock),
            child: const Text('Reject'),
          ),
          TextButton(
            onPressed: _busy || knockInviter(widget.room) == null
                ? null
                : _block,
            child: const Text('Block sender'),
          ),
        ],
      ),
    ),
  );
}
