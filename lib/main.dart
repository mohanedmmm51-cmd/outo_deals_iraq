import 'package:flutter/material.dart';

import 'commerce_pages.dart' as commerce;
import 'expert_features_backup.dart' as expert;
import 'legacy_main.dart' as legacy;
import 'order_system.dart';

void main() => runApp(const App());

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
            _open(context, const legacy.NearbyShopsPage());
          } else if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('السلة راح نربطها بالمرحلة الجاية')),
            );
          } else if (index == 3) {
            _open(context, const MyOrdersPage());
          } else if (index == 4) {
            _open(context, const ShopPortalPage());
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
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu, color: Colors.white, size: 30),
                        Spacer(),
                        Column(
                          children: [
                            Text('إطارات وبطاريات العراق', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            Text('الجودة .. بأقرب محل', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        Spacer(),
                        Icon(Icons.notifications_none, color: Colors.white, size: 30),
                      ],
                    ),
                    SizedBox(height: 22),
                    DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(16))),
                      child: SizedBox(
                        height: 54,
                        child: Row(children: [SizedBox(width: 16), Icon(Icons.search, size: 30), SizedBox(width: 10), Text('شنو تحتاج؟ إطارات أو بطاريات...', style: TextStyle(color: Colors.grey, fontSize: 16))]),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    actionButton(context, Icons.workspace_premium, 'مركز الخبير', 'نصيحة خبير + مقارنة + اختيار بطارية + سجل صيانة', yellow, () => _open(context, const expert.ExpertCenterPage())),
                    const SizedBox(height: 14),
                    actionButton(context, Icons.directions_car, 'اختار سيارتك', 'اعرف قياس الإطار المناسب لسيارتك', yellow, () => _open(context, const legacy.CarsPage())),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: categoryButton(context, 'الإطارات', const TireCategoryIcon(), () => _open(context, const commerce.TiresPage()))),
                        const SizedBox(width: 12),
                        Expanded(child: categoryButton(context, 'البطاريات', const BatteryCategoryIcon(), () => _open(context, const commerce.BatteriesPage()))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    actionButton(context, Icons.receipt_long, 'طلباتي', 'تابع كود الطلب وحالة التنفيذ', Colors.white, () => _open(context, const MyOrdersPage())),
                    const SizedBox(height: 14),
                    actionButton(context, Icons.storefront, 'بوابة صاحب المحل', 'فحص كود الزبون وتأكيد تنفيذ الطلب', Colors.white, () => _open(context, const ShopPortalPage())),
                    const SizedBox(height: 14),
                    actionButton(context, Icons.straighten, 'طلب قياس', 'ما لكيت القياس؟ أرسل طلب للمحلات', yellow, () => _open(context, const expert.RequestSizePage())),
                    const SizedBox(height: 14),
                    actionButton(context, Icons.location_on, 'المحلات القريبة', 'المسافة + الأقرب + الاتجاهات', Colors.white, () => _open(context, const legacy.NearbyShopsPage())),
                    const SizedBox(height: 14),
                    actionButton(context, Icons.add_business, 'إضافة محل', 'طلب انضمام لأصحاب المحلات', Colors.white, () => _open(context, const legacy.AddShopPage())),
                    const SizedBox(height: 14),
                    actionButton(context, Icons.local_offer, 'العروض والخصومات', 'شوف أحدث العروض المتوفرة', Colors.white, () => _open(context, const legacy.OffersPage())),
                    const SizedBox(height: 14),
                    actionButton(context, Icons.support_agent, 'التواصل مع الدعم', 'مساعدة واستفسارات', Colors.white, () => _open(context, const legacy.SupportPage())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget actionButton(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
        child: Row(children: [Icon(icon, size: 45, color: Colors.black), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), Text(subtitle)])), const Icon(Icons.arrow_back_ios_new, size: 18)]),
      ),
    );
  }

  static Widget categoryButton(BuildContext context, String title, Widget icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 150,
        decoration: BoxDecoration(color: const Color(0xff171717), borderRadius: BorderRadius.circular(20), border: Border.all(color: yellow.withValues(alpha: .20))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [icon, const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))]),
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
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: yellow, width: 8), boxShadow: [BoxShadow(color: yellow.withValues(alpha: .18), blurRadius: 12)]),
      child: Center(child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: yellow, width: 3)), child: const Icon(Icons.settings, color: yellow, size: 17))),
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
            decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(9), boxShadow: [BoxShadow(color: yellow.withValues(alpha: .18), blurRadius: 12)]),
            child: const Center(child: Icon(Icons.bolt, color: Colors.black, size: 36)),
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 14, height: 9, decoration: const BoxDecoration(color: yellow, borderRadius: BorderRadius.vertical(top: Radius.circular(3)))), const SizedBox(width: 25), Container(width: 14, height: 9, decoration: const BoxDecoration(color: yellow, borderRadius: BorderRadius.vertical(top: Radius.circular(3))))]),
      ],
    );
  }
}

class ShopPortalPage extends StatelessWidget {
  const ShopPortalPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بوابة صاحب المحل')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Card(color: yellow, child: Padding(padding: EdgeInsets.all(18), child: Column(children: [Icon(Icons.storefront, size: 70), SizedBox(height: 8), Text('تأكيد الطلب قبل تنفيذ الخدمة', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('صاحب المحل يفحص كود الزبون، وبعد التنفيذ يؤكد الطلب حتى تُسجّل العملية والعمولة.', textAlign: TextAlign.center)]))),
            const SizedBox(height: 14),
            FilledButton.icon(style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopConfirmOrderPage())), icon: const Icon(Icons.qr_code_scanner), label: const Text('فحص كود الطلب')),
            const SizedBox(height: 12),
            const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('نسخة تجريبية محلية'), subtitle: Text('حالياً الطلب والتأكيد محفوظين على نفس الجهاز. بالمرحلة التالية نربطهم بالإنترنت حتى يظهر الطلب مباشرة عند المحل الحقيقي.'))),
          ],
        ),
      ),
    );
  }
}
