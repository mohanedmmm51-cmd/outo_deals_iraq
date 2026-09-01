part of '../expert_features.dart';

class ExpertAdvicePage extends StatelessWidget {
  const ExpertAdvicePage({super.key});

  Widget tip(IconData icon, String title, String body) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: yellow,
              child: Icon(icon, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            tip(
              Icons.calendar_month,
              'تاريخ الإطار DOT',
              'لا تشتري على الاسم والسعر فقط. افحص تاريخ الإنتاج وحالة التخزين، خصوصًا إذا الإطار مخزون من فترة طويلة.',
            ),
            tip(
              Icons.speed,
              'ضغط الهواء',
              'الضغط القليل يزيد الحرارة والتآكل من الجانبين، والضغط الزائد يقلل الراحة ويأكل منتصف الإطار. اعتمد ضغط سيارتك الموصى به.',
            ),
            tip(
              Icons.tire_repair,
              'بدّل زوج لو لازم',
              'إذا إطارين تعبانين، الأفضل يكون الزوج الجديد على نفس المحور وبنفس النقشة والمقاس. اختلاف كبير بالتآكل يضر الثبات.',
            ),
            tip(
              Icons.alt_route,
              'مدينة أو سفر؟',
              'للمدينة ركّز على الهدوء والراحة. للسفر والحر ركّز أكثر على التحمل والتماسك ودرجة الحرارة.',
            ),
            tip(
              Icons.warning_amber,
              'تآكل من طرف واحد',
              'غالبًا يحتاج فحص ميزان/زوايا أو أجزاء تعليق، مو مجرد تبديل إطار. عالج السبب حتى ما يتكرر التآكل.',
            ),
            tip(
              Icons.battery_charging_full,
              'البطارية',
              'لا تعتمد على الأمبير فقط؛ لازم المقاس والقطبية ونوع السيارة مناسبين. سيارات Start/Stop قد تحتاج AGM أو EFB.',
            ),
            tip(
              Icons.electric_bolt,
              'قبل تبديل البطارية',
              'إذا البطارية تفرغ بسرعة، افحص الشحن والدينمو والتسريب الكهربائي حتى لا تبدّل بطارية سليمة بسبب عطل ثاني.',
            ),
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
    if (tire.wholesale < 85000)
      return 'اقتصادي ومناسب للاستخدام اليومي إذا كان القياس مطابق لسيارتك.';
    if (tire.wholesale < 115000)
      return 'فئة متوازنة بين السعر والتحمل؛ خيار جيد للمدينة والسفر المعتدل.';
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
                selected.isEmpty
                    ? 'اختار من 2 إلى 3 إطارات للمقارنة'
                    : 'تم اختيار ${selected.length} من 3',
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
                    title: Text(
                      tire.size,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                    ),
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
                              const Text(
                                'نتيجة المقارنة',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...chosen.map(
                                (tire) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tire.size,
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'السعر النهائي: ${money(tire.price)} د.ع',
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'نصيحة الخبير: ${expertNote(tire)}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
