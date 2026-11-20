// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/knock/knock_requests.dart';
import 'package:fluffychat/pages/knock/knock_setting_tile.dart';
import 'package:fluffychat/utils/knock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

class _UnusedDatabase implements DatabaseApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class KnockTestClient extends Client {
  final String owner;
  final writes = <Map<String, Object?>>[];
  final blocks = <String>[];
  bool failWrite = false;
  bool failBlock = false;

  KnockTestClient(this.owner)
    : super('Knock test $owner', database: _UnusedDatabase());
  @override
  String? get userID => owner;

  @override
  Future<void> setAccountData(
    String userId,
    String type,
    Map<String, Object?> body,
  ) async {
    if (failWrite) throw StateError('Offline');
    expect(userId, owner);
    expect(type, KnockAccount.eventType);
    writes.add(Map.of(body));
  }

  @override
  Future<void> ignoreUser(String userId, {bool leaveRooms = true}) async {
    if (failBlock) throw StateError('Offline');
    blocks.add(userId);
  }
}

class KnockTestRoom extends Room {
  int joins = 0;
  int leaves = 0;
  bool failJoin = false;

  KnockTestRoom(Client client, {super.membership = Membership.invite})
    : super(id: '!request:test.invalid', client: client) {
    setState(
      StrippedStateEvent.fromJson({
        'type': EventTypes.RoomMember,
        'state_key': client.userID,
        'sender': '@stranger:test.invalid',
        'content': {'membership': 'invite', 'is_direct': true},
      }),
      notifyRoomState: false,
    );
  }

  @override
  Future<void> join({
    bool leaveIfNotFound = true,
    bool waitForSync = false,
  }) async {
    if (failJoin) throw StateError('Offline');
    expect(waitForSync, isTrue);
    joins++;
    membership = Membership.join;
  }

  @override
  Future<void> leave({bool waitForSync = false}) async {
    expect(waitForSync, isTrue);
    leaves++;
    membership = Membership.leave;
  }
}

void main() {
  test(
    'off by default; enabling affects only this account and new invitations',
    () async {
      final alice = KnockTestClient('@alice:test.invalid');
      final bob = KnockTestClient('@bob:test.invalid');
      final pending = KnockTestRoom(alice);
      final joined = KnockTestRoom(alice, membership: Membership.join);
      alice.rooms.addAll([pending, joined]);
      expect(alice.isKnockRequest(pending), isFalse);
      await alice.setKnockEnabled(true);
      expect(alice.knockRequests, [pending]);
      expect(alice.isKnockRequest(joined), isFalse);
      expect(bob.knockEnabled, isFalse);
      expect(bob.isKnockRequest(pending), isFalse);
      await alice.setKnockEnabled(false);
      expect(alice.knockRequests, isEmpty);
      expect(pending.membership, Membership.invite);
      expect(pending.joins, 0);
      expect(pending.leaves, 0);
    },
  );

  test(
    'synced account data enables protection; a claimed direct flag grants no trust',
    () {
      final client = KnockTestClient('@alice:test.invalid');
      client.accountData[KnockAccount.eventType] = BasicEvent(
        type: KnockAccount.eventType,
        content: {'enabled': true, 'version': 1},
      );
      final room = KnockTestRoom(client);
      expect(room.isDirectChat, isTrue);
      expect(client.isKnockRequest(room), isTrue);
      room.states
          .clear(); // Group/space or unknown invite metadata is still gated.
      expect(client.isKnockRequest(room), isTrue);
    },
  );

  test('failed setting write keeps prior policy', () async {
    final client = KnockTestClient('@alice:test.invalid')..failWrite = true;
    await expectLater(client.setKnockEnabled(true), throwsStateError);
    expect(client.knockEnabled, isFalse);
    client.failWrite = false;
    await client.setKnockEnabled(true);
    client.failWrite = true;
    await expectLater(client.setKnockEnabled(false), throwsStateError);
    expect(client.knockEnabled, isTrue);
  });

  test(
    'accept joins only after explicit action and rejected/failed joins stay pending',
    () async {
      final client = KnockTestClient('@alice:test.invalid');
      final room = KnockTestRoom(client)..failJoin = true;
      await expectLater(acceptKnock(room), throwsStateError);
      expect(room.membership, Membership.invite);
      room.failJoin = false;
      await acceptKnock(room);
      expect(room.joins, 1);
      expect(room.membership, Membership.join);
      await expectLater(rejectKnock(room), throwsStateError);
    },
  );

  test(
    'reject leaves without blocking; failed block does not silently decline',
    () async {
      final client = KnockTestClient('@alice:test.invalid');
      final rejected = KnockTestRoom(client);
      await rejectKnock(rejected);
      expect(rejected.leaves, 1);
      expect(client.blocks, isEmpty);
      final blocked = KnockTestRoom(client);
      client.failBlock = true;
      await expectLater(blockKnock(blocked), throwsStateError);
      expect(blocked.leaves, 0);
      client.failBlock = false;
      await blockKnock(blocked);
      expect(client.blocks, ['@stranger:test.invalid']);
      expect(blocked.leaves, 1);
    },
  );

  testWidgets(
    'route guard never constructs normal chat before consent; off restores it',
    (tester) async {
      final client = KnockTestClient('@alice:test.invalid');
      final room = KnockTestRoom(client);
      await client.setKnockEnabled(true);
      var chatBuilds = 0;
      Widget app() => MaterialApp(
        home: KnockChatGate(
          room: room,
          childBuilder: () {
            chatBuilds++;
            return const Text('Normal chat');
          },
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(chatBuilds, 0);
      expect(find.text('Knock request'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Image), findsNothing);
      await client.setKnockEnabled(false);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Normal chat'), findsOneWidget);
      expect(room.joins, 0);
      expect(room.leaves, 0);
    },
  );

  testWidgets('switch saves choice and failed write leaves it off', (
    tester,
  ) async {
    final client = KnockTestClient('@alice:test.invalid')..failWrite = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KnockSettingTile(client: client)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('knock_switch')));
    await tester.pumpAndSettle();
    expect(client.knockEnabled, isFalse);
    expect(find.textContaining('Could not save Knock.'), findsOneWidget);
    client.failWrite = false;
    await tester.tap(find.byKey(const Key('knock_switch')));
    await tester.pumpAndSettle();
    expect(client.knockEnabled, isTrue);
  });
}
