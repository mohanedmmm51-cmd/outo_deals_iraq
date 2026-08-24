import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'legacy_main.dart' as legacy;

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
                    button(
                      context,
                      Icons.directions_car,
                      'اختار سيارتك',
                      'اعرف قياس الإطار المناسب لسيارتك',
                      yellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const legacy.CarsPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: cat(
                            context,
                            Icons.tire_repair,
                            'الإطارات',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const legacy.TiresPage()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: cat(
                            context,
                            Icons.battery_charging_full,
                            'البطاريات',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const legacy.BatteriesPage()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.straighten,
                      'طلب قياس',
                      'ما لكيت القياس؟ أرسل طلب للمحلات',
                      yellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RequestSizePage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.location_on,
                      'المحلات القريبة',
                      'المسافة + الأقرب + الاتجاهات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const legacy.NearbyShopsPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
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
                    button(
                      context,
                      Icons.local_offer,
                      'العروض والخصومات',
                      'شوف أحدث العروض المتوفرة',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const legacy.OffersPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
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

  static Widget button(
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
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
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

  static Widget cat(
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
            Icon(icon, color: yellow, size: 52),
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

class RequestSizePage extends StatefulWidget {
  const RequestSizePage({super.key});

  @override
  State<RequestSizePage> createState() => _RequestSizePageState();
}

class _RequestSizePageState extends State<RequestSizePage> {
  static const _storageKey = 'pending_tire_size_requests';
  final _formKey = GlobalKey<FormState>();
  final _size = TextEditingController();
  final _brand = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _size.dispose();
    _brand.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final request = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'size': _size.text.trim(),
      'brand': _brand.text.trim(),
      'notes': _notes.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_storageKey) ?? <String>[];
      existing.add(jsonEncode(request));
      await prefs.setStringList(_storageKey, existing);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تم إرسال طلب القياس'),
          content: const Text(
            'تم حفظ طلبك. عند ربط قاعدة بيانات المحلات راح يظهر الطلب لأصحاب المحلات مباشرة بدون رقم هاتف الزبون.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ الطلب. حاول مرة ثانية.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب قياس')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.straighten, size: 78, color: Color(0xff111111)),
              const SizedBox(height: 10),
              const Text(
                'اطلب قياس إطار غير موجود',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'دخل القياس، وإذا تريد أضف الماركة أو ملاحظة. ما نطلب رقم هاتفك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _size,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'قياس الإطار',
                  hintText: 'مثال: 225/45/17',
                  prefixIcon: Icon(Icons.tire_repair),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب قياس الإطار'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brand,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'الماركة أو النوع (اختياري)',
                  hintText: 'مثال: هانكوك أو صيني',
                  prefixIcon: Icon(Icons.sell_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  hintText: 'أي تفاصيل إضافية عن الطلب',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.campaign_outlined),
                label: const Text('إرسال الطلب للمحلات'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff111111),
                  foregroundColor: yellow,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
