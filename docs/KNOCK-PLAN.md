# Knock: proposed design, not implemented

Goal: strangers ask for permission to start a conversation. No claim of complete spam/scam prevention.

## First prototype

1. Define an accepted contact explicitly, using a Matrix ID and mutual conversation consent; do not infer trust from a display name, phone number, shared room or address-book upload.
2. Unknown 1:1 room invitations appear in a separate Requests inbox. Show a minimal sender ID; do not join automatically, download media, fetch link previews, disclose presence/read receipts or send encryption keys before consent.
3. Accept joins an encrypted room and marks the sender as accepted. Reject declines the invitation. Block additionally records the sender in the Matrix ignore list and suppresses future requests. Test behaviour across devices.
4. Unknown group invitations also become requests; never auto-join. Enforcing "non-contacts cannot add me" across alternate clients needs a server-side invitation policy, not just a hidden UI notification.

Matrix `knock` is a protocol room-join request feature. The WeSay product name "Knock" here is a conversation-consent flow, not an assertion that protocol knocking implements these rules.

## Important encryption boundary

A normal Matrix invite does not contain the sender's first encrypted chat message. The recipient normally needs to join and receive room keys to decrypt history. First prototype should show an invitation request, with the actual message only after acceptance. Do not put a private introduction in unencrypted invite/state data. A confidential first-message preview before acceptance requires a separately reviewed design; do not invent a new cryptographic protocol.

## Server enforcement and abuse handling

Investigate Synapse spam-checker/module hooks against the pinned Synapse version: invitation policy, account registration, room creation and request rates. Verify bypass resistance with a different Matrix client, federation, re-invitations, new accounts and multi-device state. Decide whether the first pilot disables federation. Enforce payload and media limits, rate limits and cooldowns. These measures reduce exposure; they cannot prevent scams from accepted contacts or compromised accounts.

Reporting must be intentional and explain exactly what evidence is shared with moderators. Never silently scan private encrypted chats server-side or claim that E2EE permits that. Avoid publishing reports or private message text in GitHub issues.

## Tests before public use

Unknown direct/group invites; accepted contacts; reject/block/reinvite; spoofed names; address-book permission denied; encrypted rooms; blocked calls/attachments/previews before consent; multi-device reconciliation; account logout/recovery; direct Matrix API and alternate-client bypasses; federation; request floods; malicious payloads; report consent. Independent audit and legal review precede real-user messages.
