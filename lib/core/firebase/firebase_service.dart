import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../firebase_options.dart';
import '../config/app_environment.dart';

/// The single Firebase access point used by NYABAGAM's data boundaries.
///
/// It is initialized only when client configuration is supplied. That keeps
/// local development private and a missing project cannot block capture.
abstract final class FirebaseService {
  static Future<void> initialize() async {
    if (!AppEnvironment.current.isFirebaseConfigured) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static FirebaseFunctions get functions => FirebaseFunctions.instanceFor(
        region: AppEnvironment.current.firebaseFunctionsRegion,
      );
}
