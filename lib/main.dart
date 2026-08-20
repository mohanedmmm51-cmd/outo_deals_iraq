import 'package:flutter/material.dart';

void main() {
  runApp(const AutoDealsIraqApp());
}

class AutoDealsIraqApp extends StatelessWidget {
  const AutoDealsIraqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عروض سيارتك',
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6CBD),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        fontFamily: 'Arial',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    CustomerHomePage(),
    OffersPage(),
    OrdersPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'العروض',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'طلباتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  void openCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: ProductSearchPage(category: category),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                child: Icon(Icons.directions_car),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'أهلاً بيك 👋',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'اختار المنتج وخلي إحنا نجيبلك أفضل عرض',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أفضل سعر من محلات موثوقة',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نقارن الأسعار والعروض ونرسل طلبك للمحل الأنسب، وما يطلع اسم المحل إلا بعد قبول الطلب.',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => openCategory(context, 'الإطارات'),
                  icon: const Icon(Icons.search),
                  label: const Text('ابدأ البحث'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'شنو تحتاج اليوم؟',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CategoryCard(
                  title: 'إطارات',
                  subtitle: 'أفضل سعر + خدمات',
                  icon: Icons.tire_repair,
                  onTap: () => openCategory(context, 'الإطارات'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CategoryCard(
                  title: 'بطاريات',
                  subtitle: 'حسب نوع السيارة',
                  icon: Icons.battery_charging_full,
                  onTap: () => openCategory(context, 'البطاريات'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'شلون يشتغل التطبيق؟',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const StepTile(
            number: '1',
            title: 'اختار المنتج',
            subtitle: 'حدد المقاس أو نوع السيارة والكمية.',
          ),
          const StepTile(
            number: '2',
            title: 'نجيب أفضل عرض',
            subtitle: 'السعر النهائي ويّاه الخدمات المجانية.',
          ),
          const StepTile(
            number: '3',
            title: 'المحل يقبل الطلب',
            subtitle: 'يوصله السعر والتفاصيل ويضغط قبول أو رفض.',
          ),
          const StepTile(
            number: '4',
            title: 'تستلم كود + QR',
            subtitle: 'بعد القبول يظهر اسم المحل وموقعه ورمز الطلب.',
          ),
          const StepTile(
            number: '5',
            title: 'تروح للمحل',
            subtitle: 'المحل يمسح الرمز ويؤكد تنفيذ الطلب.',
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(icon, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const StepTile({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            child: Text(number),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductSearchPage extends StatefulWidget {
  final String category;

  const ProductSearchPage({super.key, required this.category});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  String brand = 'تويوتا';
  String model = 'كامري';
  String year = '2022';
  String quantity = '4';
  String size = '215/55 R17';

  @override
  Widget build(BuildContext context) {
    final isTire = widget.category == 'الإطارات';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'حدد تفاصيل طلبك',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'راح نستخدم هالمعلومات حتى نقارن أسعار المحلات ونجيبلك أفضل عرض.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            AppDropdown(
              label: 'شركة السيارة',
              value: brand,
              items: const ['تويوتا', 'نيسان', 'كيا', 'هيونداي', 'شفروليه'],
              onChanged: (v) => setState(() => brand = v!),
            ),
            AppDropdown(
              label: 'الموديل',
              value: model,
              items: const ['كامري', 'كورولا', 'لاندكروزر', 'سوناتا', 'سبورتج'],
              onChanged: (v) => setState(() => model = v!),
            ),
            AppDropdown(
              label: 'السنة',
              value: year,
              items: const ['2026', '2025', '2024', '2023', '2022', '2021'],
              onChanged: (v) => setState(() => year = v!),
            ),
            if (isTire)
              AppDropdown(
                label: 'مقاس الإطار',
                value: size,
                items: const [
                  '195/65 R15',
                  '205/55 R16',
                  '215/55 R17',
                  '225/60 R18',
                  '265/65 R17',
                ],
                onChanged: (v) => setState(() => size = v!),
              ),
            AppDropdown(
              label: 'الكمية',
              value: quantity,
              items: const ['1', '2', '4'],
              onChanged: (v) => setState(() => quantity = v!),
            ),
            const SizedBox(height: 6),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: BestOfferPage(
                        category: widget.category,
                        quantity: quantity,
                        detail: isTire ? size : '$brand $model $year',
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.price_check),
              label: const Text('شوف أفضل عرض'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class BestOfferPage extends StatelessWidget {
  final String category;
  final String quantity;
  final String detail;

  const BestOfferPage({
    super.key,
    required this.category,
    required this.quantity,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = category == 'الإطارات' ? 480000 : 135000;

    return Scaffold(
      appBar: AppBar(title: const Text('أفضل عرض')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, size: 46),
                  const SizedBox(height: 10),
                  const Text(
                    'أفضل عرض متوفر',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  DetailRow(label: 'المنتج', value: category),
                  DetailRow(label: 'التفاصيل', value: detail),
                  DetailRow(label: 'الكمية', value: quantity),
                  DetailRow(
                    label: 'السعر النهائي',
                    value: '${formatPrice(totalPrice)} د.ع',
                  ),
                  const Divider(height: 28),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'يشمل العرض:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const BenefitTile(text: 'شد وتركيب مجاني'),
                  const BenefitTile(text: 'بلنص مجاني'),
                  const BenefitTile(text: 'سعر خاص لمستخدمي التطبيق'),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Directionality(
                      textDirection: TextDirection.rtl,
                      child: WaitingForShopPage(),
                    ),
                  ),
                );
              },
              child: const Text('إرسال الطلب للمحل'),
            ),
            const SizedBox(height: 8),
            const Text(
              'اسم المحل ما يظهر إلا بعد ما يقبل الطلب.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

String formatPrice(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[i]);
  }
  return buffer.toString();
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class BenefitTile extends StatelessWidget {
  final String text;

  const BenefitTile({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class WaitingForShopPage extends StatelessWidget {
  const WaitingForShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            const CircularProgressIndicator(),
            const SizedBox(height: 22),
            const Text(
              'جاري إرسال الطلب للمحل...',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'المحل راح يشوف تفاصيل الطلب والسعر ويختار قبول أو رفض.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Directionality(
                      textDirection: TextDirection.rtl,
                      child: AcceptedOrderPage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.bolt),
              label: const Text('محاكاة قبول المحل'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class AcceptedOrderPage extends StatelessWidget {
  const AcceptedOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    const orderCode = '482731';

    return Scaffold(
      appBar: AppBar(title: const Text('تم قبول الطلب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 58, color: Colors.green),
                  const SizedBox(height: 10),
                  const Text(
                    'المحل قبل طلبك',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const DetailRow(label: 'المحل', value: 'مركز بغداد للإطارات'),
                  const DetailRow(label: 'السعر', value: '480,000 د.ع'),
                  const DetailRow(label: 'الخدمات', value: 'شد + بلنص مجاني'),
                  const DetailRow(label: 'العنوان', value: 'بغداد - الكرادة'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'كود الطلب',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    orderCode,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 125),
                        SizedBox(height: 4),
                        Text('QR تجريبي'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'خلي صاحب المحل يمسح الرمز عند وصولك.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'العروض',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 14),
        OfferCard(
          title: '4 إطارات + شد وبلنص مجاني',
          subtitle: 'عرض خاص لمستخدمي التطبيق',
          price: '480,000 د.ع',
        ),
        OfferCard(
          title: 'بطارية مع فحص دينمو',
          subtitle: 'فحص مجاني عند التركيب',
          price: '135,000 د.ع',
        ),
      ],
    );
  }
}

class OfferCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;

  const OfferCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.local_offer)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'طلباتي',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.tire_repair)),
            title: const Text('طلب إطارات'),
            subtitle: const Text('تم قبول الطلب • 480,000 د.ع'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Directionality(
                    textDirection: TextDirection.rtl,
                    child: AcceptedOrderPage(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'المزيد',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        const Card(
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('حسابي'),
            trailing: Icon(Icons.chevron_left),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.location_on_outlined),
            title: Text('عناويني'),
            trailing: Icon(Icons.chevron_left),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.support_agent),
            title: Text('الدعم'),
            trailing: Icon(Icons.chevron_left),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'واجهة أصحاب المحلات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: null,
          icon: Icon(Icons.storefront),
          label: Text('سنربطها بحساب المحل بالمرحلة القادمة'),
        ),
      ],
    );
  }
}
