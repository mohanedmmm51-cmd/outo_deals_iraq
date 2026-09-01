import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'order_system.dart';
import 'shop_qr_confirm_page.dart';
import 'shop_store.dart';
import 'size_request_page.dart';

const shopYellow = Color(0xFFFFD400);

String _money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

DateTime _weekStart(DateTime value) {
  final d = DateTime(value.year, value.month, value.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

String _weekKey(DateTime start) =>
    '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';

class ShopDashboardPage extends StatefulWidget {
  const ShopDashboardPage({super.key});

  @override
  State<ShopDashboardPage> createState() => _ShopDashboardPageState();
}

class _ShopDashboardPageState extends State<ShopDashboardPage> {
  ShopProfile? profile;
  bool loading = true;
  String? error;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final value = await ShopStore.loadForAuthenticatedOwner();
      if (!mounted) return;
      setState(() {
        profile = value;
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

  Future<void> _saveProfile() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسم المحل ورقم الهاتف')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final value = await ShopStore.save(name: name, phone: phone);
      if (!mounted) return;
      setState(() {
        profile = value;
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

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (profile == null) return _buildCreateAccount();
    return _buildDashboard(profile!);
  }

  Widget _buildCreateAccount() {
    return Scaffold(
      appBar: AppBar(title: const Text('حساب صاحب المحل')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Card(
              color: shopYellow,
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    Icon(Icons.storefront, size: 64),
                    SizedBox(height: 8),
                    Text(
                      'إنشاء حساب المحل',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'هذا الحساب يربط الطلبات بالمحل ويحسب العمولة والتسوية الأسبوعية.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المحل',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_circle),
              label: const Text('إنشاء الحساب'),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(ShopProfile shop) {
    return Scaffold(
      appBar: AppBar(title: const Text('حساب المحل والعمولات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('shopId', isEqualTo: shop.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('تعذر تحميل الحساب: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            final completed = docs.where((d) => d.data()['completed'] == true).toList();
            completed.sort((a, b) =>
                _asDate(b.data()['completedAt']).compareTo(_asDate(a.data()['completedAt'])));

            final start = _weekStart(DateTime.now());
            final end = start.add(const Duration(days: 7));
            final thisWeek = completed.where((d) {
              final date = _asDate(d.data()['completedAt']);
              return !date.isBefore(start) && date.isBefore(end);
            }).toList();

            final weeklySales = thisWeek.fold<int>(
              0,
              (sum, d) => sum + ((d.data()['price'] as num?)?.toInt() ?? 0),
            );
            final weeklyCommission = thisWeek.fold<int>(
              0,
              (sum, d) => sum + ((d.data()['commission'] as num?)?.toInt() ?? 0),
            );
            final unassigned = thisWeek
                .where((d) => '${d.data()['settlementId'] ?? ''}'.isEmpty)
                .toList();
            final dueCommission = unassigned.fold<int>(
              0,
              (sum, d) => sum + ((d.data()['commission'] as num?)?.toInt() ?? 0),
            );

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _shopHeader(shop),
                  const SizedBox(height: 12),
                  if (shop.approved)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopQrConfirmPage(shop: shop),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('مسح طلب الزبون'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ShopConfirmOrderPage(),
                            ),
                          ),
                          icon: const Icon(Icons.keyboard),
                          label: const Text('إدخال كود الطلب يدوياً'),
                        ),
                      ],
                    )
                  else
                    const Card(
                      color: Color(0xffffe4a3),
                      child: ListTile(
                        leading: Icon(Icons.hourglass_top),
                        title: Text('الحساب بانتظار موافقة الإدارة'),
                        subtitle: Text(
                          'تتفعّل الطلبات ومسح الأكواد بعد اعتماد المحل.',
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _liveSizeRequestsCard(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'طلبات الأسبوع',
                          '${thisWeek.length}',
                          Icons.receipt_long,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          'مبيعات الأسبوع',
                          '${_money(weeklySales)} د.ع',
                          Icons.payments,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _statCard(
                    'العمولة المستحقة لهذا الأسبوع',
                    '${_money(dueCommission)} د.ع',
                    Icons.account_balance_wallet,
                    highlight: true,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                    onPressed: unassigned.isEmpty
                        ? null
                        : () => _createWeeklyStatement(
                              profile: shop,
                              weekStart: start,
                              orders: unassigned,
                            ),
                    icon: const Icon(Icons.summarize),
                    label: Text(
                      unassigned.isEmpty
                          ? 'كشف هذا الأسبوع مضاف للتسوية'
                          : 'إنشاء كشف التسوية الأسبوعية',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إجمالي عمولة كل طلبات هذا الأسبوع: ${_money(weeklyCommission)} د.ع',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'الطلبات المنفذة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (completed.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('ماكو طلبات منفذة مرتبطة بهذا المحل بعد.'),
                      ),
                    )
                  else
                    ...completed.map((d) => _orderCard(d.data())),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _shopHeader(ShopProfile shop) {
    return Card(
      color: const Color(0xff171717),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shop.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(shop.phone, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('رقم المحل: ${shop.id}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(
                shop.approved ? Icons.verified : Icons.schedule,
                size: 18,
              ),
              label: Text(shop.approved ? 'محل معتمد' : 'بانتظار الاعتماد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveSizeRequestsCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('size_requests')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Card(
          color: count > 0 ? shopYellow : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: count > 0 ? Colors.black : shopYellow,
              child: Icon(
                Icons.straighten,
                color: count > 0 ? shopYellow : Colors.black,
              ),
            ),
            title: const Text(
              'طلبات القياسات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              snapshot.hasError
                  ? 'تعذر تحميل طلبات القياسات'
                  : count > 0
                      ? '$count طلب مفتوح بانتظار عروض المحلات'
                      : 'ماكو طلبات قياسات مفتوحة حالياً',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: shopYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_back_ios_new, size: 16),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ShopSizeRequestsEnhancedPage(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Card(
      color: highlight ? shopYellow : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> data) {
    final settled = '${data['settlementId'] ?? ''}'.isNotEmpty;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: settled ? Colors.green : shopYellow,
          child: Icon(settled ? Icons.done_all : Icons.check, color: Colors.black),
        ),
        title: Text(
          '${data['title'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${data['code'] ?? ''}\n'
          'السعر: ${_money((data['price'] as num?)?.toInt() ?? 0)} د.ع • '
          'العمولة: ${_money((data['commission'] as num?)?.toInt() ?? 0)} د.ع\n'
          '${settled ? 'داخل كشف تسوية' : 'بانتظار كشف الأسبوع'}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _createWeeklyStatement({
    required ShopProfile profile,
    required DateTime weekStart,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
  }) async {
    final key = _weekKey(weekStart);
    final settlementId = '${profile.id}_$key';
    final db = FirebaseFirestore.instance;
    final statementRef = db.collection('settlements').doc(settlementId);

    try {
      final existing = await statementRef.get();
      final existingData = existing.data();
      final existingStatus = '${existingData?['status'] ?? ''}';
      if (existing.exists && existingStatus == 'paid') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسديد كشف هذا الأسبوع ولا يمكن إضافة طلبات جديدة له'),
          ),
        );
        return;
      }

      final oldCodes = (existingData?['orderCodes'] as List?)
              ?.map((e) => '$e')
              .toSet() ??
          <String>{};
      final newOrders = orders.where((order) => !oldCodes.contains(order.id)).toList();
      if (newOrders.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كل طلبات هذا الأسبوع مضافة للكشف بالفعل')),
        );
        return;
      }

      final newSales = newOrders.fold<int>(
        0,
        (sum, d) => sum + ((d.data()['price'] as num?)?.toInt() ?? 0),
      );
      final newCommission = newOrders.fold<int>(
        0,
        (sum, d) => sum + ((d.data()['commission'] as num?)?.toInt() ?? 0),
      );
      final mergedCodes = <String>{...oldCodes, ...newOrders.map((d) => d.id)}.toList();
      final previousSales = (existingData?['totalSales'] as num?)?.toInt() ?? 0;
      final previousCommission =
          (existingData?['totalCommission'] as num?)?.toInt() ?? 0;

      final batch = db.batch();
      batch.set(
        statementRef,
        {
          'id': settlementId,
          'shopId': profile.id,
          'shopName': profile.name,
          'weekStart': Timestamp.fromDate(weekStart),
          'weekEnd': Timestamp.fromDate(weekStart.add(const Duration(days: 7))),
          'totalSales': previousSales + newSales,
          'totalCommission': previousCommission + newCommission,
          'orderCount': mergedCodes.length,
          'orderCodes': mergedCodes,
          'status': 'pending',
          if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'paidAt': null,
        },
        SetOptions(merge: true),
      );

      for (final order in newOrders) {
        batch.update(order.reference, {
          'settlementId': settlementId,
          'settlementStatus': 'pending',
        });
      }

      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing.exists
                ? 'تم تحديث كشف الأسبوع وإضافة ${newOrders.length} طلب • ${_money(newCommission)} د.ع عمولة جديدة'
                : 'تم إنشاء كشف الأسبوع: ${_money(newCommission)} د.ع عمولة مستحقة',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء كشف التسوية: $e')),
      );
    }
  }

  DateTime _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse('$value') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
