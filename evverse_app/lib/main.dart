import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

// If you have firebase_options.dart from flutterfire configure, uncomment below line:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // If you have DefaultFirebaseOptions, use it:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Otherwise fall back to default initialize (requires platform config files).
    await Firebase.initializeApp();
    // Note: if your app needs firebase_options.dart for web or specific platforms,
    // run `flutterfire configure` to create it and re-enable the import above.
  } catch (e) {
    // Initialization failed (maybe missing platform files). We still start the app
    // so placeholders can be developed. Replace this with logging in production.
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const EvverseApp());
}
