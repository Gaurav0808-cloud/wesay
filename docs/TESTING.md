# WeSay private test build

For the founder's test accounts only. No public pilot or real-user messages until independent security audit, legal review, and abuse-response staff are in place.

## Install and connect

1. Download the `wesay-test-apk` artifact from a successful WeSay Android Test workflow run.
2. Extract `wesay-test.apk` and install on your Android test phone. The next combined preview uses a separate package, so do not uninstall either existing test app.
3. Signed-out debug builds open the offline demo. Try the dummy number, sample code `000000`, made-up name and avatar, then restart the preview. No account is created. To test real test-account messaging, choose **Sign in with an existing test account**.
4. Keep Docker/Synapse and Tailscale running on the laptop, and Tailscale on the phone.
5. Sign in, enter your HTTPS Tailscale Serve address, select it, and continue. Enter the local username `alice` or `bob` (not a full `@alice:localhost` ID, which triggers server discovery).
6. Test encrypted messages in both directions, then restart the app and test again. Confirm encryption and verify the new device using the existing client.

The visible app name/logo/colours remain unchanged. The next combined preview uses package `io.github.gaurav0808cloud.wesay.previewtest` and `wesay.previewtest` / `wesay.previewtest.auth` URI schemes. It installs alongside both the earlier `wesay.test` and `wesay.knocktest` packages, preserving their sessions and local encryption keys. Existing apps will not gain the new screens. Verify the preview's new Matrix session from your existing verified client before expecting encrypted history to be readable.

Debug signing remains disposable per cloud runner. This is a co-installable preview, not a guaranteed update path for future APKs. Never uninstall a verified client or reset its identity just to install a preview. Stable private signing and production signing remain separate setup; keys must never enter the public repository. These debug builds are not production releases.

## Optional default homeserver

The source accepts `--dart-define-from-file` containing `WESAY_HOMESERVER`. GitHub Actions reads this from the optional Actions secret `WESAY_HOMESERVER`, never from tracked server configuration. Leave it unset to enter the server on-device. Do not put account passwords, access tokens, recovery keys or Synapse configuration in GitHub.

IMPORTANT: an address compiled into an APK is extractable. Repository secrets hide it from source and logs, not from APK recipients. Use manual on-device entry when the address must remain private. The APK artifact is publicly downloadable by signed-in GitHub users with repository access.

## Build scope and costs

The workflow uses a standard hosted Ubuntu runner in a public repository. It builds ARM64 Android only, with no Firebase injection, paid services, deployment or release publishing. Each APK artifact is retained for one day; caches are disabled. Do not enable paid billing or larger runners. Repeated artifacts still consume account-wide storage: remove old artifacts or wait for expiry before repeated builds if nearing the free allowance.

The old FluffyChat workflows are preserved under `.github/upstream-workflows/` and are not active. The upstream licences and attribution remain.

## Not implemented

Optional Knock is implemented inside WeSay; see [Knock behaviour and tests](KNOCK-PLAN.md). Server-enforced contact-only group invitations, scam detection, migration from WhatsApp and payments are not implemented. Background push delivery has not been configured or verified. This fork has not been security audited. End-to-end encryption is provided by the inherited Matrix SDK; server metadata, local device data and encrypted backups still exist.
