part of '../expert_features.dart';

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
    final list = set.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return list;
  }

  List<legacy.Battery> get matches {
    if (amp == null) return [];
    return legacy.batteries
        .where(
          (b) =>
              RegExp('(^|\\D)${RegExp.escape(amp!)}(\\D|\$)').hasMatch(b.amp),
        )
        .toList();
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
            const Text(
              'اختار الأمبير المكتوب على بطاريتك الحالية أو الموصى به للسيارة.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: amp,
              decoration: const InputDecoration(
                labelText: 'الأمبير',
                border: OutlineInputBorder(),
              ),
              items: amps
                  .map(
                    (a) => DropdownMenuItem(value: a, child: Text('$a أمبير')),
                  )
                  .toList(),
              onChanged: (v) => setState(() => amp = v),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: startStop,
              onChanged: (v) => setState(() => startStop = v),
              title: const Text('السيارة بيها Start/Stop'),
              subtitle: const Text(
                'قد تحتاج AGM/EFB؛ تأكد من مواصفات السيارة قبل الشراء.',
              ),
            ),
            SwitchListTile(
              value: hasOld,
              onChanged: (v) => setState(() => hasOld = v),
              title: const Text('راح أسلّم البطارية القديمة'),
              subtitle: const Text(
                'السعر يتغير حسب سياسة استلام البطارية القديمة.',
              ),
            ),
            if (startStop)
              const Card(
                color: Color(0xfffff3cd),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'تنبيه خبير: لا تستبدل بطارية AGM/EFB ببطارية عادية قبل التأكد من مواصفات السيارة ونظام الشحن.',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (amp != null && matches.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'ماكو بطارية مطابقة بهذا الأمبير ضمن القائمة الحالية.',
                  ),
                ),
              ),
            ...matches.map((b) {
              final price = hasOld ? b.withOld : b.withoutOld;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: yellow,
                    child: Icon(Icons.battery_full, color: Colors.black),
                  ),
                  title: Text(
                    '${b.brand} - ${b.amp}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'السعر النهائي: ${money(price)} د.ع\nتأكد من المقاس والقطبية قبل التركيب.',
                  ),
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
