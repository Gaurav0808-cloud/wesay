# Knock opt-in test implementation

Knock is OFF by default. Each Matrix account has its own choice under Settings → Security → Knock. The boolean preference is stored as Matrix account data (`io.github.gaurav0808cloud.wesay.knock`) on the account's homeserver and syncs to other WeSay clients. This metadata is not end-to-end encrypted; it contains no message text or address-book uploads.

## On and off

- Off: preserve the inherited WeSay/Matrix messaging and invitation behaviour. Do not auto-join rooms or groups.
- On: every new conversation/group/space invitation goes to Requests. Already joined chats keep working. The first version does not assume a phone contact or a sender-controlled `is_direct` flag proves trust. Even someone you already chat with must get acceptance for a new room/group.
- Switching off returns pending invitations to the normal list. It does not join, reject, delete or unblock anything.
- Accept uses the SDK's normal explicit room join. Messages become available afterwards according to room encryption/history rules.
- Reject declines this invitation without globally blocking its sender. A later invitation may appear again.
- Block identifies the inviter by Matrix ID, records a standard Matrix ignore-list entry, then declines the invitation. A confirmation explains that blocking applies across chats. Failed block/save/join operations remain visible as errors and can be retried.

## Client protection and limits

The normal chat controller, timeline and composer are not created for gated invitations, including direct chat routes and notification navigation. Request cards show plain Matrix IDs, without remote avatars, room titles, image previews or message previews. Pending-request local notifications/call alerts are suppressed. The existing test build still has background push disabled.

This is a WeSay client prototype. Other Matrix clients do not implement this preference. It does NOT reject invitations at the Synapse API or stop account/room floods. It does not protect against scams in already accepted chats or groups. Server-side policy, federation/bypass tests, rate limits, independent security audit, legal review and abuse-response staff are required before real-user testing.

Matrix protocol `knock` is a separate room-join-request mechanism; no new encryption protocol is introduced here. WeSay shows an invitation, not a supposedly private first-message preview hidden in unencrypted room state.

## Manual two-account test

1. Install WeSay Knock Test alongside the earlier test app. Sign in using Alice and verify the new session from the existing app. Do not uninstall an old app or reset the identity.
2. Confirm Knock is off in Alice's Security settings. Existing Bob messages should remain readable.
3. On Bob's laptop client, create a new private test group and invite Alice. With Knock off, this invitation appears in the normal chat list.
4. Turn Knock on for Alice. The pending invitation should move to Requests without joining. Close/reopen the app and confirm the setting persists.
5. Open the request. There must be no message composer or sender/room image loaded in the request page. Accept, then test a new encrypted message in both directions.
6. Create separate invitations to test Reject and Block. Confirm rejected rooms are left; confirm a blocked sender appears in the existing Blocked users setting. Restore the test account's block list when done.
7. Turn Knock off and confirm remaining requests return to the normal list without joining. Bob's own account preference must remain off unless Bob enabled it.
8. On a second WeSay client for Alice, verify the setting syncs. The original FluffyChat app will not enforce Knock.

## References

- [Matrix account data](https://spec.matrix.org/latest/client-server-api/#client-config)
- [Matrix room membership](https://spec.matrix.org/latest/client-server-api/#room-membership)
- [Current Synapse spam-checker callbacks for future server enforcement](https://element-hq.github.io/synapse/latest/modules/spam_checker_callbacks.html)

## Connection handling follow-up

The next revision performs pre-login discovery in an isolated, unauthenticated Matrix SDK client, limits the network check to 20 seconds, closes its dedicated HTTP transport on timeout/cancel, and ignores results from cancelled/disposed sign-in screens. It preserves standard well-known delegation and only copies a successful current result to the actual login client. The underlying SDK and encryption are unchanged. An offline laptop/server still cannot receive messages: this improves feedback, not server availability.

PR updates now run strict analysis and all focused tests without generating repeated 200 MB APK artifacts. Main-branch/manual builds retain APK output. The already downloaded Knock APK predates these connection-handling changes.
