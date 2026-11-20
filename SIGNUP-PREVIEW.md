# WeSay signup preview

Debug builds open an offline welcome and phone layout for signed-out users. Release builds keep the existing sign-in flow. The preview uses a read-only invalid dummy number, +91 0000000000. It sends no SMS, collects no real phone number, creates no account, stores no profile and never grants access to chats. Continuing displays an explicit completion notice, not an OTP or verified state. Existing signed-in sessions still open chats. Existing test-account sign-in remains available from the preview.

This is an English-only India layout prototype, not phone authentication. Real number verification, account recovery, privacy controls, service costs and server integration remain separate work requiring review before real users. Knock remains the existing optional client-side test feature.

Validation: widget tests cover demo-only data, explicit sign-in navigation, reset, narrow screens and large text. The PR runs analysis and tests without uploading another large APK. The installed APK is unchanged until a new build is prepared.
