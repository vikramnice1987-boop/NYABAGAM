// Generated-style Firebase options.
//
// Replace this file by running flutterfire configure once a Firebase project
// exists. Dart defines keep the repository usable in local-only mode without
// committing a production project.

import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_environment.dart';

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final env = AppEnvironment.current;
    if (!env.isFirebaseConfigured) {
      throw StateError(
        'Firebase has not been configured. Run flutterfire configure or pass '
        'the FIREBASE_* Dart defines described in .env.example.',
      );
    }

    return FirebaseOptions(
      apiKey: env.firebaseApiKey,
      appId: env.firebaseAppId,
      messagingSenderId: env.firebaseMessagingSenderId,
      projectId: env.firebaseProjectId,
      storageBucket: env.firebaseStorageBucket,
      authDomain: env.firebaseAuthDomain.isEmpty ? null : env.firebaseAuthDomain,
    );
  }
}
