import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'order_system.dart';

const _cartKey = 'auto_deals_customer_cart_v1';
const _cartYellow = Color(0xFFFFD400);

String _money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

class CartItem {
  final String id;
  final String title;
  final String detail;
  final int price;
  final int commission;

  const CartItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.price,
    required this.commission,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'price': price,
        'commission': commission,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        detail: '${json['detail'] ?? ''}',
        price: (json['price'] as num?)?.toInt() ?? 0,
        commission: (json['commission'] as num?)?.toInt() ?? 0,
      );
}

class CustomerCartStore {
  static Future<List<CartItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(CartItem item) async {
    final items = await load();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await _save(items);
  }

  static Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((e) => e.id == id);
    await _save(items);
  }

  static Future<void> clear() => _save(const []);

  static Future<void> _save(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cartKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({super.key});

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  List<CartItem>? items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await CustomerCartStore.load();
    if (mounted) setState(() => items = data);
  }

  Future<void> _remove(CartItem item) async {
    await CustomerCartStore.remove(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final current = items;
    final total = current?.fold<int>(0, (sum, e) => sum + e.price) ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('السلة'),
        actions: [
          if (current != null && current.isNotEmpty)
            IconButton(
              tooltip: 'تفريغ السلة',
              onPressed: () async {
                await CustomerCartStore.clear();
                await _load();
              },
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: current == null
            ? const Center(child: CircularProgressIndicator())
            : current.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'السلة فارغة. أضف إطار أو بطارية من صفحة التفاصيل.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: _cartYellow,
                        child: ListTile(
                          leading: const Icon(Icons.shopping_cart_checkout),
                          title: const Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text(
                            '${_money(total)} د.ع',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...current.map(
                        (item) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${item.detail}\n${_money(item.price)} د.ع'),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    onPressed: () => _remove(item),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderTicketPage(
                                        title: item.title,
                                        detail: item.detail,
                                        price: item.price,
                                        commission: item.commission,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.qr_code_2),
                                  label: const Text('اختار محل وأنشئ كود الطلب'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
