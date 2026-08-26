import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'operations_features.dart';

const adminYellow = Color(0xFFFFD400);

String _money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

class AdminAccessPage extends StatefulWidget {
  const AdminAccessPage({super.key});

  @override
  State<AdminAccessPage> createState() => _AdminAccessPageState();
}

class _AdminAccessPageState extends State<AdminAccessPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool allowed = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _checkCurrent();
  }

  Future<void> _checkCurrent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted && doc.data()?['role'] == 'admin') setState(() => allowed = true);
  }

  Future<void> _login() async {
    setState(() { busy = true; error = null; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
      final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (doc.data()?['role'] != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw Exception('هذا الحساب مو مخول للإدارة');
      }
      await AuditLogService.record(action: 'admin_login', targetType: 'admin', targetId: cred.user!.uid);
      if (mounted) setState(() => allowed = true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (allowed) return const _AdminDashboard();
    return Scaffold(
      appBar: AppBar(title: const Text('دخول الإدارة')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: busy ? null : _login, icon: const Icon(Icons.admin_panel_settings), label: const Text('دخول الإدارة')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, textAlign: TextAlign.center)),
        ]),
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة'),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'الملخص'),
            Tab(text: 'المحلات'),
            Tab(text: 'العروض'),
            Tab(text: 'التسويات'),
          ]),
          actions: [IconButton(onPressed: () async { await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.logout))],
        ),
        body: const TabBarView(children: [_SummaryTab(), _ShopsTab(), _OffersTab(), _SettlementsTab()]),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  void _open(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, ordersSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('shops').snapshots(),
          builder: (context, shopsSnap) {
            final orders = ordersSnap.data?.docs ?? [];
            final shops = shopsSnap.data?.docs ?? [];
            final completed = orders.where((d) => d.data()['completed'] == true || d.data()['status'] == 'completed').length;
            final sales = orders.where((d) => d.data()['completed'] == true || d.data()['status'] == 'completed').fold<int>(0, (value, d) => value + ((d.data()['price'] as num?)?.toInt() ?? 0));
            final commissions = orders.where((d) => d.data()['completed'] == true || d.data()['status'] == 'completed').fold<int>(0, (value, d) => value + ((d.data()['commission'] as num?)?.toInt() ?? 0));
            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [Expanded(child: _stat('الطلبات', '${orders.length}', Icons.receipt_long)), const SizedBox(width: 8), Expanded(child: _stat('المنفذة', '$completed', Icons.check_circle))]),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: _stat('المحلات', '${shops.length}', Icons.store)), const SizedBox(width: 8), Expanded(child: _stat('المبيعات', '${_money(sales)} د.ع', Icons.payments))]),
              const SizedBox(height: 8),
              _stat('إجمالي العمولات المسجلة', '${_money(commissions)} د.ع', Icons.account_balance_wallet),
              const SizedBox(height: 18),
              _nav(context, 'البحث + الفلاتر + CSV/PDF', Icons.manage_search, const OrdersManagementPage()),
              _nav(context, 'الإحصائيات الشهرية والأكثر طلباً', Icons.analytics, const AnalyticsPage()),
              _nav(context, 'إدارة الأسعار من السيرفر', Icons.price_change, const PricingManagementPage()),
              _nav(context, 'مخاطر المحلات والشكاوى', Icons.warning_amber, const ShopRiskPage()),
              _nav(context, 'سجل النشاط الإداري', Icons.history, const AuditLogPage()),
            ]);
          },
        );
      },
    );
  }

  Widget _stat(String t, String v, IconData i) => Card(color: adminYellow, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Icon(i, size: 34), Text(t), Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))])));
  Widget _nav(BuildContext context, String title, IconData icon, Widget page) => Card(child: ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: const Icon(Icons.arrow_back_ios_new, size: 16), onTap: () => _open(context, page)));
}

class _ShopsTab extends StatelessWidget {
  const _ShopsTab();

  Future<void> _setState(DocumentSnapshot<Map<String, dynamic>> d, bool approved) async {
    await d.reference.set({'approved': approved, 'status': approved ? 'approved' : 'suspended'}, SetOptions(merge: true));
    await AuditLogService.record(action: approved ? 'shop_approved' : 'shop_suspended', targetType: 'shop', targetId: d.id, details: '${d.data()?['name'] ?? ''}');
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(12), children: snap.data!.docs.map((d) {
            final x = d.data();
            final approved = x['approved'] == true;
            return Card(child: ListTile(
              leading: Icon(approved ? Icons.verified : Icons.pending),
              title: Text('${x['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${x['phone'] ?? ''}\n${approved ? 'معتمد' : (x['status'] == 'suspended' ? 'موقوف' : 'بانتظار الموافقة')}'),
              isThreeLine: true,
              trailing: approved ? TextButton(onPressed: () => _setState(d, false), child: const Text('إيقاف')) : FilledButton(onPressed: () => _setState(d, true), child: const Text('موافقة')),
            ));
          }).toList());
        },
      );
}

class _OffersTab extends StatelessWidget {
  const _OffersTab();

  Future<void> _approve(DocumentSnapshot<Map<String, dynamic>> d, bool approved) async {
    await d.reference.set({'approved': approved, if (approved) 'approvedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await AuditLogService.record(action: approved ? 'offer_approved' : 'offer_hidden', targetType: 'offer', targetId: d.id, details: '${d.data()?['title'] ?? ''}');
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('offers').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(12), children: snap.data!.docs.map((d) {
            final x = d.data();
            final approved = x['approved'] == true;
            return Card(child: ListTile(
              title: Text('${x['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${x['description'] ?? ''}\n${x['shopName'] ?? ''}'),
              isThreeLine: true,
              trailing: approved ? IconButton(onPressed: () => _approve(d, false), icon: const Icon(Icons.visibility_off)) : FilledButton(onPressed: () => _approve(d, true), child: const Text('نشر')),
            ));
          }).toList());
        },
      );
}

class _SettlementsTab extends StatelessWidget {
  const _SettlementsTab();

  Future<void> _markPaid(DocumentSnapshot<Map<String, dynamic>> d) async {
    final x = d.data()!;
    final batch = FirebaseFirestore.instance.batch();
    batch.update(d.reference, {'status': 'paid', 'paidAt': FieldValue.serverTimestamp()});
    final codes = (x['orderCodes'] as List?)?.map((e) => '$e').toList() ?? <String>[];
    for (final code in codes) {
      batch.update(FirebaseFirestore.instance.collection('orders').doc(code), {'settlementStatus': 'paid'});
    }
    await batch.commit();
    await AuditLogService.record(action: 'settlement_paid', targetType: 'settlement', targetId: d.id, details: '${x['totalCommission'] ?? 0}');
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('settlements').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(12), children: snap.data!.docs.map((d) {
            final x = d.data();
            final pending = x['status'] == 'pending';
            return Card(child: ListTile(
              title: Text('${x['shopName'] ?? x['shopId'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('طلبات: ${x['orderCount'] ?? 0}\nالعمولة: ${_money((x['totalCommission'] as num?)?.toInt() ?? 0)} د.ع • ${pending ? 'بانتظار الدفع' : 'تم الدفع'}'),
              isThreeLine: true,
              trailing: pending ? FilledButton(onPressed: () => _markPaid(d), child: const Text('تم الدفع')) : const Icon(Icons.done_all, color: Colors.green),
            ));
          }).toList());
        },
      );
}
