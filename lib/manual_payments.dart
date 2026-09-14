import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'shop_store.dart';
import 'manual_payment_rules.dart';
import 'marketplace_rules.dart';

String _money(dynamic n) => '$n'.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
String _status(dynamic s) => s == 'approved' ? 'تم تأكيد الاستلام' :
    s == 'rejected' ? 'مرفوض — راجع السبب' : 'بانتظار تأكيد الاستلام';

class ManualPaymentService {
  static final db = FirebaseFirestore.instance;

  static Future<void> submit(ShopProfile shop, List<String> codes, int amount,
      String reference, String receipt, String instructions) async {
    final ref = db.collection('payment_requests').doc(shop.id);
    await db.runTransaction((tx) async {
      final current = (await tx.get(ref)).data();
      if (current?['status'] == 'pending') {
        throw StateError('عندك طلب تسديد بانتظار المراجعة');
      }
      final settings = (await tx.get(db.collection('payment_settings').doc('manual'))).data();
      if (settings?['instructions'] != instructions || instructions.trim().isEmpty) {
        throw StateError('تغيرت بيانات التحويل. ارجع وافتح الصفحة من جديد');
      }
      final orders = <String, Map<String, dynamic>>{};
      for (final code in codes) {
        final value = (await tx.get(db.collection('orders').doc(code))).data();
        if (value != null) orders[code] = value;
      }
      final data = <String, dynamic>{
        'shopId': shop.id, 'shopName': shop.name,
        'ownerUid': FirebaseAuth.instance.currentUser!.uid,
        'amount': amount, 'orderCodes': codes, 'reference': reference.trim(),
        'receiptBase64': receipt, 'instructions': instructions,
        'status': 'pending', 'submittedAt': FieldValue.serverTimestamp(),
      };
      validateManualPayment(data, orders);
      tx.set(ref, data);
    });
  }

  static Future<void> review(String shopId, bool approve, String reason, dynamic submittedAt) async {
    final ref = db.collection('payment_requests').doc(shopId);
    final history = db.collection('payment_history').doc();
    await db.runTransaction((tx) async {
      final request = (await tx.get(ref)).data();
      if (request == null || request['status'] != 'pending' || request['submittedAt'] != submittedAt) {
        throw StateError('هذا الطلب تمت مراجعته مسبقاً');
      }
      final orders = <String, Map<String, dynamic>>{};
      final statements = <String, Map<String, dynamic>>{};
      if (approve) {
        for (final code in (request['orderCodes'] as List).cast<String>()) {
          final order = (await tx.get(db.collection('orders').doc(code))).data();
          if (order != null) orders[code] = order;
        }
        validateManualPayment(request, orders);
        final ids = orders.values.map((o) => '${o['settlementId'] ?? ''}')
            .where((id) => id.isNotEmpty).toSet();
        for (final id in ids) {
          final statement = (await tx.get(db.collection('settlements').doc(id))).data();
          if (statement == null || statement['shopId'] != shopId || statement['status'] != 'pending') {
            throw StateError('كشف مرتبط تغير. راجع الكشف قبل تأكيد الاستلام');
          }
          statements[id] = statement;
          for (final code in (statement['orderCodes'] as List).cast<String>()) {
            if (!orders.containsKey(code)) {
              final order = (await tx.get(db.collection('orders').doc(code))).data();
              if (order == null) throw StateError('طلب مفقود من الكشف');
              orders[code] = order;
            }
          }
        }
      }
      for (final entry in statements.entries) {
        validateSettlementOrders(entry.key, entry.value, orders);
      }
      final paidCodes = (request['orderCodes'] as List).cast<String>().toSet();
      if (approve) {
        for (final code in paidCodes) {
          tx.update(db.collection('orders').doc(code), {
            'settlementStatus': 'paid', 'manualPaymentId': history.id,
          });
        }
        for (final entry in statements.entries) {
          final remaining = (entry.value['orderCodes'] as List).cast<String>()
              .where((code) => !paidCodes.contains(code)).toList();
          final update = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
          if (remaining.isEmpty) {
            update.addAll({'status': 'paid', 'paidAt': FieldValue.serverTimestamp()});
          } else {
            // Keep unpaid orders in the weekly statement. The immutable payment
            // history retains the exact paid codes and amount, including partial payments.
            update.addAll({
              'orderCodes': remaining, 'orderCount': remaining.length,
              'totalSales': remaining.fold<int>(0, (sum, code) => sum + (orders[code]!['price'] as int)),
              'totalCommission': remaining.fold<int>(0, (sum, code) => sum + (orders[code]!['commission'] as int)),
            });
          }
          tx.update(db.collection('settlements').doc(entry.key), update);
        }
      }
      final decision = <String, dynamic>{
        'status': approve ? 'approved' : 'rejected',
        'reason': reason, 'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser!.uid,
      };
      tx.update(ref, decision);
      tx.set(history, {...request, ...decision});
    });
  }
}

class ShopManualPaymentPage extends StatefulWidget {
  final ShopProfile shop;
  const ShopManualPaymentPage({super.key, required this.shop});
  @override
  State<ShopManualPaymentPage> createState() => _ShopManualPaymentPageState();
}

