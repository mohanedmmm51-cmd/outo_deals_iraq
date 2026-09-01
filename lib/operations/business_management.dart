part of '../operations_features.dart';

class PricingManagementPage extends StatefulWidget {
  const PricingManagementPage({super.key});
  @override
  State<PricingManagementPage> createState() => _PricingManagementPageState();
}

class _PricingManagementPageState extends State<PricingManagementPage> {
  final category = TextEditingController();
  final keyName = TextEditingController();
  final value = TextEditingController();

  Future<void> _save() async {
    final c = category.text.trim();
    final k = keyName.text.trim();
    final v = int.tryParse(value.text.trim());
    if (c.isEmpty || k.isEmpty || v == null) return;
    final id = '${c}_$k'.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    await FirebaseFirestore.instance.collection('price_rules').doc(id).set({
      'category': c,
      'key': k,
      'value': v,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditLogService.record(
      action: 'price_rule_update',
      targetType: 'price_rule',
      targetId: id,
      details: '$c/$k=$v',
    );
    category.clear();
    keyName.clear();
    value.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إدارة الأسعار')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('price_rules').snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(controller: category, decoration: const InputDecoration(labelText: 'الفئة: tires / batteries', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: keyName, decoration: const InputDecoration(labelText: 'اسم القاعدة أو القياس', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: value, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القيمة بالدينار', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _save, child: const Text('حفظ القاعدة')),
                  const SizedBox(height: 12),
                  ...docs.map((d) {
                    final x = d.data();
                    return Card(
                      child: ListTile(
                        title: Text('${x['category']} • ${x['key']}'),
                        subtitle: Text('${opMoney((x['value'] as num?)?.toInt() ?? 0)} د.ع'),
                        trailing: IconButton(onPressed: () => d.reference.delete(), icon: const Icon(Icons.delete_outline)),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      );
}

class InventoryManagementPage extends StatefulWidget {
  const InventoryManagementPage({super.key});
  @override
  State<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  final name = TextEditingController();
  final qty = TextEditingController();

  Future<void> _add(ShopProfile shop) async {
    final n = name.text.trim();
    final q = int.tryParse(qty.text.trim());
    if (n.isEmpty || q == null) return;
    await FirebaseFirestore.instance.collection('shops').doc(shop.id).collection('inventory').add({
      'name': n,
      'quantity': q,
      'available': q > 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    name.clear();
    qty.clear();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ShopProfile?>(
        future: ShopStore.load(),
        builder: (context, shopSnap) {
          final shop = shopSnap.data;
          if (shop == null) return const Scaffold(body: Center(child: Text('سجل دخول المحل أولاً')));
          return Scaffold(
            appBar: AppBar(title: const Text('مخزون المحل')),
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('shops').doc(shop.id).collection('inventory').snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(controller: name, decoration: const InputDecoration(labelText: 'المنتج/القياس', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: () => _add(shop), child: const Text('إضافة للمخزون')),
                      const SizedBox(height: 12),
                      ...docs.map((d) {
                        final x = d.data();
                        final q = (x['quantity'] as num?)?.toInt() ?? 0;
                        return Card(
                          child: ListTile(
                            title: Text('${x['name'] ?? ''}'),
                            subtitle: Text(q > 0 ? 'متوفر • الكمية $q' : 'غير متوفر'),
                            trailing: Switch(
                              value: x['available'] == true,
                              onChanged: (v) => d.reference.set({'available': v}, SetOptions(merge: true)),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
}

class BranchManagementPage extends StatefulWidget {
  const BranchManagementPage({super.key});
  @override
  State<BranchManagementPage> createState() => _BranchManagementPageState();
}

class _BranchManagementPageState extends State<BranchManagementPage> {
  final name = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();

  Future<void> _add(ShopProfile shop) async {
    if (name.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('shops').doc(shop.id).collection('branches').add({
      'name': name.text.trim(),
      'address': address.text.trim(),
      'phone': phone.text.trim(),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    name.clear();
    address.clear();
    phone.clear();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ShopProfile?>(
        future: ShopStore.load(),
        builder: (context, shopSnap) {
          final shop = shopSnap.data;
          if (shop == null) return const Scaffold(body: Center(child: Text('سجل دخول المحل أولاً')));
          return Scaffold(
            appBar: AppBar(title: const Text('فروع المحل')),
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('shops').doc(shop.id).collection('branches').snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الفرع', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: address, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: () => _add(shop), child: const Text('إضافة فرع')),
                      const SizedBox(height: 12),
                      ...docs.map((d) {
                        final x = d.data();
                        return Card(
                          child: ListTile(
                            title: Text('${x['name'] ?? ''}'),
                            subtitle: Text('${x['address'] ?? ''}\n${x['phone'] ?? ''}'),
                            isThreeLine: true,
                            trailing: Switch(
                              value: x['active'] != false,
                              onChanged: (v) => d.reference.set({'active': v}, SetOptions(merge: true)),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
}
