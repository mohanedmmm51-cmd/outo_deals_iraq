import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'advanced_features.dart';
import 'commerce_pages.dart' as commerce;
import 'expert_features_backup.dart' as expert;
import 'marketplace_features.dart';
import 'order_system.dart';
import 'production_features.dart';
import 'shop_qr_confirm_page.dart';
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
      builder: (context, child) => ShopScannerShortcut(
        navigatorKey: appNavigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RestoredHomePage(),
    );
  }
}

class RestoredHomePage extends StatelessWidget {
  const RestoredHomePage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xff111111),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إطارات وبطاريات العراق', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('الجودة .. بأقرب محل', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _wide(
              context,
              Icons.workspace_premium,
              'مركز الخبير',
              'نصيحة خبير، مقارنة، اختيار بطارية وسجل صيانة',
              () => _open(context, const expert.ExpertCenterPage()),
            ),
            const SizedBox(height: 12),
            _wide(
              context,
              Icons.directions_car,
              'اختار سيارتك - VehDB',
              'الشركة، الموديل، السنة، الفئة وقياس الإطار',
              () => _open(context, const VehDbCarsPage()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _tile(
                    context,
                    Icons.tire_repair,
                    'الإطارات',
                    () => _open(context, const commerce.TiresPage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tile(
                    context,
                    Icons.battery_charging_full,
                    'البطاريات',
                    () => _open(context, const commerce.BatteriesPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _wide(
              context,
              Icons.straighten,
              'طلب قياس',
              'ما لكيت القياس؟ أرسل الطلب واستلم عروض المحلات',
              () => _open(context, const EnhancedSizeRequestPage()),
            ),
            const SizedBox(height: 12),
            _wide(
              context,
              Icons.near_me,
              'المحلات القريبة',
              'ترتيب حسب المسافة وزر اتجاهات',
              () => _open(context, const OnlineNearbyShopsPage()),
            ),
            const SizedBox(height: 12),
            _wide(
              context,
              Icons.local_offer,
              'العروض والخصومات',
              'عروض المحلات المعتمدة',
              () => _open(context, const OnlineOffersPage()),
            ),
            const SizedBox(height: 12),
            _wide(
              context,
              Icons.receipt_long,
              'طلباتي',
              'تابع أكواد الطلبات وحالتها',
              () => _open(context, const MyOrdersPage()),
            ),
            const SizedBox(height: 12),
            _wide(
              context,
              Icons.add_business,
              'صاحب محل / إضافة محل',
              'تسجيل محل وحفظ موقعه GPS للموافقة',
              () => _open(context, const ShopAuthPage()),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _wide(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: yellow,
          foregroundColor: Colors.black,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 44),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
        ),
      ),
    );
  }
}