class _ShopManualPaymentPageState extends State<ShopManualPaymentPage> {
  final reference = TextEditingController();
  Uint8List? receipt;
  bool busy = false;
  String? error;
  late final Future<DocumentSnapshot<Map<String, dynamic>>> settings;
  late Future<QuerySnapshot<Map<String, dynamic>>> orders;
  String? ordersVersion;
  @override
  void initState() {
    super.initState();
    orders = ManualPaymentService.db.collection('orders').where('shopId', isEqualTo: widget.shop.id).get(const GetOptions(source: Source.server));
    settings = ManualPaymentService.db.collection('payment_settings').doc('manual').get();
  }
  @override
  void dispose() { reference.dispose(); super.dispose(); }

  Future<void> _pick() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery,
          maxWidth: 1400, maxHeight: 1400, imageQuality: 65);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 300000) throw StateError('الصورة كبيرة. اختار صورة وصل أصغر من 300 كيلوبايت');
      if (mounted) setState(() { receipt = bytes; error = null; });
    } catch (e) { if (mounted) setState(() => error = '$e'); }
  }

  Future<void> _submit(List<String> codes, int amount, String instructions) async {
    if (busy) return;
    if (receipt == null || reference.text.trim().isEmpty) {
      setState(() => error = 'اكتب رقم التحويل وأرفق صورة الوصل'); return;
    }
    setState(() { busy = true; error = null; });
    try {
      await ManualPaymentService.submit(widget.shop, codes, amount,
          reference.text, base64Encode(receipt!), instructions);
      if (mounted) setState(() { receipt = null; reference.clear(); });
    } catch (e) {
      if (mounted) setState(() => error = '$e'.replaceFirst('Bad state: ', ''));
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تسديد المستحقات')),
    body: Directionality(textDirection: TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ManualPaymentService.db.collection('payment_requests').doc(widget.shop.id).snapshots(),
        builder: (context, requestSnap) {
          if (requestSnap.hasError) return const Center(child: Text('تعذر تحميل طلب التسديد. أعد فتح الصفحة'));
          if (!requestSnap.hasData) return const Center(child: CircularProgressIndicator());
          final request = requestSnap.data!.data();
          final version = '${request?['submittedAt']}_${request?['status']}';
          if (ordersVersion != version) {
            ordersVersion = version;
            orders = ManualPaymentService.db.collection('orders').where('shopId', isEqualTo: widget.shop.id).get(const GetOptions(source: Source.server));
          }
          if (request?['status'] == 'pending') {
            return ListView(padding: const EdgeInsets.all(20), children: [
              const Icon(Icons.hourglass_top, size: 48),
              const Text('بانتظار تأكيد الاستلام', textAlign: TextAlign.center),
              Text('المبلغ: ${_money(request!['amount'])} د.ع'),
              Text('رقم التحويل: ${request['reference']}'),
              const Text('وصل إثبات التحويل للإدارة. تبقى المستحقات إلى أن يتم تأكيد وصول المبلغ.'),
            ]);
          }
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: settings,
            builder: (context, settingsSnap) {
              if (settingsSnap.hasError) return const Center(child: Text('تعذر تحميل بيانات التحويل. أعد فتح الصفحة'));
              if (!settingsSnap.hasData) return const Center(child: CircularProgressIndicator());
              final instructions = '${settingsSnap.data!.data()?['instructions'] ?? ''}'.trim();
              return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: orders,
                builder: (context, snap) {
                  if (snap.hasError) return const Center(child: Text('تعذر تحميل المستحقات. أعد فتح الصفحة'));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final due = snap.data!.docs.where((d) => d.data()['completed'] == true &&
                      d.data()['status'] == 'completed' && d.data()['settlementStatus'] != 'paid').toList()
                    ..sort((a, b) => a.id.compareTo(b.id));
                  final selected = due.take(200).toList();
                  final amount = selected.fold<int>(0, (sum, d) => sum + ((d.data()['commission'] as num?)?.toInt() ?? 0));
                  return ListView(padding: const EdgeInsets.all(20), children: [
                    if (request != null) ...[
                      Text(_status(request['status'])),
                      if ('${request['reason'] ?? ''}'.isNotEmpty) Text('${request['reason']}'),
                      const Divider(),
                    ],
                    Text('المبلغ المطلوب: ${_money(amount)} د.ع', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                    Text('${selected.length} طلب منفذ'),
                    if (due.length > 200) const Text('هذه الدفعة لأول 200 طلب. تبقى بقية المستحقات لدفعة لاحقة.'),
                    const SizedBox(height: 16),
                    if (instructions.isEmpty) const Text('بيانات التحويل لم تُحدد بعد من الإدارة. ستظهر هنا بعد إعدادها.')
                    else ...[
                      const Text('طريقة التحويل وبيانات المستلم', style: TextStyle(fontWeight: FontWeight.bold)),
                      SelectableText(instructions),
                    ],
                    const SizedBox(height: 16),
                    if (amount > 0 && instructions.isNotEmpty) ...[
                      const Text('حوّل المبلغ خارج التطبيق إلى الجهة الموضحة، ثم أرفق الإثبات. الحساب يتحدث بعد تأكيد الاستلام.'),
                      TextField(controller: reference, maxLength: 120, decoration: const InputDecoration(labelText: 'رقم التحويل / مرجع العملية')),
                      OutlinedButton.icon(onPressed: busy ? null : _pick, icon: const Icon(Icons.attach_file), label: const Text('إرفاق صورة الوصل')),
                      if (receipt != null) Image.memory(receipt!, height: 200, errorBuilder: (_, __, ___) => const Text('تعذر عرض الصورة. اختار صورة أخرى')),
                      FilledButton(onPressed: busy ? null : () => _submit(selected.map((d) => d.id).toList(), amount, instructions),
                          child: Text(busy ? 'جاري الإرسال...' : 'إرسال إثبات التسديد')),
                    ],
                    if (amount == 0) const Text('ما عندك مستحقات غير مسددة حالياً'),
                    if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                  ]);
                },
              );
            },
          );
        },
      ),
    ),
  );
}

