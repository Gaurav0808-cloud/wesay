# WeSay private test build

For the founder's test accounts only. No public pilot or real-user messages until independent security audit, legal review, and abuse-response staff are in place.

## Install and connect

1. Download the `wesay-test-apk` artifact from a successful WeSay Android Test workflow run.
2. Extract `wesay-test.apk` and install on your Android test phone.
3. Keep Docker/Synapse and Tailscale running on the laptop, and Tailscale on the phone.
4. Sign in, enter your HTTPS Tailscale Serve address, select it, and continue. Enter the local username `alice` or `bob` (not a full `@alice:localhost` ID, which triggers server discovery).
5. Test encrypted messages in both directions, then restart the app and test again. Confirm encryption and verify the new device using the existing client.

This build installs as **WeSay Knock Test**, alongside the earlier WeSay Test app so its local encryption keys are preserved. The package ID is `io.github.gaurav0808cloud.wesay.knocktest`, separate from FluffyChat. The test APK uses Android debug signing, is debuggable, and must never be distributed as a production release. A fresh cloud runner generates a new disposable debug key: subsequent APKs may require uninstall/reinstall, losing local keys. Before uninstalling, verify that another test device or a tested recovery backup can decrypt your test history. Production signing is a separate future setup.

## Optional default homeserver

The source accepts `--dart-define-from-file` containing `WESAY_HOMESERVER`. GitHub Actions reads this from the optional Actions secret `WESAY_HOMESERVER`, never from tracked server configuration. Leave it unset to enter the server on-device. Do not put account passwords, access tokens, recovery keys or Synapse configuration in GitHub.

IMPORTANT: an address compiled into an APK is extractable. Repository secrets hide it from source and logs, not from APK recipients. Use manual on-device entry when the address must remain private. The APK artifact is publicly downloadable by signed-in GitHub users with repository access.

## Build scope and costs

The workflow uses a standard hosted Ubuntu runner in a public repository. It builds ARM64 Android only, with no Firebase injection, paid services, deployment or release publishing. One small artifact is retained for one day; caches are disabled. Do not enable paid billing or larger runners. Repeated artifacts still consume account-wide storage: remove old artifacts or wait for expiry before repeated builds if nearing the free allowance.

The old FluffyChat workflows are preserved under `.github/upstream-workflows/` and are not active. The upstream licences and attribution remain.

## Not implemented

Optional Knock is implemented inside WeSay; see [Knock behaviour and tests](KNOCK-PLAN.md). Server-enforced contact-only group invitations, scam detection, migration from WhatsApp and payments are not implemented. Background push delivery has not been configured or verified. This fork has not been security audited. End-to-end encryption is provided by the inherited Matrix SDK; server metadata, local device data and encrypted backups still exist.
