import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Deployment exports public SDK configuration from the selected Firebase Web app.
/// Native apps continue using their existing platform configuration.
Future<void> initializeFirebase() async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
    return;
  }
  final response = await http.get(Uri.base.resolve('/firebase-config.json'))
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw StateError('Firebase web configuration is unavailable');
  }
  final config = jsonDecode(response.body) as Map<String, dynamic>;
  String requiredValue(String key) {
    final value = config[key];
    if (value is! String || value.isEmpty) {
      throw StateError('Missing Firebase web configuration: $key');
    }
    return value;
  }
  final appId = requiredValue('appId');
  if (!appId.contains(':web:')) {
    throw StateError('Register a Firebase Web app before publishing');
  }
  await Firebase.initializeApp(options: FirebaseOptions(
    apiKey: requiredValue('apiKey'),
    appId: appId,
    messagingSenderId: requiredValue('messagingSenderId'),
    projectId: requiredValue('projectId'),
    authDomain: config['authDomain'] as String?,
    storageBucket: config['storageBucket'] as String?,
    measurementId: config['measurementId'] as String?,
    databaseURL: config['databaseURL'] as String?,
  ));
}
