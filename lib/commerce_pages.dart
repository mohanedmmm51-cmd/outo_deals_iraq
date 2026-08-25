import 'package:flutter/material.dart';

import 'legacy_main.dart' as legacy;
import 'order_system.dart';

String _money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

class TiresPage extends StatelessWidget {
  const TiresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإطارات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: legacy.tires.length,
          itemBuilder: (context, index) {
            final tire = legacy.tires[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.tire_repair),
                title: Text(
                  tire.size,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('السعر النهائي: ${_money(tire.price)} د.ع'),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TireDetailsPage(tire: tire),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TireDetailsPage extends StatelessWidget {
  final legacy.Tire tire;

  const TireDetailsPage({super.key, required this.tire});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الإطار')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              color: orderYellow,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.tire_repair, size: 80),
                    const SizedBox(height: 12),
                    Text(
                      tire.size,
                      style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text('السعر النهائي للزبون'),
                    Text(
                      '${_money(tire.price)} د.ع',
                      style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Card(
              child: ListTile(
                leading: Icon(Icons.verified_outlined),
                title: Text('السعر مضمون داخل التطبيق'),
                subtitle: Text('اعرض كود الطلب للمحل قبل بدء العمل.'),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderTicketPage(
                    title: 'إطار ${tire.size}',
                    detail: 'سعر الزوج • شد وبلنص حسب العرض',
                    price: tire.price,
                    commission: tire.commission,
                  ),
                ),
              ),
              icon: const Icon(Icons.qr_code_2),
              label: const Text(
                'اطلب الآن وأنشئ الكود',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BatteriesPage extends StatelessWidget {
  const BatteriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البطاريات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: legacy.batteries.length,
          itemBuilder: (context, index) {
            final battery = legacy.batteries[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.battery_charging_full),
                title: Text(
                  '${battery.brand} ${battery.amp}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('اختار إذا تسلّم البطارية القديمة'),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BatteryDetailsPage(battery: battery),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BatteryDetailsPage extends StatefulWidget {
  final legacy.Battery battery;

  const BatteryDetailsPage({super.key, required this.battery});

  @override
  State<BatteryDetailsPage> createState() => _BatteryDetailsPageState();
}

class _BatteryDetailsPageState extends State<BatteryDetailsPage> {
  bool oldBattery = true;

  @override
  Widget build(BuildContext context) {
    final price = oldBattery ? widget.battery.withOld : widget.battery.withoutOld;
    const commission = 3000;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل البطارية')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.battery_charging_full, size: 80),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.battery.brand} ${widget.battery.amp}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<bool>(
                      value: true,
                      groupValue: oldBattery,
                      title: const Text('أسلّم البطارية القديمة'),
                      onChanged: (_) => setState(() => oldBattery = true),
                    ),
                    RadioListTile<bool>(
                      value: false,
                      groupValue: oldBattery,
                      title: const Text('بدون البطارية القديمة'),
                      onChanged: (_) => setState(() => oldBattery = false),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('السعر النهائي'),
                    Text(
                      '${_money(price)} د.ع',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTicketPage(
                            title: '${widget.battery.brand} ${widget.battery.amp}',
                            detail: oldBattery
                                ? 'مع تسليم البطارية القديمة'
                                : 'بدون تسليم البطارية القديمة',
                            price: price,
                            commission: commission,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('اطلب الآن وأنشئ الكود'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
