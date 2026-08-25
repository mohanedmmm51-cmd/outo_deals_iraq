import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'legacy_main.dart' as legacy;

void main() => runApp(const App());

const yellow = Color(0xFFFFD400);

String money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

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
                      Icons.workspace_premium,
                      'مركز الخبير',
                      'نصيحة خبير + مقارنة + اختيار بطارية + سجل صيانة',
                      yellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExpertCenterPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
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

class ExpertCenterPage extends StatelessWidget {
  const ExpertCenterPage({super.key});

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
                  Icon(Icons.workspace_premium, color: yellow, size: 58),
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
            Home.button(
              context,
              Icons.tips_and_updates,
              'نصيحة الخبير',
              'DOT، التآكل، الضغط، المدينة والسفر',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertAdvicePage())),
            ),
            const SizedBox(height: 12),
            Home.button(
              context,
              Icons.compare_arrows,
              'مقارنة الإطارات',
              'قارن حتى 3 قياسات وأسعار ونصيحة الاستخدام',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TireComparisonPage())),
            ),
            const SizedBox(height: 12),
            Home.button(
              context,
              Icons.battery_saver,
              'مساعد البطارية',
              'اختيار حسب الأمبير وStart/Stop والبطارية القديمة',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatteryAdvisorPage())),
            ),
            const SizedBox(height: 12),
            Home.button(
              context,
              Icons.directions_car,
              'القياس حسب السيارة',
              'شركة → موديل → سنة → فئة → قياس',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const legacy.CarsPage())),
            ),
            const SizedBox(height: 12),
            Home.button(
              context,
              Icons.history,
              'سجل السيارة والضمان',
              'احفظ التركيب والكيلومترات والضمان',
              Colors.white,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceRecordsPage())),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpertAdvicePage extends StatelessWidget {
  const ExpertAdvicePage({super.key});

  Widget tip(IconData icon, String title, String body) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: yellow, child: Icon(icon, color: Colors.black)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نصيحة الخبير')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            tip(Icons.calendar_month, 'تاريخ الإطار DOT', 'لا تشتري على الاسم والسعر فقط. افحص تاريخ الإنتاج وحالة التخزين، خصوصًا إذا الإطار مخزون من فترة طويلة.'),
            tip(Icons.speed, 'ضغط الهواء', 'الضغط القليل يزيد الحرارة والتآكل من الجانبين، والضغط الزائد يقلل الراحة ويأكل منتصف الإطار. اعتمد ضغط سيارتك الموصى به.'),
            tip(Icons.tire_repair, 'بدّل زوج لو لازم', 'إذا إطارين تعبانين، الأفضل يكون الزوج الجديد على نفس المحور وبنفس النقشة والمقاس. اختلاف كبير بالتآكل يضر الثبات.'),
            tip(Icons.alt_route, 'مدينة أو سفر؟', 'للمدينة ركّز على الهدوء والراحة. للسفر والحر ركّز أكثر على التحمل والتماسك ودرجة الحرارة.'),
            tip(Icons.warning_amber, 'تآكل من طرف واحد', 'غالبًا يحتاج فحص ميزان/زوايا أو أجزاء تعليق، مو مجرد تبديل إطار. عالج السبب حتى ما يتكرر التآكل.'),
            tip(Icons.battery_charging_full, 'البطارية', 'لا تعتمد على الأمبير فقط؛ لازم المقاس والقطبية ونوع السيارة مناسبين. سيارات Start/Stop قد تحتاج AGM أو EFB.'),
            tip(Icons.electric_bolt, 'قبل تبديل البطارية', 'إذا البطارية تفرغ بسرعة، افحص الشحن والدينمو والتسريب الكهربائي حتى لا تبدّل بطارية سليمة بسبب عطل ثاني.'),
          ],
        ),
      ),
    );
  }
}

class TireComparisonPage extends StatefulWidget {
  const TireComparisonPage({super.key});

  @override
  State<TireComparisonPage> createState() => _TireComparisonPageState();
}

class _TireComparisonPageState extends State<TireComparisonPage> {
  final Set<int> selected = {};

  String expertNote(legacy.Tire tire) {
    if (tire.wholesale < 85000) return 'اقتصادي ومناسب للاستخدام اليومي إذا كان القياس مطابق لسيارتك.';
    if (tire.wholesale < 115000) return 'فئة متوازنة بين السعر والتحمل؛ خيار جيد للمدينة والسفر المعتدل.';
    return 'فئة أعلى بالسعر؛ قارن بلد المنشأ والضمان والنقشة قبل القرار.';
  }

