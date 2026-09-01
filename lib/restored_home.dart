import 'package:flutter/material.dart';

import 'advanced_features.dart';
import 'commerce_pages.dart' as commerce;
import 'customer_cart.dart';
import 'expert_features.dart' as expert;
import 'app_core.dart' as legacy;
import 'marketplace_features.dart';
import 'order_system.dart';
import 'production_features.dart';
import 'size_request_page.dart';
import 'vehdb_cars_page.dart';

const restoredYellow = Color(0xFFFFD400);

class RestoredHome extends StatefulWidget {
  const RestoredHome({super.key});

  @override
  State<RestoredHome> createState() => _RestoredHomeState();
}

class _RestoredHomeState extends State<RestoredHome> {
  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _bottomTap(int index) {
    switch (index) {
      case 0:
        return;
      case 1:
        _open(const OnlineNearbyShopsPage());
        return;
      case 2:
        _open(const CustomerCartPage());
        return;
      case 3:
        _open(const MyOrdersPage());
        return;
      case 4:
        _open(const CustomerAccountPage());
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      drawer: const _HomeDrawer(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _bottomTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xff111111),
        selectedItemColor: restoredYellow,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المحلات'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'السلة'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'طلباتي'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
      body: Builder(
        builder: (bodyContext) => SafeArea(
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
                          IconButton(
                            tooltip: 'القائمة',
                            onPressed: () => Scaffold.of(bodyContext).openDrawer(),
                            icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                          ),
                          const Spacer(),
                          const Column(
                            children: [
                              Text(
                                'إطارات وبطاريات العراق',
                                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              Text('الجودة .. بأقرب محل', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'الإشعارات',
                            onPressed: () => _open(const NotificationCenterPage()),
                            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      InkWell(
                        onTap: () => _open(const ProductSearchPage()),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                            children: [
                              Icon(Icons.search, size: 30),
                              SizedBox(width: 10),
                              Text('شنو تحتاج؟ إطارات أو بطاريات...', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                      RestoredHomeUi.button(
                        Icons.workspace_premium,
                        'مركز الخبير',
                        'نصيحة خبير + مقارنة + اختيار بطارية + سجل صيانة',
                        restoredYellow,
                        () => _open(const RestoredExpertCenterPage()),
                      ),
                      const SizedBox(height: 14),
                      RestoredHomeUi.button(
                        Icons.directions_car,
                        'اختار سيارتك',
                        'اعرف قياس الإطار المناسب لسيارتك',
                        restoredYellow,
                        () => _open(const VehDbCarsPage()),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: RestoredHomeUi.category(
                              Icons.tire_repair,
                              'الإطارات',
                              () => _open(const commerce.TiresPage()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RestoredHomeUi.category(
                              Icons.battery_charging_full,
                              'البطاريات',
                              () => _open(const commerce.BatteriesPage()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      RestoredHomeUi.button(
                        Icons.straighten,
                        'طلب قياس',
                        'ما لكيت القياس؟ أرسل طلب للمحلات',
                        restoredYellow,
                        () => _open(const EnhancedSizeRequestPage()),
                      ),
                      const SizedBox(height: 14),
                      RestoredHomeUi.button(
                        Icons.location_on,
                        'المحلات القريبة',
                        'المسافة + الأقرب + الاتجاهات',
                        Colors.white,
                        () => _open(const OnlineNearbyShopsPage()),
                      ),
                      const SizedBox(height: 14),
                      RestoredHomeUi.button(
                        Icons.add_business,
                        'إضافة محل',
                        'طلب انضمام لأصحاب المحلات + تحديد GPS',
                        Colors.white,
                        () => _open(const ShopAuthPage()),
                      ),
                      const SizedBox(height: 14),
                      RestoredHomeUi.button(
                        Icons.local_offer,
                        'العروض والخصومات',
                        'شوف أحدث العروض المتوفرة',
                        Colors.white,
                        () => _open(const OnlineOffersPage()),
                      ),
                      const SizedBox(height: 14),
                      RestoredHomeUi.button(
                        Icons.support_agent,
                        'التواصل مع الدعم',
                        'مساعدة واستفسارات',
                        Colors.white,
                        () => _open(const legacy.SupportPage()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RestoredHomeUi {
  static Widget button(
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
                  Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
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

  static Widget category(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140,
        decoration: BoxDecoration(color: const Color(0xff171717), borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: restoredYellow, size: 52),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  void _open(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xff111111)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tire_repair, color: restoredYellow, size: 54),
                    SizedBox(height: 8),
                    Text('Auto Deals Iraq', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('طلباتي'),
                onTap: () => _open(context, const MyOrdersPage()),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('الخدمات المتقدمة'),
                onTap: () => _open(context, const AdvancedHubPage()),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('أفضل المحلات إلك'),
                onTap: () => _open(context, const SmartShopRankingPage()),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.storefront),
                title: const Text('دخول / تسجيل صاحب محل'),
                onTap: () => _open(context, const ShopAuthPage()),
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('دخول الإدارة'),
                onTap: () => _open(context, const AdminLoginPage()),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('الدعم'),
                onTap: () => _open(context, const legacy.SupportPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final controller = TextEditingController();
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final tires = q.isEmpty
        ? legacy.tires.take(10).toList()
        : legacy.tires.where((t) => t.size.toLowerCase().contains(q)).toList();
    final batteries = q.isEmpty
        ? legacy.batteries.take(10).toList()
        : legacy.batteries.where((b) => '${b.brand} ${b.amp}'.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: 'اكتب القياس أو اسم البطارية',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 18),
            if (tires.isNotEmpty) ...[
              const Text('الإطارات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...tires.map(
                (tire) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.tire_repair),
                    title: Text(tire.size),
                    trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => commerce.TireDetailsPage(tire: tire)),
                    ),
                  ),
                ),
              ),
            ],
            if (batteries.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('البطاريات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...batteries.map(
                (battery) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.battery_charging_full),
                    title: Text('${battery.brand} ${battery.amp}'),
                    trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => commerce.BatteryDetailsPage(battery: battery)),
                    ),
                  ),
                ),
              ),
            ],
            if (q.isNotEmpty && tires.isEmpty && batteries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Text('ما لكينا نتيجة. تقدر تستخدم «طلب قياس» وترسله للمحلات.', textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomerAccountPage extends StatelessWidget {
  const CustomerAccountPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              color: restoredYellow,
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('حساب الزبون', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('طلباتك وسلتك محفوظة على هذا الجهاز، والطلب يتزامن مع السيرفر عند إنشائه.'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('طلباتي'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => _open(context, const MyOrdersPage()),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('السلة'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => _open(context, const CustomerCartPage()),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('الخدمات المتقدمة'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => _open(context, const AdvancedHubPage()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('صاحب محل؟ دخول أو تسجيل'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => _open(context, const ShopAuthPage()),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('التواصل مع الدعم'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => _open(context, const legacy.SupportPage()),
            ),
          ],
        ),
      ),
    );
  }
}

class RestoredExpertCenterPage extends StatelessWidget {
  const RestoredExpertCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مركز الخبير')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xff111111), borderRadius: BorderRadius.circular(22)),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium, color: restoredYellow, size: 58),
                  SizedBox(height: 8),
                  Text('خبرة عملية قبل لا تشتري', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text(
                    'اختيار صحيح للإطار والبطارية، مقارنة واضحة، ونصائح تمنع الشراء الغلط.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RestoredHomeUi.button(
              Icons.tips_and_updates,
              'نصيحة الخبير',
              'DOT، التآكل، الضغط، المدينة والسفر',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const expert.ExpertAdvicePage())),
            ),
            const SizedBox(height: 12),
            RestoredHomeUi.button(
              Icons.compare_arrows,
              'مقارنة الإطارات',
              'قارن حتى 3 قياسات وأسعار ونصيحة الاستخدام',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const expert.TireComparisonPage())),
            ),
            const SizedBox(height: 12),
            RestoredHomeUi.button(
              Icons.battery_saver,
              'مساعد البطارية',
              'اختيار حسب الأمبير وStart/Stop والبطارية القديمة',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const expert.BatteryAdvisorPage())),
            ),
            const SizedBox(height: 12),
            RestoredHomeUi.button(
              Icons.directions_car,
              'القياس حسب السيارة',
              'شركة → موديل → سنة → فئة → قياس',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehDbCarsPage())),
            ),
            const SizedBox(height: 12),
            RestoredHomeUi.button(
              Icons.history,
              'سجل السيارة والضمان',
              'احفظ التركيب والكيلومترات والضمان',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const expert.MaintenanceRecordsPage())),
            ),
          ],
        ),
      ),
    );
  }
}
