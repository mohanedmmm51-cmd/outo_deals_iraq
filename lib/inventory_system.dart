import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'legacy_main.dart' as legacy;
import 'shop_store.dart';

const inventoryYellow = Color(0xFFFFD400);

String inventoryDocId(String productId) =>
    base64Url.encode(utf8.encode(productId)).replaceAll('=', '');

class InventoryProduct {
  final String id;
  final String title;
  final String category;

  const InventoryProduct({
    required this.id,
    required this.title,
    required this.category,
  });
}

class InventoryService {
  static DocumentReference<Map<String, dynamic>> itemRef(
    String shopId,
    String productId,
  ) =>
      FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('inventory')
          .doc(inventoryDocId(productId));

  static Future<bool> shopHasProduct({
    required QueryDocumentSnapshot<Map<String, dynamic>> shop,
    required String productId,
  }) async {
    final shopData = shop.data();
    if (shopData['inventoryEnabled'] != true || productId.trim().isEmpty) {
      return true;
    }
    final item = await itemRef(shop.id, productId).get();
    final data = item.data();
    final quantity = (data?['quantity'] as num?)?.toInt() ?? 0;
    return data?['available'] == true && quantity > 0;
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      eligibleShops(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> shops,
    String productId,
  ) async {
    final result = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final shop in shops) {
      if (shop.data()['status'] == 'suspended') continue;
      if (await shopHasProduct(shop: shop, productId: productId)) {
        result.add(shop);
      }
    }
    return result;
  }

  static Future<void> setQuantity({
    required ShopProfile shop,
    required InventoryProduct product,
    required int quantity,
  }) async {
    final cleanQuantity = quantity < 0 ? 0 : quantity;
    final db = FirebaseFirestore.instance;
    final ref = itemRef(shop.id, product.id);
    await ref.set({
      'productId': product.id,
      'title': product.title,
      'category': product.category,
      'quantity': cleanQuantity,
      'available': cleanQuantity > 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final inventory = await db
        .collection('shops')
        .doc(shop.id)
        .collection('inventory')
        .get();
    final availableCount = inventory.docs.where((doc) {
      final data = doc.data();
      return data['available'] == true &&
          ((data['quantity'] as num?)?.toInt() ?? 0) > 0;
    }).length;

    await db.collection('shops').doc(shop.id).set({
      'inventoryEnabled': true,
      'availableCount': availableCount,
      'inventoryUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static List<InventoryProduct> catalog() {
    final result = <InventoryProduct>[
      ...legacy.tires.map(
        (tire) => InventoryProduct(
          id: 'tire-${tire.size}',
          title: 'إطار ${tire.size}',
          category: 'tire',
        ),
      ),
      ...legacy.batteries.map(
        (battery) => InventoryProduct(
          id: 'battery-${battery.brand}-${battery.amp}',
          title: '${battery.brand} ${battery.amp}',
          category: 'battery',
        ),
      ),
    ];
    final seen = <String>{};
    return result.where((item) => seen.add(item.id)).toList();
  }
}

class ShopInventoryPage extends StatefulWidget {
  const ShopInventoryPage({super.key});

  @override
  State<ShopInventoryPage> createState() => _ShopInventoryPageState();
}

class _ShopInventoryPageState extends State<ShopInventoryPage> {
  ShopProfile? shop;
  bool loading = true;
  String? error;
  String filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await ShopStore.load();
      if (!mounted) return;
      setState(() {
        shop = value;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _editQuantity(
    InventoryProduct product,
    int currentQuantity,
  ) async {
    final controller = TextEditingController(text: '$currentQuantity');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(product.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الكمية المتوفرة',
            helperText: 'اكتب 0 إذا المنتج نافد',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text.trim());
              if (quantity == null || quantity < 0) return;
              Navigator.pop(dialogContext, quantity);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || shop == null) return;

    try {
      await InventoryService.setQuantity(
        shop: shop!,
        product: product,
        quantity: value,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value > 0
                  ? 'تم تحديث المخزون: $value متوفر'
                  : 'تم تعليم المنتج كنافد',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث المخزون: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (shop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('مخزون المحل')),
        body: Center(child: Text(error ?? 'سجل دخول المحل أولاً')),
      );
    }

    final catalog = InventoryService.catalog();
    return Scaffold(
      appBar: AppBar(title: const Text('مخزون المحل')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (value) => setState(() => filter = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن قياس أو بطارية',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Card(
                color: inventoryYellow,
                child: ListTile(
                  leading: Icon(Icons.inventory_2_outlined),
                  title: Text(
                    'المخزون يتحكم بالطلبات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'بعد تفعيل المخزون، المنتج النافد ما يظهر كمتوفر لهذا المحل، وعند تنفيذ الطلب تنقص الكمية تلقائياً.',
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('shops')
                    .doc(shop!.id)
                    .collection('inventory')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final quantities = <String, int>{};
                  for (final doc in snap.data!.docs) {
                    final data = doc.data();
                    quantities['${data['productId'] ?? ''}'] =
                        (data['quantity'] as num?)?.toInt() ?? 0;
                  }
                  final q = filter.toLowerCase();
                  final shown = catalog
                      .where((p) => q.isEmpty || p.title.toLowerCase().contains(q))
                      .toList();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final product = shown[index];
                      final quantity = quantities[product.id] ?? 0;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                quantity > 0 ? inventoryYellow : Colors.grey.shade300,
                            child: Icon(
                              product.category == 'tire'
                                  ? Icons.tire_repair
                                  : Icons.battery_charging_full,
                              color: Colors.black,
                            ),
                          ),
                          title: Text(
                            product.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            quantity > 0 ? 'المتوفر: $quantity' : 'نافد / غير محدد',
                          ),
                          trailing: FilledButton(
                            onPressed: () => _editQuantity(product, quantity),
                            child: const Text('تعديل'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
