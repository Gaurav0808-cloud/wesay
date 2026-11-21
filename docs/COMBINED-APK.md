# Combined founder-only APK

This packaging branch builds an ARM64 profile-mode APK from the previously tested combined source. AOT compilation removes the large debug kernel. Signup preview requires both profile mode and the explicit WESAY_OFFLINE_PREVIEW define, or debug mode. Release builds cannot enable it. No private homeserver address or account credentials are compiled in.

The standard public Ubuntu runner checks strict analysis and all focused tests before building. Android native dependencies are restricted to arm64-v8a. The app keeps the separate preview package and existing visible branding. Signing uses the profile variant inherited from Android debug signing; verification records the public certificate fingerprint, source commit, package ID and file checksum. This test signing is not a production or stable future update-signing setup.

Uploads stop if this repository's active artifacts plus an 81 MB reserve exceed 500 MB, and the ZIP download itself must be below 80 MB. The APK may be larger because it holds native libraries uncompressed. The measured ZIP is uploaded inside an uncompressed artifact wrapper, with the 1 MB reserve covering wrapper overhead. Storage is checked again immediately before upload. No paid runner, cache, external file host, billing change or release publication is used. Repository artifact checks do not reveal private account-wide billing usage. Prior artifacts are retained untouched. A full account storage quota may still reject an upload.

The APK is for the founder's dummy/test accounts only. It installs alongside earlier packages; do not uninstall a verified client or reset encryption identity. It still needs real-device tests after download. Real SMS login, contact recognition and server-enforced Knock are not implemented.
