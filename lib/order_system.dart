import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ordersKey = 'auto_deals_orders_v1';
const orderYellow = Color(0xFFFFD400);

String _money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

String createOrderCode() {
  final stamp = DateTime.now().millisecondsSinceEpoch.toString();
  return 'ADI-${stamp.substring(stamp.length - 8)}';
}

class AppOrder {
  final String code;
  final String title;
  final String detail;
  final int price;
  final int commission;
  final DateTime createdAt;
  final bool completed;
  final DateTime? completedAt;

  const AppOrder({
    required this.code,
    required this.title,
    required this.detail,
    required this.price,
    required this.commission,
    required this.createdAt,
    this.completed = false,
    this.completedAt,
  });

  AppOrder copyWith({bool? completed, DateTime? completedAt}) => AppOrder(
        code: code,
        title: title,
        detail: detail,
        price: price,
        commission: commission,
        createdAt: createdAt,
        completed: completed ?? this.completed,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'detail': detail,
        'price': price,
        'commission': commission,
        'createdAt': createdAt.toIso8601String(),
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory AppOrder.fromJson(Map<String, dynamic> json) => AppOrder(
        code: '${json['code'] ?? ''}',
        title: '${json['title'] ?? ''}',
        detail: '${json['detail'] ?? ''}',
        price: (json['price'] as num?)?.toInt() ?? 0,
        commission: (json['commission'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
        completed: json['completed'] == true,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.tryParse('${json['completedAt']}'),
      );
}

class OrderStore {
  static Future<List<AppOrder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      final orders = data
          .whereType<Map>()
          .map((e) => AppOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<AppOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersKey,
      jsonEncode(orders.map((e) => e.toJson()).toList()),
    );
  }

  static Future<AppOrder> create({
    required String title,
    required String detail,
    required int price,
    required int commission,
  }) async {
    final order = AppOrder(
      code: createOrderCode(),
      title: title,
      detail: detail,
      price: price,
      commission: commission,
      createdAt: DateTime.now(),
    );
    final orders = await load();
    orders.insert(0, order);
    await _save(orders);
    return order;
  }

  static Future<AppOrder?> findByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final orders = await load();
    for (final order in orders) {
      if (order.code.toUpperCase() == normalized) return order;
    }
    return null;
  }

  static Future<AppOrder?> confirm(String code) async {
    final normalized = code.trim().toUpperCase();
    final orders = await load();
    final index = orders.indexWhere((e) => e.code.toUpperCase() == normalized);
    if (index < 0) return null;

    final current = orders[index];
    if (!current.completed) {
      orders[index] = current.copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
      await _save(orders);
    }
    return orders[index];
  }
}

class OrderTicketPage extends StatefulWidget {
  final String title;
  final String detail;
  final int price;
  final int commission;

  const OrderTicketPage({
    super.key,
    required this.title,
    required this.detail,
    required this.price,
    required this.commission,
  });

  @override
  State<OrderTicketPage> createState() => _OrderTicketPageState();
}

class _OrderTicketPageState extends State<OrderTicketPage> {
  AppOrder? order;
  String? error;

  @override
  void initState() {
    super.initState();
    _create();
  }

  Future<void> _create() async {
    try {
      final created = await OrderStore.create(
        title: widget.title,
        detail: widget.detail,
        price: widget.price,
        commission: widget.commission,
      );
      if (!mounted) return;
      setState(() => order = created);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كود الطلب')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: order == null
            ? Center(
                child: error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('تعذر إنشاء الطلب: $error'),
                      ),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Card(
                    color: orderYellow,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order!.title,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(order!.detail),
                          const SizedBox(height: 8),
                          Text('السعر النهائي: ${_money(order!.price)} د.ع',
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('كود الزيارة/الشراء',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SelectableText(order!.code,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Center(
                    child: BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: order!.code,
                      width: 200,
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: order!.code,
                      width: 290,
                      height: 90,
                      drawText: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'سلّم الكود لصاحب المحل قبل بدء العمل. بعد تأكيده يتحول الطلب إلى منفّذ وتُحتسب عمولة التطبيق.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<AppOrder>? orders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await OrderStore.load();
    if (mounted) setState(() => orders = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: orders == null
            ? const Center(child: CircularProgressIndicator())
            : orders!.isEmpty
                ? const Center(child: Text('ما عندك طلبات لحد الآن'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: orders!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final o = orders![index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  o.completed ? Colors.green : orderYellow,
                              child: Icon(
                                o.completed ? Icons.check : Icons.receipt_long,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(o.title,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${o.code}\n${_money(o.price)} د.ع • ${o.completed ? 'تم التنفيذ' : 'بانتظار المحل'}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class ShopConfirmOrderPage extends StatefulWidget {
  const ShopConfirmOrderPage({super.key});

  @override
  State<ShopConfirmOrderPage> createState() => _ShopConfirmOrderPageState();
}

class _ShopConfirmOrderPageState extends State<ShopConfirmOrderPage> {
  final controller = TextEditingController();
  AppOrder? found;
  String? message;
  bool busy = false;

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      message = null;
      found = null;
    });
    final result = await OrderStore.findByCode(controller.text);
    if (!mounted) return;
    setState(() {
      busy = false;
      found = result;
      if (result == null) message = 'الكود غير موجود';
    });
  }

  Future<void> _confirm() async {
    if (found == null) return;
    setState(() => busy = true);
    final result = await OrderStore.confirm(found!.code);
    if (!mounted) return;
    setState(() {
      busy = false;
      found = result;
      message = result == null ? 'تعذر تأكيد الطلب' : 'تم تأكيد تنفيذ الطلب بنجاح';
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد طلب الزبون')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'أدخل كود الزبون قبل تنفيذ الخدمة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'مثال: ADI-12345678',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: busy ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('فحص الكود'),
            ),
            if (busy) ...[
              const SizedBox(height: 18),
              const Center(child: CircularProgressIndicator()),
            ],
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            if (found != null) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(found!.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(found!.detail),
                      const SizedBox(height: 6),
                      Text('السعر للزبون: ${_money(found!.price)} د.ع'),
                      Text('عمولة التطبيق: ${_money(found!.commission)} د.ع'),
                      const SizedBox(height: 12),
                      if (found!.completed)
                        const Chip(
                          avatar: Icon(Icons.check_circle),
                          label: Text('تم تنفيذ هذا الطلب'),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ? null : _confirm,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('تأكيد تم تنفيذ الطلب'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
