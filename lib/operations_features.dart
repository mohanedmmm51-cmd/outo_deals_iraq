import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'shop_store.dart';

const operationsYellow = Color(0xFFFFD400);

String opMoney(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

DateTime opDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String orderStatusLabel(String status) {
  switch (status) {
    case 'accepted':
      return 'مقبول';
    case 'on_the_way':
      return 'الزبون بالطريق';
    case 'completed':
      return 'منفذ';
    case 'cancelled':
      return 'ملغي';
    case 'expired':
      return 'منتهي';
    default:
      return 'جديد';
  }
}

class AuditLogService {
  static Future<void> record({
    required String action,
    required String targetType,
    required String targetId,
    String details = '',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'details': details,
        'actorUid': user?.uid ?? '',
        'actorEmail': user?.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}

class OrderActionsPage extends StatefulWidget {
  final String orderCode;
  const OrderActionsPage({super.key, required this.orderCode});

  @override
  State<OrderActionsPage> createState() => _OrderActionsPageState();
}

class _OrderActionsPageState extends State<OrderActionsPage> {
  final note = TextEditingController();

  Future<void> _setStatus(String status) async {
    final ref = FirebaseFirestore.instance.collection('orders').doc(widget.orderCode);
    await ref.set({
      'status': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditLogService.record(
      action: 'order_status_$status',
      targetType: 'order',
      targetId: widget.orderCode,
    );
  }

  Future<void> _cancel() async {
    await _setStatus('cancelled');
    await FirebaseFirestore.instance.collection('orders').doc(widget.orderCode).set({
      'cancelledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _addNote() async {
    final text = note.text.trim();
    if (text.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderCode)
        .collection('notes')
        .add({
      'text': text,
      'actorUid': FirebaseAuth.instance.currentUser?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    note.clear();
  }

  Future<void> _share(Map<String, dynamic> data) async {
    final status = '${data['status'] ?? (data['completed'] == true ? 'completed' : 'new')}';
    final text = 'طلب Auto Deals Iraq\n'
        'الكود: ${widget.orderCode}\n'
        'المنتج: ${data['title'] ?? ''}\n'
        'المحل: ${data['shopName'] ?? ''}\n'
        'السعر: ${opMoney((data['price'] as num?)?.toInt() ?? 0)} د.ع\n'
        'الحالة: ${orderStatusLabel(status)}';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('orders').doc(widget.orderCode);
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final data = snap.data!.data();
            if (data == null) return const Center(child: Text('الطلب غير موجود'));

            var status = '${data['status'] ?? ''}';
            if (status.isEmpty) status = data['completed'] == true ? 'completed' : 'new';
            final expires = opDate(data['expiresAt']);
            if (expires.millisecondsSinceEpoch > 0 &&
                DateTime.now().isAfter(expires) &&
                status != 'completed' &&
                status != 'cancelled') {
              status = 'expired';
            }
            final terminal = status == 'completed' || status == 'cancelled' || status == 'expired';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: operationsYellow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${data['title'] ?? ''}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                        Text('الكود: ${widget.orderCode}'),
                        Text('المحل: ${data['shopName'] ?? ''}'),
                        Text('السعر: ${opMoney((data['price'] as num?)?.toInt() ?? 0)} د.ع'),
                        Text('الحالة: ${orderStatusLabel(status)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _share(data),
                  icon: const Icon(Icons.share),
                  label: const Text('مشاركة الطلب'),
                ),
                if (!terminal) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _setStatus('on_the_way'),
                    icon: const Icon(Icons.directions_car),
                    label: const Text('أنا بالطريق للمحل'),
                  ),
                  TextButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.cancel),
                    label: const Text('إلغاء الطلب'),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplaintSubmitPage(
                        orderCode: widget.orderCode,
                        shopId: '${data['shopId'] ?? ''}',
                        shopName: '${data['shopName'] ?? ''}',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('إرسال شكوى على المحل'),
                ),
                const SizedBox(height: 12),
                const Text('ملاحظات الطلب', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: note,
                        decoration: const InputDecoration(hintText: 'اكتب ملاحظة', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: _addNote, icon: const Icon(Icons.send)),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: ref.collection('notes').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, notesSnap) {
                    if (!notesSnap.hasData) return const SizedBox.shrink();
                    return Column(
                      children: notesSnap.data!.docs.map((d) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.note_alt_outlined),
                            title: Text('${d.data()['text'] ?? ''}'),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ComplaintSubmitPage extends StatefulWidget {
  final String orderCode;
  final String shopId;
  final String shopName;
  const ComplaintSubmitPage({
    super.key,
    required this.orderCode,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ComplaintSubmitPage> createState() => _ComplaintSubmitPageState();
}

class _ComplaintSubmitPageState extends State<ComplaintSubmitPage> {
  final controller = TextEditingController();
  bool busy = false;

  Future<void> _submit() async {
    final text = controller.text.trim();
    if (text.isEmpty || widget.shopId.isEmpty) return;
    setState(() => busy = true);
    await FirebaseFirestore.instance.collection('complaints').add({
      'orderCode': widget.orderCode,
      'shopId': widget.shopId,
      'shopName': widget.shopName,
      'text': text,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إرسال شكوى')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(widget.shopName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'تفاصيل الشكوى', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: busy ? null : _submit, child: const Text('إرسال الشكوى')),
              ],
            ),
          ),
        ),
      );
}

class ShopOrdersPage extends StatelessWidget {
  const ShopOrdersPage({super.key});

  Future<void> _accept(DocumentReference<Map<String, dynamic>> ref) async {
    await ref.set({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditLogService.record(action: 'order_accepted', targetType: 'order', targetId: ref.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopProfile?>(
      future: ShopStore.load(),
      builder: (context, shopSnap) {
        final shop = shopSnap.data;
        if (shop == null) return const Scaffold(body: Center(child: Text('سجل دخول المحل أولاً')));
        return Scaffold(
          appBar: AppBar(title: const Text('طلبات المحل')),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('orders').where('shopId', isEqualTo: shop.id).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs.toList()
                  ..sort((a, b) => opDate(b.data()['createdAt']).compareTo(opDate(a.data()['createdAt'])));
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final x = d.data();
                    var status = '${x['status'] ?? ''}';
                    if (status.isEmpty) status = x['completed'] == true ? 'completed' : 'new';
                    return Card(
                      child: ListTile(
                        title: Text('${x['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${d.id}\n${orderStatusLabel(status)} • ${opMoney((x['price'] as num?)?.toInt() ?? 0)} د.ع'),
                        isThreeLine: true,
                        trailing: status == 'new'
                            ? FilledButton(onPressed: () => _accept(d.reference), child: const Text('قبول'))
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class OrdersManagementPage extends StatefulWidget {
  const OrdersManagementPage({super.key});
  @override
  State<OrdersManagementPage> createState() => _OrdersManagementPageState();
}

class _OrdersManagementPageState extends State<OrdersManagementPage> {
  final search = TextEditingController();
  String status = 'all';
  DateTime? from;
  DateTime? to;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final q = search.text.trim().toLowerCase();
    return docs.where((d) {
      final x = d.data();
      var s = '${x['status'] ?? ''}';
      if (s.isEmpty) s = x['completed'] == true ? 'completed' : 'new';
      final date = opDate(x['createdAt']);
      if (status != 'all' && s != status) return false;
      if (from != null && date.isBefore(DateTime(from!.year, from!.month, from!.day))) return false;
      if (to != null && date.isAfter(DateTime(to!.year, to!.month, to!.day, 23, 59, 59))) return false;
      if (q.isEmpty) return true;
      return '${d.id} ${x['title']} ${x['shopName']} ${x['detail']}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: from ?? DateTime.now(),
    );
    if (d != null) setState(() => from = d);
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: to ?? DateTime.now(),
    );
    if (d != null) setState(() => to = d);
  }

  Future<void> _exportCsv(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final lines = <String>['code,title,shop,status,price,commission,createdAt'];
    String esc(dynamic value) => '"${'$value'.replaceAll('"', '""')}"';
    for (final d in docs) {
      final x = d.data();
      var s = '${x['status'] ?? ''}';
      if (s.isEmpty) s = x['completed'] == true ? 'completed' : 'new';
      lines.add([
        esc(d.id),
        esc(x['title']),
        esc(x['shopName']),
        esc(s),
        x['price'] ?? 0,
        x['commission'] ?? 0,
        esc(opDate(x['createdAt']).toIso8601String()),
      ].join(','));
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/auto_deals_orders.csv');
    await file.writeAsString(lines.join('\n'));
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'تقرير طلبات Auto Deals Iraq'),
    );
  }

  Future<void> _exportPdf(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final pdf = pw.Document();
    final total = docs.fold<int>(0, (value, d) => value + ((d.data()['price'] as num?)?.toInt() ?? 0));
    final commission = docs.fold<int>(0, (value, d) => value + ((d.data()['commission'] as num?)?.toInt() ?? 0));
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text('Auto Deals Iraq Orders Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Orders: ${docs.length}  Sales: $total IQD  Commission: $commission IQD'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['Code', 'Shop', 'Status', 'Price', 'Commission'],
            data: docs.map((d) {
              final x = d.data();
              var s = '${x['status'] ?? ''}';
              if (s.isEmpty) s = x['completed'] == true ? 'completed' : 'new';
              return [d.id, '${x['shopName'] ?? ''}', s, '${x['price'] ?? 0}', '${x['commission'] ?? 0}'];
            }).toList(),
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/auto_deals_orders.pdf');
    await file.writeAsBytes(await pdf.save());
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'تقرير طلبات Auto Deals Iraq'),
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث والتقارير')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = _filter(snap.data!.docs);
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث بالكود أو المحل أو المنتج',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('كل الحالات')),
                    DropdownMenuItem(value: 'new', child: Text('جديد')),
                    DropdownMenuItem(value: 'accepted', child: Text('مقبول')),
                    DropdownMenuItem(value: 'on_the_way', child: Text('بالطريق')),
                    DropdownMenuItem(value: 'completed', child: Text('منفذ')),
                    DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                  ],
                  onChanged: (v) => setState(() => status = v ?? 'all'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: _pickFrom, child: Text(from == null ? 'من تاريخ' : '${from!.year}/${from!.month}/${from!.day}'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: _pickTo, child: Text(to == null ? 'إلى تاريخ' : '${to!.year}/${to!.month}/${to!.day}'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: FilledButton.icon(onPressed: docs.isEmpty ? null : () => _exportCsv(docs), icon: const Icon(Icons.table_view), label: const Text('CSV'))),
                    const SizedBox(width: 8),
                    Expanded(child: FilledButton.icon(onPressed: docs.isEmpty ? null : () => _exportPdf(docs), icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF'))),
                  ],
                ),
                const SizedBox(height: 10),
                Text('النتائج: ${docs.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...docs.map((d) {
                  final x = d.data();
                  var s = '${x['status'] ?? ''}';
                  if (s.isEmpty) s = x['completed'] == true ? 'completed' : 'new';
                  return Card(
                    child: ListTile(
                      title: Text('${x['title'] ?? ''}'),
                      subtitle: Text('${d.id}\n${x['shopName'] ?? ''} • ${orderStatusLabel(s)} • ${opMoney((x['price'] as num?)?.toInt() ?? 0)} د.ع'),
                      isThreeLine: true,
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
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return Scaffold(
      appBar: AppBar(title: const Text('إحصائيات هذا الشهر')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final completed = snap.data!.docs.where((d) {
              final x = d.data();
              final date = opDate(x['completedAt'] ?? x['createdAt']);
              final done = x['completed'] == true || x['status'] == 'completed';
              return done && !date.isBefore(monthStart) && date.isBefore(nextMonth);
            }).toList();
            final sales = completed.fold<int>(0, (value, d) => value + ((d.data()['price'] as num?)?.toInt() ?? 0));
            final commissions = completed.fold<int>(0, (value, d) => value + ((d.data()['commission'] as num?)?.toInt() ?? 0));
            final avg = completed.isEmpty ? 0 : sales ~/ completed.length;
            final products = <String, int>{};
            final shops = <String, int>{};
            for (final d in completed) {
              final x = d.data();
              final title = '${x['title'] ?? ''}';
              final shop = '${x['shopName'] ?? ''}';
              products[title] = (products[title] ?? 0) + 1;
              if (shop.isNotEmpty) shops[shop] = (shops[shop] ?? 0) + 1;
            }
            final topProducts = products.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            final topShops = shops.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _stat('مبيعات', '${opMoney(sales)} د.ع', Icons.payments)),
                    const SizedBox(width: 8),
                    Expanded(child: _stat('عمولات', '${opMoney(commissions)} د.ع', Icons.account_balance_wallet)),
                  ],
                ),
                const SizedBox(height: 8),
                _stat('متوسط الطلب', '${opMoney(avg)} د.ع', Icons.analytics),
                const SizedBox(height: 16),
                const Text('أكثر المنتجات طلباً', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ...topProducts.take(10).map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value} طلب'))),
                const SizedBox(height: 12),
                const Text('أكثر المحلات مبيعاً', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ...topShops.take(10).map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value} طلب'))),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon) => Card(
        color: operationsYellow,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, size: 32),
              Text(title),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}

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

class ShopRiskPage extends StatelessWidget {
  const ShopRiskPage({super.key});

  Future<Map<String, dynamic>> _load() async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('shops').get(),
      db.collection('complaints').get(),
      db.collection('settlements').where('status', isEqualTo: 'pending').get(),
    ]);
    return {
      'shops': results[0] as QuerySnapshot<Map<String, dynamic>>,
      'complaints': results[1] as QuerySnapshot<Map<String, dynamic>>,
      'settlements': results[2] as QuerySnapshot<Map<String, dynamic>>,
    };
  }

  Future<void> _suspend(String shopId, String name) async {
    await FirebaseFirestore.instance.collection('shops').doc(shopId).set({
      'approved': false,
      'status': 'suspended',
      'suspendedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditLogService.record(action: 'shop_suspended_risk', targetType: 'shop', targetId: shopId, details: name);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مخاطر وشكاوى المحلات')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _load(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final shops = (snap.data!['shops'] as QuerySnapshot<Map<String, dynamic>>).docs;
              final complaints = (snap.data!['complaints'] as QuerySnapshot<Map<String, dynamic>>).docs;
              final settlements = (snap.data!['settlements'] as QuerySnapshot<Map<String, dynamic>>).docs;
              final now = DateTime.now();
              return ListView(
                padding: const EdgeInsets.all(12),
                children: shops.map((shop) {
                  final x = shop.data();
                  final complaintCount = complaints.where((c) => c.data()['shopId'] == shop.id && c.data()['status'] == 'open').length;
                  final overdue = settlements.any((s) {
                    if (s.data()['shopId'] != shop.id) return false;
                    final created = opDate(s.data()['createdAt']);
                    return created.millisecondsSinceEpoch > 0 && now.difference(created).inDays >= 7;
                  });
                  final risky = complaintCount >= 3 || overdue;
                  return Card(
                    color: risky ? Colors.orange.shade100 : null,
                    child: ListTile(
                      leading: Icon(risky ? Icons.warning_amber : Icons.verified_user),
                      title: Text('${x['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('شكاوى مفتوحة: $complaintCount\n${overdue ? 'تسوية متأخرة 7 أيام أو أكثر' : 'التسويات طبيعية'}'),
                      isThreeLine: true,
                      trailing: risky
                          ? FilledButton(onPressed: () => _suspend(shop.id, '${x['name'] ?? ''}'), child: const Text('تعليق'))
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      );
}

class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سجل النشاط')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('audit_logs').orderBy('createdAt', descending: true).limit(300).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              return ListView(
                padding: const EdgeInsets.all(12),
                children: snap.data!.docs.map((d) {
                  final x = d.data();
                  return Card(
                    child: ListTile(
                      title: Text('${x['action'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${x['targetType'] ?? ''}: ${x['targetId'] ?? ''}\n${x['actorEmail'] ?? ''} • ${x['details'] ?? ''}'),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      );
}
