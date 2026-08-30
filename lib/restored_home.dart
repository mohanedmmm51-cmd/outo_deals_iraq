import 'package:flutter/material.dart';

import 'commerce_pages.dart' as commerce;
import 'expert_features_backup.dart' as expert;
import 'legacy_main.dart' as legacy;
import 'marketplace_features.dart';
import 'size_request_page.dart';
import 'vehdb_cars_page.dart';

const restoredYellow = Color(0xFFFFD400);

class RestoredHome extends StatelessWidget {
  const RestoredHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu, color: Colors.white, size: 30),
                        Spacer(),
                        Column(
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
                        Spacer(),
                        Icon(Icons.notifications_none, color: Colors.white, size: 30),
                      ],
                    ),
                    SizedBox(height: 22),
                    DecoratedBox(
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
                    _button(
                      context,
                      Icons.workspace_premium,
                      'مركز الخبير',
                      'نصيحة خبير + مقارنة + اختيار بطارية + سجل صيانة',
                      restoredYellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RestoredExpertCenterPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _button(
                      context,
                      Icons.directions_car,
                      'اختار سيارتك',
                      'اعرف قياس الإطار المناسب لسيارتك',
                      restoredYellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VehDbCarsPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _cat(
                            context,
                            Icons.tire_repair,
                            'الإطارات',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const commerce.TiresPage()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _cat(
                            context,
                            Icons.battery_charging_full,
                            'البطاريات',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const commerce.BatteriesPage()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _button(
                      context,
                      Icons.straighten,
                      'طلب قياس',
                      'ما لكيت القياس؟ أرسل طلب للمحلات',
                      restoredYellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EnhancedSizeRequestPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _button(
                      context,
                      Icons.location_on,
                      'المحلات القريبة',
                      'المسافة + الأقرب + الاتجاهات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnlineNearbyShopsPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _button(
                      context,
                      Icons.add_business,
                      'إضافة محل',
                      'طلب انضمام لأصحاب المحلات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const legacy.AddShopPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _button(
                      context,
                      Icons.local_offer,
                      'العروض والخصومات',
                      'شوف أحدث العروض المتوفرة',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnlineOffersPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _button(
                      context,
                      Icons.support_agent,
                      'التواصل مع الدعم',
                      'مساعدة واستفسارات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const legacy.SupportPage()),
                      ),
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

  static Widget _button(
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

  static Widget _cat(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xff171717),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: restoredYellow, size: 52),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
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
              decoration: BoxDecoration(
                color: const Color(0xff111111),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium, color: restoredYellow, size: 58),
                  SizedBox(height: 8),
                  Text(
                    'خبرة عملية قبل لا تشتري',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
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
            RestoredHome._button(
              context,
              Icons.tips_and_updates,
              'نصيحة الخبير',
              'DOT، التآكل، الضغط، المدينة والسفر',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const expert.ExpertAdvicePage())),
            ),
            const SizedBox(height: 12),
            RestoredHome._button(
              context,
              Icons.compare_arrows,
              'مقارنة الإطارات',
              'قارن حتى 3 قياسات وأسعار ونصيحة الاستخدام',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const expert.TireComparisonPage())),
            ),
            const SizedBox(height: 12),
            RestoredHome._button(
              context,
              Icons.battery_saver,
              'مساعد البطارية',
              'اختيار حسب الأمبير وStart/Stop والبطارية القديمة',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const expert.BatteryAdvisorPage())),
            ),
            const SizedBox(height: 12),
            RestoredHome._button(
              context,
              Icons.directions_car,
              'القياس حسب السيارة',
              'شركة → موديل → سنة → فئة → قياس',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehDbCarsPage())),
            ),
            const SizedBox(height: 12),
            RestoredHome._button(
              context,
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
