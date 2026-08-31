import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'advanced_features.dart';
import 'draggable_shop_shortcuts_v2.dart';
import 'marketplace_features.dart';
import 'production_features.dart';
import 'restored_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  if (Firebase.apps.isNotEmpty) {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('Notifications init skipped: $e');
    }

    try {
      await ProductionServices.init();
    } catch (e) {
      debugPrint('Production services init skipped: $e');
    }
  }

  runApp(const App());
}

const yellow = Color(0xFFFFD400);
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'إطارات وبطاريات العراق',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: yellow),
      ),
      builder: (context, child) => DraggableShopShortcutsV2(
        navigatorKey: appNavigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RestoredHome(),
    );
  }
}
