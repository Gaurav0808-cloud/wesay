<!--
SPDX-FileCopyrightText: 2019-Present Christian Kußowski
SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
SPDX-FileCopyrightText: 2026 Gaurav Gill
SPDX-License-Identifier: AGPL-3.0-or-later
-->

# WeSay test privacy notes

This is an unaudited private development build for the founder's test accounts, not a public service or a final privacy policy.

- Matrix end-to-end encryption is inherited from FluffyChat and its SDK. It does not hide all metadata. No claim of "we store nothing" is made.
- The optional Knock preference is stored as unencrypted account metadata on your homeserver and syncs to other WeSay clients. It does not contain message content or upload your contacts. Other Matrix clients do not enforce it.
- Your Synapse server can retain account identifiers, room membership, message timing, encrypted message/media data, IP/log information and other metadata according to its configuration. This repository does not configure server retention.
- The app stores local account/session data, encryption keys, cached messages and diagnostics on the test device. Android cloud backup remains disabled as in upstream.
- The test sign-in page does not fetch a public server directory. Choose your own test server; there is no built-in public default.
- Automatic error reporting remains off by default. Do not publish logs, screenshots or bug reports containing passwords, tokens, recovery keys or private messages.
- External links, mapping, calling and optional push integrations inherited from upstream have not been comprehensively audited. No promise of zero third-party connections is made. Firebase is not injected into this build and background push is disabled for this test build.
- A server address embedded at build time can be extracted from the APK, even if supplied through a GitHub secret. Manual on-device server entry is available.
- Indian and international legal duties, retention and lawful-request processes need qualified legal review before launch. Encryption does not itself resolve those duties.

Before any real-user testing: independent security audit, qualified legal/privacy review, truthful public policy and an operational abuse/scam response team are required.
