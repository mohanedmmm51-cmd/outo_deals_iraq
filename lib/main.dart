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
import 'shop_store.dart';
import 'size_request_page.dart';
import 'vehdb_cars_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const App());

  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
    return;
  }

  try {
    await NotificationService.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Notifications init skipped: $e');
  }

  try {
    await ProductionServices.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Production services init skipped: $e');
  }
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
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xff111111),
        selectedItemColor: yellow,
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          if (index == 1) {
            _open(context, const OnlineNearbyShopsPage());
          } else if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('السلة راح نربطها بمرحلة المنتجات متعددة العناصر'),
              ),
            );
          } else if (index == 3) {
            _open(context, const MyOrdersPage());
          } else if (index == 4) {
            _open(context, const ShopAuthPage());
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المحلات'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'السلة'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'طلباتي'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                decoration: const BoxDecoration(
                  color: Color(0xff101010),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu, color: Colors.white, size: 30),
                        const Spacer(),
                        const Column(
                          children: [
                            Text(
                              'إطارات وبطاريات العراق',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'الجودة .. بأقرب محل',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _open(context, const NotificationCenterPage()),
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: SizedBox(
                        height: 54,
                        child: Row(
                          children: [
                            SizedBox(width: 16),
                            Icon(Icons.search, size: 30),
                            SizedBox(width: 10),
                            Text(
                              'شنو تحتاج؟ إطارات أو بطاريات...',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    actionButton(
                      context,
                      Icons.workspace_premium,
                      'مركز الخبير',
                      'نصيحة خبير + مقارنة + اختيار بطارية + سجل صيانة',
                      yellow,
                      () => _open(context, const expert.ExpertCenterPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.directions_car,
                      'اختار سيارتك',
                      'اعرف قياس الإطار المناسب لسيارتك',
                      yellow,
                      () => _open(context, const VehDbCarsPage()),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: categoryButton(
                            context,
                            'الإطارات',
                            const TireCategoryIcon(),
                            () => _open(context, const commerce.TiresPage()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: categoryButton(
                            context,
                            'البطاريات',
                            const BatteryCategoryIcon(),
                            () => _open(context, const commerce.BatteriesPage()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.auto_awesome,
                      'الخدمات المتقدمة',
                      'مفضلة + حجز + كوبونات + إحالة + فاتورة + صور + مقارنة + تنبيهات',
                      yellow,
                      () => _open(context, const AdvancedHubPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.recommend,
                      'أفضل المحلات إلك',
                      'ترتيب ذكي حسب القرب والتقييم والتوفر وسرعة التنفيذ',
                      yellow,
                      () => _open(context, const SmartShopRankingPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.receipt_long,
                      'طلباتي',
                      'الحالة + الإلغاء + الملاحظات + المشاركة + التقييم',
                      Colors.white,
                      () => _open(context, const MyOrdersPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.storefront,
                      'بوابة صاحب المحل',
                      'الطلبات + المخزون + الفروع + العمولات',
                      Colors.white,
                      () => _open(context, const ShopPortalPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.straighten,
                      'طلب قياس',
                      'ما لكيت القياس؟ أرسل الطلب للمحلات أونلاين',
                      yellow,
                      () => _open(context, const EnhancedSizeRequestPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.location_on,
                      'المحلات القريبة',
                      'GPS + المسافة + ترتيب الأقرب + الاتجاهات',
                      Colors.white,
                      () => _open(context, const OnlineNearbyShopsPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.add_business,
                      'إضافة محل',
                      'إنشاء حساب محل وإرسال طلب الاعتماد',
                      Colors.white,
                      () => _open(context, const ShopAuthPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.local_offer,
                      'العروض والخصومات',
                      'العروض المعتمدة من المحلات',
                      Colors.white,
                      () => _open(context, const OnlineOffersPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.notifications_active,
                      'الإشعارات',
                      'طلبات جديدة وتحديثات المحلات',
                      Colors.white,
                      () => _open(context, const NotificationCenterPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.support_agent,
                      'التواصل مع الدعم',
                      'مساعدة واستفسارات',
                      Colors.white,
                      () => _open(context, const legacy.SupportPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.monitor_heart,
                      'حالة النظام',
                      'Crashlytics + Performance + Remote Config + البيئة الحالية',
                      Colors.white,
                      () => _open(context, const ProductionStatusPage()),
                    ),
                    const SizedBox(height: 14),
                    actionButton(
                      context,
                      Icons.admin_panel_settings,
                      'لوحة الإدارة',
                      'تقارير + بحث + أسعار + إحصائيات + سجل نشاط',
                      Colors.white,
                      () => _open(context, const AdminAccessPage()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget actionButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 45, color: Colors.black),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new, size: 18),
          ],
        ),
      ),
    );
  }

  static Widget categoryButton(
    BuildContext context,
    String title,
    Widget icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xff171717),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: yellow.withValues(alpha: .20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TireCategoryIcon extends StatelessWidget {
  const TireCategoryIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: yellow, width: 8),
        boxShadow: [
          BoxShadow(color: yellow.withValues(alpha: .18), blurRadius: 12),
        ],
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: yellow, width: 3),
          ),
          child: const Icon(Icons.settings, color: yellow, size: 17),
        ),
      ),
    );
  }
}

class BatteryCategoryIcon extends StatelessWidget {
  const BatteryCategoryIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 68,
            height: 54,
            decoration: BoxDecoration(
              color: yellow,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(color: yellow.withValues(alpha: .18), blurRadius: 12),
              ],
            ),
            child: const Center(
              child: Icon(Icons.bolt, color: Colors.black, size: 36),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 9,
              decoration: const BoxDecoration(
                color: yellow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
            const SizedBox(width: 25),
            Container(
              width: 14,
              height: 9,
              decoration: const BoxDecoration(
                color: yellow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ShopPortalPage extends StatefulWidget {
  const ShopPortalPage({super.key});

  @override
  State<ShopPortalPage> createState() => _ShopPortalPageState();
}

class _ShopPortalPageState extends State<ShopPortalPage> {
  ShopProfile? shop;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ShopStore.load();
    if (mounted) setState(() => shop = p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بوابة صاحب المحل')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              color: yellow,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(Icons.storefront, size: 70),
                    const SizedBox(height: 8),
                    Text(
                      shop == null ? 'سجل دخول المحل' : shop!.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shop == null
                          ? 'الحساب يحمي الطلبات ويحسب العمولة على المحل الصحيح.'
                          : 'رقم المحل: ${shop!.id}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopAuthPage()),
                );
                _load();
              },
              icon: const Icon(Icons.login),
              label: const Text('دخول / إنشاء حساب محل'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopOrdersPage()),
              ),
              icon: const Icon(Icons.inbox),
              label: const Text('الطلبات الواردة وحالاتها'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopConfirmOrderPage()),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('فحص كود الطلب'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopDashboardPage()),
              ),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('حساب المحل والعمولات'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryManagementPage()),
              ),
              icon: const Icon(Icons.inventory_2),
              label: const Text('إدارة المخزون'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BranchManagementPage()),
              ),
              icon: const Icon(Icons.account_tree),
              label: const Text('فروع المحل'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopHoursPage()),
              ),
              icon: const Icon(Icons.schedule),
              label: const Text('ساعات العمل والعطل'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopAdvancedToolsPage()),
              ),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('أدوات المحل المتقدمة'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfferSubmitPage()),
              ),
              icon: const Icon(Icons.local_offer),
              label: const Text('إضافة عرض'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopSizeRequestsPage()),
              ),
              icon: const Icon(Icons.straighten),
              label: const Text('طلبات القياسات'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
              ),
              icon: const Icon(Icons.notifications),
              label: const Text('إشعارات المحل'),
            ),
          ],
        ),
      ),
    );
  }
}