  @override
  Widget build(BuildContext context) {
    final chosen = selected.map((i) => legacy.tires[i]).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('مقارنة الإطارات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                selected.isEmpty ? 'اختار من 2 إلى 3 إطارات للمقارنة' : 'تم اختيار ${selected.length} من 3',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: legacy.tires.length,
                itemBuilder: (context, index) {
                  final tire = legacy.tires[index];
                  final active = selected.contains(index);
                  return CheckboxListTile(
                    value: active,
                    title: Text(tire.size, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('السعر النهائي: ${money(tire.price)} د.ع'),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          if (selected.length < 3) selected.add(index);
                        } else {
                          selected.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            if (chosen.length >= 2)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: Color(0xff111111)),
                child: SafeArea(
                  top: false,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: yellow, foregroundColor: Colors.black),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(18),
                            children: [
                              const Text('نتيجة المقارنة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ...chosen.map((tire) => Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tire.size, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                                          Text('السعر النهائي: ${money(tire.price)} د.ع'),
                                          const SizedBox(height: 6),
                                          Text('نصيحة الخبير: ${expertNote(tire)}'),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.compare),
                    label: const Text('عرض المقارنة'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BatteryAdvisorPage extends StatefulWidget {
  const BatteryAdvisorPage({super.key});

  @override
  State<BatteryAdvisorPage> createState() => _BatteryAdvisorPageState();
}

class _BatteryAdvisorPageState extends State<BatteryAdvisorPage> {
  String? amp;
  bool startStop = false;
  bool hasOld = true;

  List<String> get amps {
    final set = <String>{};
    for (final b in legacy.batteries) {
      final match = RegExp(r'\d+').firstMatch(b.amp);
      if (match != null) set.add(match.group(0)!);
    }
    final list = set.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return list;
  }

  List<legacy.Battery> get matches {
    if (amp == null) return [];
    return legacy.batteries.where((b) => RegExp('(^|\\D)${RegExp.escape(amp!)}(\\D|\$)').hasMatch(b.amp)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مساعد اختيار البطارية')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('اختار الأمبير المكتوب على بطاريتك الحالية أو الموصى به للسيارة.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: amp,
              decoration: const InputDecoration(labelText: 'الأمبير', border: OutlineInputBorder()),
              items: amps.map((a) => DropdownMenuItem(value: a, child: Text('$a أمبير'))).toList(),
              onChanged: (v) => setState(() => amp = v),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: startStop,
              onChanged: (v) => setState(() => startStop = v),
              title: const Text('السيارة بيها Start/Stop'),
              subtitle: const Text('قد تحتاج AGM/EFB؛ تأكد من مواصفات السيارة قبل الشراء.'),
            ),
            SwitchListTile(
              value: hasOld,
              onChanged: (v) => setState(() => hasOld = v),
              title: const Text('راح أسلّم البطارية القديمة'),
              subtitle: const Text('السعر يتغير حسب سياسة استلام البطارية القديمة.'),
            ),
            if (startStop)
              const Card(
                color: Color(0xfffff3cd),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('تنبيه خبير: لا تستبدل بطارية AGM/EFB ببطارية عادية قبل التأكد من مواصفات السيارة ونظام الشحن.'),
                ),
              ),
            const SizedBox(height: 8),
            if (amp != null && matches.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('ماكو بطارية مطابقة بهذا الأمبير ضمن القائمة الحالية.'))),
            ...matches.map((b) {
              final price = hasOld ? b.withOld : b.withoutOld;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: yellow, child: Icon(Icons.battery_full, color: Colors.black)),
                  title: Text('${b.brand} - ${b.amp}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('السعر النهائي: ${money(price)} د.ع\nتأكد من المقاس والقطبية قبل التركيب.'),
                  isThreeLine: true,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class MaintenanceRecordsPage extends StatefulWidget {
  const MaintenanceRecordsPage({super.key});

  @override
  State<MaintenanceRecordsPage> createState() => _MaintenanceRecordsPageState();
}

class _MaintenanceRecordsPageState extends State<MaintenanceRecordsPage> {
  static const keyName = 'vehicle_maintenance_records';
  final product = TextEditingController();
  final car = TextEditingController();
  final km = TextEditingController();
  final warranty = TextEditingController();
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    product.dispose();
    car.dispose();
    km.dispose();
    warranty.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(keyName) ?? [];
    if (!mounted) return;
    setState(() {
      records = raw.map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map)).toList().reversed.toList();
    });
  }

  Future<void> addRecord() async {
    if (product.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(keyName) ?? [];
    raw.add(jsonEncode({
      'product': product.text.trim(),
      'car': car.text.trim(),
      'km': km.text.trim(),
      'warranty': warranty.text.trim(),
      'date': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(keyName, raw);
    product.clear();
    car.clear();
    km.clear();
    warranty.clear();
    await load();
  }

  Future<void> openAddDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة سجل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: product, decoration: const InputDecoration(labelText: 'المنتج: إطار أو بطارية')),
                TextField(controller: car, decoration: const InputDecoration(labelText: 'السيارة')),
                TextField(controller: km, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكيلومترات عند التركيب')),
                TextField(controller: warranty, decoration: const InputDecoration(labelText: 'الضمان / ملاحظة')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                await addRecord();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  String dateLabel(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return '';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل السيارة والضمان')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة سجل'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: records.isEmpty
            ? const Center(child: Text('ماكو سجلات بعد. احفظ أول تبديل إطار أو بطارية.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final r = records[index];
                  final details = <String>[
                    if ('${r['car'] ?? ''}'.isNotEmpty) 'السيارة: ${r['car']}',
                    if ('${r['km'] ?? ''}'.isNotEmpty) 'العداد: ${r['km']} كم',
                    if ('${r['warranty'] ?? ''}'.isNotEmpty) 'الضمان: ${r['warranty']}',
                    'التاريخ: ${dateLabel('${r['date'] ?? ''}')}',
                  ];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: yellow, child: Icon(Icons.history, color: Colors.black)),
                      title: Text('${r['product']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(details.join('\n')),
                      isThreeLine: true,
                    ),
                  );
                },
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
                validator: (value) => value == null || value.trim().isEmpty ? 'اكتب قياس الإطار' : null,
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
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
