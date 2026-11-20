# WeSay offline signup preview

Signed-out debug builds open welcome → dummy number → demo verification → sample profile → completion. Release builds retain existing sign-in. The phone field is read-only +91 0000000000; the sample code is visibly stated as 000000, with no SMS/resend or real verification. Incorrect demo codes and empty sample names show inline errors. Avatars are bundled Flutter icons; no camera, photo-library or contacts permissions are used.

This widget imports only Flutter and the existing local logo. It never calls Matrix, HTTP, authentication, storage, profile upload or chat navigation. Code, made-up name and avatar exist only in widget memory and reset on restart or disposal. The code is not an authentication credential. Completing this flow grants no chat access. Existing test-account sign-in is a separate explicit action, and existing signed-in sessions still open chats.

Back navigation moves one step at a time, including Android back. Each step starts at the top of a scrollable screen. UI tests cover the full flow, invalid input, avatar choice, restart, back navigation, small displays and large text.

This is an English-only India layout prototype, not phone authentication. Real SMS delivery, account creation/recovery, number ownership and reassignment, privacy, abuse protection, service costs and server integration remain separate work before launch. No real-user messages until the agreed independent security audit, legal review and abuse-response team are in place.

The same branch includes the optional Knock setting, Requests accept/decline/block flow and cancellable server discovery. Knock is off by default and applies to all new invitations when on; it is client-side and not a contact-only or complete scam-prevention guarantee. See docs/KNOCK-PLAN.md.

The next combined APK uses a separate preview package and URI schemes so it does not replace either installed test app. Branding is unchanged. This source update does not build or upload an APK; phone testing remains pending until packaging and server access are available.
