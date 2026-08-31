import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'customer_cart.dart';
import 'legacy_main.dart' as legacy;
import 'order_system.dart';

String _money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

String _priceRuleId(String category, String key) =>
    '${category}_$key'.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

Future<int> _remotePrice(String category, String key, int fallback) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('price_rules')
        .doc(_priceRuleId(category, key))
        .get();
    return (doc.data()?['value'] as num?)?.toInt() ?? fallback;
  } catch (_) {
    return fallback;
  }
}

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
            return FutureBuilder<int>(
              future: _remotePrice('tires', tire.size, tire.price),
              builder: (context, snap) {
                final price = snap.data ?? tire.price;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.tire_repair),
                    title: Text(tire.size, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('السعر النهائي: ${_money(price)} د.ع'),
                    trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TireDetailsPage(tire: tire)),
                    ),
                  ),
                );
              },
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
    return FutureBuilder<int>(
      future: _remotePrice('tires', tire.size, tire.price),
      builder: (context, snap) {
        final price = snap.data ?? tire.price;
        const detail = 'سعر الزوج • شد وبلنص حسب العرض';
        final productId = 'tire-${tire.size}';
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
                        Text(tire.size, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text('السعر النهائي للزبون'),
                        Text('${_money(price)} د.ع', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.verified_outlined),
                    title: Text('السعر مضمون داخل التطبيق'),
                    subtitle: Text('بعد إنشاء الكود يبقى السعر مثبت طول فترة صلاحية الطلب.'),
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
                        detail: detail,
                        price: price,
                        commission: tire.commission,
                        productId: productId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('اطلب الآن وأنشئ الكود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  onPressed: () async {
                    await CustomerCartStore.add(
                      CartItem(
                        id: productId,
                        productId: productId,
                        title: 'إطار ${tire.size}',
                        detail: detail,
                        price: price,
                        commission: tire.commission,
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إضافة الإطار إلى السلة')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('أضف إلى السلة'),
                ),
              ],
            ),
          ),
        );
      },
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
                title: Text('${battery.brand} ${battery.amp}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('اختار إذا تسلّم البطارية القديمة'),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BatteryDetailsPage(battery: battery)),
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

  String get _baseKey => '${widget.battery.brand}_${widget.battery.amp}';

  @override
  Widget build(BuildContext context) {
    final fallback = oldBattery ? widget.battery.withOld : widget.battery.withoutOld;
    final key = '${_baseKey}_${oldBattery ? 'with_old' : 'without_old'}';
    return FutureBuilder<int>(
      future: _remotePrice('batteries', key, fallback),
      builder: (context, snap) {
        final price = snap.data ?? fallback;
        const commission = 3000;
        final detail = oldBattery ? 'مع تسليم البطارية القديمة' : 'بدون تسليم البطارية القديمة';
        final title = '${widget.battery.brand} ${widget.battery.amp}';
        final productId = 'battery-${widget.battery.brand}-${widget.battery.amp}';
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
                        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                        Text('${_money(price)} د.ع', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderTicketPage(
                                title: title,
                                detail: detail,
                                price: price,
                                commission: commission,
                                productId: productId,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('اطلب الآن وأنشئ الكود'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await CustomerCartStore.add(
                              CartItem(
                                id: '$productId-${oldBattery ? 'old' : 'no-old'}',
                                productId: productId,
                                title: title,
                                detail: detail,
                                price: price,
                                commission: commission,
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تمت إضافة البطارية إلى السلة')),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('أضف إلى السلة'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
