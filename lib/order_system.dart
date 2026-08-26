import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'marketplace_features.dart';
import 'shop_dashboard.dart';
import 'shop_store.dart';

const _ordersKey = 'auto_deals_orders_v1';
const _ordersCollection = 'orders';
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
  final String shopId;
  final String shopName;

  const AppOrder({
    required this.code,
    required this.title,
    required this.detail,
    required this.price,
    required this.commission,
    required this.createdAt,
    this.completed = false,
    this.completedAt,
    this.shopId = '',
    this.shopName = '',
  });

  AppOrder copyWith({
    bool? completed,
    DateTime? completedAt,
    String? shopId,
    String? shopName,
  }) => AppOrder(
        code: code,
        title: title,
        detail: detail,
        price: price,
        commission: commission,
        createdAt: createdAt,
        completed: completed ?? this.completed,
        completedAt: completedAt ?? this.completedAt,
        shopId: shopId ?? this.shopId,
        shopName: shopName ?? this.shopName,
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
        'shopId': shopId,
        'shopName': shopName,
      };

  Map<String, dynamic> toFirestore() => {
        'code': code,
        'title': title,
        'detail': detail,
        'price': price,
        'commission': commission,
        'createdAt': Timestamp.fromDate(createdAt),
        'completed': completed,
        'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
        'shopId': shopId,
        'shopName': shopName,
        'settlementId': '',
        'settlementStatus': '',
      };

  factory AppOrder.fromJson(Map<String, dynamic> json) => AppOrder(
        code: '${json['code'] ?? ''}',
        title: '${json['title'] ?? ''}',
        detail: '${json['detail'] ?? ''}',
        price: (json['price'] as num?)?.toInt() ?? 0,
        commission: (json['commission'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
        completed: json['completed'] == true,
        completedAt: json['completedAt'] == null ? null : DateTime.tryParse('${json['completedAt']}'),
        shopId: '${json['shopId'] ?? ''}',
        shopName: '${json['shopName'] ?? ''}',
      );

  factory AppOrder.fromFirestore(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value');
    }

    return AppOrder(
      code: '${json['code'] ?? ''}',
      title: '${json['title'] ?? ''}',
      detail: '${json['detail'] ?? ''}',
      price: (json['price'] as num?)?.toInt() ?? 0,
      commission: (json['commission'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['createdAt']),
      completed: json['completed'] == true,
      completedAt: parseNullableDate(json['completedAt']),
      shopId: '${json['shopId'] ?? ''}',
      shopName: '${json['shopName'] ?? ''}',
    );
  }
}

class OrderStore {
  static CollectionReference<Map<String, dynamic>> get _remote => FirebaseFirestore.instance.collection(_ordersCollection);

  static Future<List<AppOrder>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      final orders = data.whereType<Map>().map((e) => AppOrder.fromJson(Map<String, dynamic>.from(e))).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveLocal(List<AppOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ordersKey, jsonEncode(orders.map((e) => e.toJson()).toList()));
  }

  static Future<List<AppOrder>> load() async {
    try {
      final snap = await _remote.orderBy('createdAt', descending: true).limit(100).get();
      final remoteOrders = snap.docs.map((d) => AppOrder.fromFirestore(d.data())).where((e) => e.code.isNotEmpty).toList();
      if (remoteOrders.isNotEmpty) {
        await _saveLocal(remoteOrders);
        return remoteOrders;
      }
    } catch (_) {}
    return _loadLocal();
  }

  static Future<AppOrder> create({
    required String title,
    required String detail,
    required int price,
    required int commission,
    required String shopId,
    required String shopName,
  }) async {
    final order = AppOrder(
      code: createOrderCode(),
      title: title,
      detail: detail,
      price: price,
      commission: commission,
      createdAt: DateTime.now(),
      shopId: shopId,
      shopName: shopName,
    );
    final local = await _loadLocal();
    local.removeWhere((e) => e.code == order.code);
    local.insert(0, order);
    await _saveLocal(local);
    await _remote.doc(order.code).set(order.toFirestore());
    await FirebaseFirestore.instance.collection('notifications').add({
      'targetShopId': shopId,
      'title': 'طلب جديد',
      'body': '$title • ${_money(price)} د.ع',
      'orderCode': order.code,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return order;
  }

  static Future<AppOrder?> findByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    try {
      final doc = await _remote.doc(normalized).get();
      if (doc.exists && doc.data() != null) {
        final order = AppOrder.fromFirestore(doc.data()!);
        await _upsertLocal(order);
        return order;
      }
    } catch (_) {}
    final orders = await _loadLocal();
    for (final order in orders) {
      if (order.code.toUpperCase() == normalized) return order;
    }
    return null;
  }

  static Future<AppOrder?> confirm(String code, {required String shopId, required String shopName}) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    try {
      final docRef = _remote.doc(normalized);
      final result = await FirebaseFirestore.instance.runTransaction<AppOrder?>((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists || snap.data() == null) return null;
        final current = AppOrder.fromFirestore(snap.data()!);
        if (current.shopId.isNotEmpty && current.shopId != shopId) {
          throw StateError('هذا الطلب مخصص لمحل آخر');
        }
        if (current.completed) return current;
        final completedAt = DateTime.now();
        tx.update(docRef, {
          'completed': true,
          'completedAt': Timestamp.fromDate(completedAt),
          'shopId': shopId,
          'shopName': shopName,
          'settlementId': '',
          'settlementStatus': '',
        });
        return current.copyWith(completed: true, completedAt: completedAt, shopId: shopId, shopName: shopName);
      });
      if (result != null) {
        await _upsertLocal(result);
        return result;
      }
    } on StateError {
      rethrow;
    } catch (_) {}
    final orders = await _loadLocal();
    final index = orders.indexWhere((e) => e.code.toUpperCase() == normalized);
    if (index < 0) return null;
    final current = orders[index];
    if (current.shopId.isNotEmpty && current.shopId != shopId) throw StateError('هذا الطلب مخصص لمحل آخر');
    if (!current.completed) {
      orders[index] = current.copyWith(completed: true, completedAt: DateTime.now(), shopId: shopId, shopName: shopName);
      await _saveLocal(orders);
    }
    return orders[index];
  }

  static Future<void> _upsertLocal(AppOrder order) async {
    final orders = await _loadLocal();
    final index = orders.indexWhere((e) => e.code == order.code);
    if (index >= 0) orders[index] = order; else orders.insert(0, order);
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveLocal(orders);
  }
}

