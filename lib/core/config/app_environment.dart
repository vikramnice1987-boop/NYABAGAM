class AppEnvironment {
  const AppEnvironment._({
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseMessagingSenderId,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
    required this.firebaseAuthDomain,
    required this.firebaseEmailLinkUrl,
    required this.firebaseFunctionsRegion,
    required this.firebaseAiFunctionName,
  });
  static const current = AppEnvironment._(
    firebaseApiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    firebaseAppId: String.fromEnvironment('FIREBASE_APP_ID'),
    firebaseMessagingSenderId:
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    firebaseProjectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    firebaseStorageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    firebaseAuthDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    firebaseEmailLinkUrl: String.fromEnvironment('FIREBASE_EMAIL_LINK_URL'),
    firebaseFunctionsRegion: String.fromEnvironment(
      'FIREBASE_FUNCTIONS_REGION',
      defaultValue: 'asia-south1',
    ),
    firebaseAiFunctionName: String.fromEnvironment(
      'FIREBASE_AI_FUNCTION_NAME',
      defaultValue: 'aiOrchestrator',
    ),
  );
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final String firebaseAuthDomain;
  final String firebaseEmailLinkUrl;
  final String firebaseFunctionsRegion;
  final String firebaseAiFunctionName;

  /// True when this build has a real Firebase client configuration.
  ///
  /// The application falls back to its local repository when these values are
  /// absent, so contributors can run the UI without production access.
  bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseStorageBucket.isNotEmpty;
}