class AdminManualPaymentsPage extends StatefulWidget {
  const AdminManualPaymentsPage({super.key});
  @override
  State<AdminManualPaymentsPage> createState() => _AdminManualPaymentsPageState();
}

class _AdminManualPaymentsPageState extends State<AdminManualPaymentsPage> {
  final instructions = TextEditingController();
  bool loading = true;
  bool busy = false;
  String? error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final doc = await ManualPaymentService.db.collection('payment_settings').doc('manual').get();
      if (!mounted) return;
      instructions.text = '${doc.data()?['instructions'] ?? ''}';
    } catch (e) { error = '$e'; }
    if (mounted) setState(() => loading = false);
  }
  @override
  void dispose() { instructions.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (busy || instructions.text.trim().isEmpty) return;
    setState(() { busy = true; error = null; });
    try {
      await ManualPaymentService.db.collection('payment_settings').doc('manual').set({
        'instructions': instructions.text.trim(), 'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات التحويل')));
    } catch (e) { if (mounted) setState(() => error = '$e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> _review(String id, bool approve, dynamic submittedAt) async {
    if (busy) return;
    var reasonText = '';
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(approve ? 'تأكيد استلام المبلغ' : 'رفض إثبات التسديد'),
      content: approve ? const Text('تأكد من وصول كامل المبلغ فعلياً لحسابك. صورة الوصل وحدها لا تكفي. سيتم تسديد الطلبات المرتبطة فقط.') :
        TextField(onChanged: (value) => reasonText = value.trim(), maxLength: 500, decoration: const InputDecoration(labelText: 'سبب الرفض')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رجوع')),
        FilledButton(onPressed: () { if (approve || reasonText.isNotEmpty) Navigator.pop(context, true); }, child: const Text('تأكيد'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try { await ManualPaymentService.review(id, approve, reasonText, submittedAt); }
    catch (e) { if (mounted) setState(() => error = '$e'.replaceFirst('Bad state: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تسديدات المحلات')),
    body: Directionality(textDirection: TextDirection.rtl,
      child: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16), children: [
          TextField(controller: instructions, minLines: 3, maxLines: 6, maxLength: 2000,
              decoration: const InputDecoration(labelText: 'طريقة التحويل، رقم الحساب / المحفظة، اسم المستلم')),
          FilledButton(onPressed: busy ? null : _save, child: const Text('حفظ بيانات التحويل')),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          const Divider(),
          const Text('إثباتات التسديد الواردة'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ManualPaymentService.db.collection('payment_requests').where('status', isEqualTo: 'pending').snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return const Text('تعذر تحميل التسديدات');
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return const Text('ماكو إثباتات بانتظار المراجعة');
              return Column(children: snap.data!.docs.map((d) {
                final x = d.data();
                return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${x['shopName']} — ${_money(x['amount'])} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText('مرجع التحويل: ${x['reference']}'),
                    Text('بيانات التحويل وقت الإرسال: ${x['instructions']}'),
                    _ReceiptPreview(encoded: '${x['receiptBase64'] ?? ''}'),
                    FilledButton(onPressed: busy ? null : () => _review(d.id, true, x['submittedAt']), child: const Text('تأكيد استلام المبلغ')),
                    TextButton(onPressed: busy ? null : () => _review(d.id, false, x['submittedAt']), child: const Text('رفض مع ذكر السبب')),
                  ],
                )));
              }).toList());
            },
          ),
        ],
      ),
    ),
  );
}

class _ReceiptPreview extends StatelessWidget {
  final String encoded;
  const _ReceiptPreview({required this.encoded});
  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(encoded);
      return InkWell(onTap: () => showDialog<void>(context: context, builder: (context) => Dialog(
        child: InteractiveViewer(child: Image.memory(bytes,
            errorBuilder: (_, __, ___) => const Text('تعذر عرض الوصل'))))),
        child: Image.memory(bytes, height: 180,
            errorBuilder: (_, __, ___) => const Text('تعذر عرض الوصل')));
    } catch (_) { return const Text('صيغة الوصل غير صالحة'); }
  }
}
