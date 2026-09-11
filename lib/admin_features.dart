import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'operations_features.dart';

const adminYellow = Color(0xFFFFD400);

String _money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

DateTime _settlementWeekStart(DateTime value) {
  final d = DateTime(value.year, value.month, value.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

String _settlementWeekKey(DateTime start) =>
    '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';

DateTime _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.fromMillisecondsSinceEpoch(0);
}

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

class AdminOffersPage extends StatelessWidget {
  const AdminOffersPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إدارة العروض')),
        body: const _OffersTab(),
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
          if (snap.hasError) {
            return const Center(child: Text('تعذر تحميل العروض. حاول مرة ثانية.'));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text('ماكو عروض للمراجعة حالياً'));
          }
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

class _SettlementsTab extends StatefulWidget {
  const _SettlementsTab();

  @override
  State<_SettlementsTab> createState() => _SettlementsTabState();
}

class _SettlementsTabState extends State<_SettlementsTab> {
  bool generating = false;

  Future<void> _generateStatements() async {
    if (generating) return;
    setState(() => generating = true);
    try {
      final db = FirebaseFirestore.instance;
      final ordersSnap = await db.collection('orders').where('completed', isEqualTo: true).get();
      final unassigned = ordersSnap.docs.where((d) {
        final x = d.data();
        return '${x['settlementId'] ?? ''}'.isEmpty &&
            (x['status'] == 'completed' || x['completed'] == true);
      }).toList();

      if (unassigned.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ماكو طلبات منفذة جديدة تحتاج كشف تسوية')),
          );
        }
        return;
      }

      final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      final starts = <String, DateTime>{};
      for (final order in unassigned) {
        final data = order.data();
        final shopId = '${data['shopId'] ?? ''}';
        if (shopId.isEmpty) continue;
        final completedAt = _asDate(data['completedAt']);
        final start = _settlementWeekStart(completedAt);
        final baseId = '${shopId}_${_settlementWeekKey(start)}';
        grouped.putIfAbsent(baseId, () => []).add(order);
        starts[baseId] = start;
      }

      var createdOrUpdated = 0;
      var attachedOrders = 0;

      for (final entry in grouped.entries) {
        final baseId = entry.key;
        final candidates = entry.value;
        if (candidates.isEmpty) continue;
        final start = starts[baseId]!;

        final attached = await db.runTransaction<int>((tx) async {
          final baseRef = db.collection('settlements').doc(baseId);
          final baseSnap = await tx.get(baseRef);
          final baseData = baseSnap.data();

          DocumentReference<Map<String, dynamic>> statementRef = baseRef;
          Map<String, dynamic>? existingData = baseData;
          if (baseSnap.exists && '${baseData?['status'] ?? ''}' == 'paid') {
            final lateId = '${baseId}_late_${DateTime.now().microsecondsSinceEpoch}';
            statementRef = db.collection('settlements').doc(lateId);
            existingData = null;
          }

          final freshOrders = <DocumentSnapshot<Map<String, dynamic>>>[];
          for (final candidate in candidates) {
            final fresh = await tx.get(candidate.reference);
            final data = fresh.data();
            if (!fresh.exists || data == null) continue;
            if (data['completed'] != true && data['status'] != 'completed') continue;
            if ('${data['settlementId'] ?? ''}'.isNotEmpty) continue;
            if ('${data['shopId'] ?? ''}' != '${candidates.first.data()['shopId'] ?? ''}') continue;
            final completedAt = _asDate(data['completedAt']);
            if (_settlementWeekKey(_settlementWeekStart(completedAt)) != _settlementWeekKey(start)) continue;
            freshOrders.add(fresh);
          }

          if (freshOrders.isEmpty) return 0;

          final oldCodes = (existingData?['orderCodes'] as List?)
                  ?.map((e) => '$e')
                  .toSet() ??
              <String>{};
          final newOrders = freshOrders.where((order) => !oldCodes.contains(order.id)).toList();
          if (newOrders.isEmpty) return 0;

          final newSales = newOrders.fold<int>(
            0,
            (sum, d) => sum + ((d.data()?['price'] as num?)?.toInt() ?? 0),
          );
          final newCommission = newOrders.fold<int>(
            0,
            (sum, d) => sum + ((d.data()?['commission'] as num?)?.toInt() ?? 0),
          );
          final mergedCodes = <String>{...oldCodes, ...newOrders.map((d) => d.id)}.toList();
          final previousSales = (existingData?['totalSales'] as num?)?.toInt() ?? 0;
          final previousCommission = (existingData?['totalCommission'] as num?)?.toInt() ?? 0;
          final first = newOrders.first.data()!;
          final shopName = '${first['shopName'] ?? first['shopId'] ?? ''}';
          final shopId = '${first['shopId'] ?? ''}';

          tx.set(
            statementRef,
            {
              'id': statementRef.id,
              'shopId': shopId,
              'shopName': shopName,
              'weekStart': Timestamp.fromDate(start),
              'weekEnd': Timestamp.fromDate(start.add(const Duration(days: 7))),
              'totalSales': previousSales + newSales,
              'totalCommission': previousCommission + newCommission,
              'orderCount': mergedCodes.length,
              'orderCodes': mergedCodes,
              'status': 'pending',
              if (existingData == null) 'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'paidAt': null,
            },
            SetOptions(merge: true),
          );
          for (final order in newOrders) {
            tx.update(order.reference, {
              'settlementId': statementRef.id,
              'settlementStatus': 'pending',
            });
          }
          return newOrders.length;
        });

        if (attached > 0) {
          createdOrUpdated++;
          attachedOrders += attached;
        }
      }

      await AuditLogService.record(
        action: 'settlements_generated',
        targetType: 'settlement',
        targetId: 'weekly',
        details: '$createdOrUpdated كشف • $attachedOrders طلب',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث $createdOrUpdated كشف وربط $attachedOrders طلب بشكل ذري وآمن')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء كشوف التسوية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  Future<void> _markPaid(DocumentSnapshot<Map<String, dynamic>> d) async {
    final db = FirebaseFirestore.instance;
    await db.runTransaction<void>((tx) async {
      final freshStatement = await tx.get(d.reference);
      final x = freshStatement.data();
      if (!freshStatement.exists || x == null) {
        throw StateError('كشف التسوية غير موجود');
      }
      if ('${x['status'] ?? ''}' == 'paid') return;
      if ('${x['status'] ?? ''}' != 'pending') {
        throw StateError('حالة كشف التسوية غير صالحة للدفع');
      }

      final codes = (x['orderCodes'] as List?)?.map((e) => '$e').toSet().toList() ?? <String>[];
      if (codes.isEmpty) throw StateError('كشف التسوية ما بيه طلبات');
      if (codes.length > 450) {
        throw StateError('الكشف كبير جداً للدفع الذري. قسّمه إلى أكثر من كشف');
      }

      var verifiedSales = 0;
      var verifiedCommission = 0;
      final verifiedOrders = <DocumentReference<Map<String, dynamic>>>[];
      for (final code in codes) {
        final ref = db.collection('orders').doc(code);
        final order = await tx.get(ref);
        final data = order.data();
        if (!order.exists || data == null) {
          throw StateError('أحد طلبات الكشف غير موجود: $code');
        }
        if (data['completed'] != true && data['status'] != 'completed') {
          throw StateError('الكشف يحتوي طلب غير منفذ: $code');
        }
        if ('${data['settlementId'] ?? ''}' != d.id) {
          throw StateError('الطلب $code مو مربوط بهذا الكشف');
        }
        if ('${data['shopId'] ?? ''}' != '${x['shopId'] ?? ''}') {
          throw StateError('الكشف يحتوي طلب تابع لمحل مختلف');
        }
        verifiedSales += (data['price'] as num?)?.toInt() ?? 0;
        verifiedCommission += (data['commission'] as num?)?.toInt() ?? 0;
        verifiedOrders.add(ref);
      }

      final storedSales = (x['totalSales'] as num?)?.toInt() ?? 0;
      final storedCommission = (x['totalCommission'] as num?)?.toInt() ?? 0;
      final storedCount = (x['orderCount'] as num?)?.toInt() ?? 0;
      if (verifiedSales != storedSales ||
          verifiedCommission != storedCommission ||
          verifiedOrders.length != storedCount) {
        throw StateError('مجموع الكشف ما يطابق الطلبات المنفذة. أعد إنشاء/تحديث الكشف أولاً');
      }

      tx.update(d.reference, {
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      for (final ref in verifiedOrders) {
        tx.update(ref, {'settlementStatus': 'paid'});
      }
    });

    final fresh = await d.reference.get();
    final x = fresh.data() ?? <String, dynamic>{};
    await AuditLogService.record(
      action: 'settlement_paid',
      targetType: 'settlement',
      targetId: d.id,
      details: '${x['totalCommission'] ?? 0}',
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('settlements').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final cards = snap.data!.docs.map((d) {
            final x = d.data();
            final pending = x['status'] == 'pending';
            return Card(child: ListTile(
              title: Text('${x['shopName'] ?? x['shopId'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('طلبات: ${x['orderCount'] ?? 0}\nالعمولة: ${_money((x['totalCommission'] as num?)?.toInt() ?? 0)} د.ع • ${pending ? 'بانتظار الدفع' : 'تم الدفع'}'),
              isThreeLine: true,
              trailing: pending ? FilledButton(onPressed: () async {
                try {
                  await _markPaid(d);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم التحقق من الكشف وتسجيل الدفع')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذر تسجيل الدفع: $e')),
                    );
                  }
                }
              }, child: const Text('تم الدفع')) : const Icon(Icons.done_all, color: Colors.green),
            ));
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              FilledButton.icon(
                onPressed: generating ? null : _generateStatements,
                icon: generating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.security),
                label: Text(generating ? 'جاي أراجع الطلبات...' : 'إنشاء/تحديث كشوف التسوية من الطلبات المنفذة'),
              ),
              const SizedBox(height: 8),
              const Text(
                'الكشوف محمية للإدارة فقط، وتنربط بالطلبات داخل Transaction حتى ما يتكرر نفس الطلب بكشفين. وقبل تسجيل الدفع ينراجع عدد الطلبات والمبيعات والعمولة من الطلبات المنفذة نفسها.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ...cards,
            ],
          );
        },
      );
}
