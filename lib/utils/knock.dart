// SPDX-FileCopyrightText: 2026 Gaurav Gill
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:matrix/matrix.dart';

/// Conversation consent in WeSay, distinct from Matrix room-join knocking.
/// This client policy does not impose server-side rules on other clients.
extension KnockAccount on Client {
  static const eventType = 'io.github.gaurav0808cloud.wesay.knock';

  bool get knockEnabled => accountData[eventType]?.content['enabled'] == true;

  /// Every new invitation requires explicit consent when enabled. Already
  /// joined chats remain normal; a claimed is_direct flag never grants trust.
  bool isKnockRequest(Room room) =>
      identical(room.client, this) &&
      knockEnabled &&
      room.membership == Membership.invite;

  List<Room> get knockRequests => rooms.where(isKnockRequest).toList();

  Future<void> setKnockEnabled(bool enabled) async {
    await accountDataLoading;
    final id = userID;
    if (id == null) throw StateError('Sign in before changing Knock.');
    final content = <String, Object?>{'enabled': enabled, 'version': 1};
    // Do not change the visible setting if the server rejects the write.
    await setAccountData(id, eventType, content);
    accountData[eventType] = BasicEvent(type: eventType, content: content);
    // Normal /sync persists this to the SDK database and updates other devices.
  }
}

String? knockInviter(Room room) {
  final id = room.client.userID;
  if (id == null) return null;
  return room.getState(EventTypes.RoomMember, id)?.senderId;
}

Future<void> acceptKnock(Room room) async {
  if (room.membership != Membership.invite) {
    throw StateError('This invitation is no longer pending.');
  }
  await room.join(waitForSync: true);
}

Future<void> rejectKnock(Room room) async {
  if (room.membership != Membership.invite) {
    throw StateError('This invitation is no longer pending.');
  }
  await room.leave(waitForSync: true);
}

Future<void> blockKnock(Room room) async {
  final sender = knockInviter(room);
  if (sender == null || sender == room.client.userID) {
    throw StateError('The sender could not be identified.');
  }
  // Persist the block before declining. A failed block must not be reported
  // as successful merely because leaving the room worked.
  await room.client.ignoreUser(sender, leaveRooms: false);
  if (room.membership == Membership.invite) await room.leave(waitForSync: true);
}
