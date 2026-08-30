import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin_features.dart';
import 'advanced_features.dart';
import 'commerce_pages.dart' as commerce;
import 'expert_features_backup.dart' as expert;
import 'legacy_main.dart' as legacy;
import 'marketplace_features.dart';
import 'operations_features.dart';
import 'order_system.dart';
import 'production_features.dart';
import 'shop_dashboard.dart';
import 'shop_qr_confirm_page.dart';
import 'shop_store.dart';
import 'size_request_page.dart';
import 'vehdb_cars_page.dart';

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

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إطارات وبطاريات العراق',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: yellow),
      ),
      builder: (context, child) => ShopScannerShortcut(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const legacy.Home(),
    );
  }
}