class OrderTicketPage extends StatefulWidget {
  final String title;
  final String detail;
  final int price;
  final int commission;

  const OrderTicketPage({super.key, required this.title, required this.detail, required this.price, required this.commission});

  @override
  State<OrderTicketPage> createState() => _OrderTicketPageState();
}

class _OrderTicketPageState extends State<OrderTicketPage> {
  AppOrder? order;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? shops;
  String? selectedShopId;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('shops').where('approved', isEqualTo: true).get();
      if (mounted) setState(() => shops = snap.docs);
    } catch (e) {
      if (mounted) setState(() { shops = []; error = e.toString(); });
    }
  }

  Future<void> _create() async {
    if (selectedShopId == null) return;
    final shop = shops!.firstWhere((d) => d.id == selectedShopId);
    setState(() { busy = true; error = null; });
    try {
      final created = await OrderStore.create(
        title: widget.title,
        detail: widget.detail,
        price: widget.price,
        commission: widget.commission,
        shopId: shop.id,
        shopName: '${shop.data()['name'] ?? ''}',
      );
      if (mounted) setState(() => order = created);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(order == null ? 'اختيار المحل' : 'كود الطلب')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: order == null ? _buildShopChooser() : _buildTicket(),
      ),
    );
  }

  Widget _buildShopChooser() {
    if (shops == null) return const Center(child: CircularProgressIndicator());
    if (shops!.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error ?? 'ماكو محلات معتمدة حالياً. لازم الإدارة توافق على محل أولاً.', textAlign: TextAlign.center)));
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(color: orderYellow, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), Text('السعر النهائي: ${_money(widget.price)} د.ع')]))),
        const SizedBox(height: 14),
        const Text('اختار المحل اللي تريد يوصله الطلب', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...shops!.map((d) {
          final data = d.data();
          return RadioListTile<String>(
            value: d.id,
            groupValue: selectedShopId,
            title: Text('${data['name'] ?? ''}'),
            subtitle: Text('${data['phone'] ?? ''}'),
            onChanged: (v) => setState(() => selectedShopId = v),
          );
        }),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: busy || selectedShopId == null ? null : _create, icon: const Icon(Icons.qr_code_2), label: Text(busy ? 'جاري إنشاء الطلب...' : 'تأكيد المحل وإنشاء الكود')),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _buildTicket() => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(color: orderYellow, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order!.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(order!.detail),
            const SizedBox(height: 6),
            Text('المحل: ${order!.shopName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('السعر النهائي: ${_money(order!.price)} د.ع', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ]))),
          const SizedBox(height: 18),
          const Text('كود الزيارة/الشراء', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SelectableText(order!.code, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Center(child: BarcodeWidget(barcode: Barcode.qrCode(), data: order!.code, width: 200, height: 200)),
          const SizedBox(height: 20),
          Center(child: BarcodeWidget(barcode: Barcode.code128(), data: order!.code, width: 290, height: 90, drawText: true)),
          const SizedBox(height: 18),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('هذا الطلب مربوط بالمحل المختار فقط. سلّم الكود للمحل قبل بدء العمل.', textAlign: TextAlign.center))),
        ],
      );
}

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});
  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<AppOrder>? orders;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final data = await OrderStore.load(); if (mounted) setState(() => orders = data); }

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
                        return Card(child: ListTile(
                          leading: CircleAvatar(backgroundColor: o.completed ? Colors.green : orderYellow, child: Icon(o.completed ? Icons.check : Icons.receipt_long, color: Colors.black)),
                          title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${o.code}\n${o.shopName.isEmpty ? '' : '${o.shopName} • '}${_money(o.price)} د.ع • ${o.completed ? 'تم التنفيذ' : 'بانتظار المحل'}'),
                          isThreeLine: true,
                          trailing: o.completed && o.shopId.isNotEmpty ? IconButton(icon: const Icon(Icons.star_rate), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RatingPage(orderCode: o.code, shopId: o.shopId, shopName: o.shopName)))) : null,
                        ));
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
  ShopProfile? shop;
  String? message;
  bool busy = false;

  @override
  void initState() { super.initState(); _loadShop(); }
  Future<void> _loadShop() async { final value = await ShopStore.load(); if (mounted) setState(() => shop = value); }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() { busy = true; message = null; found = null; });
    final result = await OrderStore.findByCode(controller.text);
    if (!mounted) return;
    setState(() { busy = false; found = result; if (result == null) message = 'الكود غير موجود'; });
  }

  Future<void> _confirm() async {
    if (found == null) return;
    final currentShop = await ShopStore.load();
    if (currentShop == null) { if (mounted) setState(() => message = 'سجل دخول المحل أولاً'); return; }
    if (found!.shopId.isNotEmpty && found!.shopId != currentShop.id) { setState(() => message = 'هذا الطلب مخصص لمحل آخر'); return; }
    setState(() => busy = true);
    try {
      final result = await OrderStore.confirm(found!.code, shopId: currentShop.id, shopName: currentShop.name);
      if (!mounted) return;
      setState(() { found = result; shop = currentShop; message = result == null ? 'تعذر تأكيد الطلب' : 'تم تأكيد تنفيذ الطلب وتسجيل العمولة'; });
    } catch (e) {
      if (mounted) setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد طلب الزبون'), actions: [IconButton(tooltip: 'حساب المحل والعمولات', onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopDashboardPage())); _loadShop(); }, icon: const Icon(Icons.account_balance_wallet))]),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(color: shop == null ? Colors.orange.shade100 : Colors.green.shade100, child: ListTile(
              leading: Icon(shop == null ? Icons.warning_amber : Icons.store),
              title: Text(shop == null ? 'ماكو حساب محل على هذا الجهاز' : shop!.name),
              subtitle: Text(shop == null ? 'سجل دخول المحل قبل تأكيد الطلبات.' : 'رقم المحل: ${shop!.id}'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopDashboardPage())); _loadShop(); },
            )),
            const SizedBox(height: 14),
            const Text('أدخل كود الزبون قبل تنفيذ الخدمة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'مثال: ADI-12345678', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)), onSubmitted: (_) => _search()),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: busy ? null : _search, icon: const Icon(Icons.search), label: const Text('فحص الكود')),
            if (busy) ...[const SizedBox(height: 18), const Center(child: CircularProgressIndicator())],
            if (message != null) ...[const SizedBox(height: 14), Text(message!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))],
            if (found != null) ...[
              const SizedBox(height: 18),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(found!.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(found!.detail),
                const SizedBox(height: 6),
                Text('المحل المطلوب: ${found!.shopName.isEmpty ? 'غير محدد' : found!.shopName}'),
                Text('السعر للزبون: ${_money(found!.price)} د.ع'),
                Text('عمولة التطبيق: ${_money(found!.commission)} د.ع'),
                const SizedBox(height: 12),
                if (found!.completed)
                  const Chip(avatar: Icon(Icons.check_circle), label: Text('تم تنفيذ هذا الطلب'))
                else
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : _confirm, icon: const Icon(Icons.check_circle), label: const Text('تأكيد تم تنفيذ الطلب'))),
              ]))),
            ],
          ],
        ),
      ),
    );
  }
}
