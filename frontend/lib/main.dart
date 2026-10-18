import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_repository.dart';
import 'services/firebase_clinical_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MovereApp(
      authRepository: FirebaseAuthRepository(),
      clinicalRepository: FirebaseClinicalRepository(),
    ),
  );
}
