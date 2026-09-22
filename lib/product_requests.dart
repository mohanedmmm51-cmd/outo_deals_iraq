import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'request_notifications.dart';

final productRequests = FirebaseFirestore.instance.collection('product_requests');

String requestLabel(String type) => type == 'battery' ? 'طلب بطارية' : 'طلب قياس إطار';

class ProductRequestPage extends StatefulWidget {
  const ProductRequestPage({super.key, this.initialType = 'tire', this.initialSize = ''});
  final String initialType;
  final String initialSize;
  @override
  State<ProductRequestPage> createState() => _ProductRequestPageState();
}

class _ProductRequestPageState extends State<ProductRequestPage> {
  late String type = widget.initialType;
  late final size = TextEditingController(text: widget.initialSize);
  final note = TextEditingController();
  bool busy = false;
  String? error;
  // Keep the same document ID on retry so a lost response cannot duplicate a request.
  final request = productRequests.doc();

  @override
  void dispose() { size.dispose(); note.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (busy) return;
    if (size.text.trim().isEmpty) {
      setState(() => error = type == 'battery' ? 'اكتب الأمبير أو نوع سيارتك' : 'اكتب قياس الإطار');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      var user = FirebaseAuth.instance.currentUser;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (user == null) throw StateError('missing user');
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final existing = await tx.get(request);
        if (existing.exists) return;
        tx.set(request, {
          'customerUid': user!.uid, 'type': type, 'size': size.text.trim(),
          'note': note.text.trim(), 'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      final notified = await RequestPushService.notify(request.id, 'created');
      if (!mounted) return;
      if (!notified) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انحفظ طلبك. إشعار الهاتف تعذّر مؤقتاً وراح نحاول مجدداً.')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductRequestDetailPage(id: request.id)));
    } catch (_) {
      if (mounted) setState(() { busy = false; error = 'تعذر إرسال الطلب. تأكد من الاتصال وحاول مجدداً.'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(requestLabel(type))),
    body: Directionality(textDirection: TextDirection.rtl, child: ListView(
      padding: const EdgeInsets.all(20), children: [
        const Text('أرسل طلبك للإدارة ونرد عليك بالمتوفر والسعر.', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(value: type,
          decoration: const InputDecoration(labelText: 'نوع الطلب', border: OutlineInputBorder()),
          items: const [DropdownMenuItem(value: 'tire', child: Text('إطار')), DropdownMenuItem(value: 'battery', child: Text('بطارية'))],
          onChanged: busy ? null : (value) => setState(() { type = value!; size.clear(); error = null; })),
        const SizedBox(height: 16),
        TextField(controller: size, enabled: !busy, maxLength: 100,
          decoration: InputDecoration(labelText: type == 'battery' ? 'الأمبير أو نوع السيارة' : 'قياس الإطار',
            hintText: type == 'battery' ? 'مثال: 74 أمبير، كورولا 2020' : 'مثال: 205/55 R16', border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: note, enabled: !busy, maxLength: 500, minLines: 2, maxLines: 4,
          decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', hintText: 'العدد، النوعية المفضلة أو تفاصيل أخرى', border: OutlineInputBorder())),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: busy ? null : submit, icon: const Icon(Icons.send), label: Text(busy ? 'جاري الإرسال...' : 'إرسال الطلب')),
        TextButton(onPressed: busy ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductRequestsPage())), child: const Text('طلباتي وردود الإدارة')),
      ])),
  );
}

class ProductRequestsPage extends StatelessWidget {
  const ProductRequestsPage({super.key, this.admin = false});
  final bool admin;
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final Query<Map<String, dynamic>> query = admin ? productRequests : productRequests.where('customerUid', isEqualTo: uid ?? '');
    return Scaffold(appBar: AppBar(title: Text(admin ? 'طلبات الزبائن' : 'طلباتي وردود الإدارة')),
      body: Directionality(textDirection: TextDirection.rtl, child: Column(children: [
        const Padding(padding: EdgeInsets.all(12), child: RequestNotificationButton()),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: query.snapshots(), builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('تعذر تحميل الطلبات. تأكد من الاتصال وصلاحية الحساب.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.toList()..sort((a,b) {
            final at = a.data()['createdAt'] as Timestamp?;
            final bt = b.data()['createdAt'] as Timestamp?;
            return (bt?.millisecondsSinceEpoch ?? 0).compareTo(at?.millisecondsSinceEpoch ?? 0);
          });
          if (docs.isEmpty) return const Center(child: Text('ماكو طلبات حالياً'));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (context, i) {
            final doc = docs[i]; final d = doc.data(); final answered = d['status'] == 'answered';
            return Card(child: ListTile(
              leading: Icon(d['type'] == 'battery' ? Icons.battery_charging_full : Icons.tire_repair),
              title: Text('${requestLabel(d['type'] as String)} • ${d['size']}'),
              subtitle: Text(answered ? 'تم الرد • ${d['reply'] ?? ''}' : 'بانتظار رد الإدارة', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Icon(answered ? Icons.mark_email_read : Icons.mark_email_unread, color: answered ? Colors.green : Colors.orange),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductRequestDetailPage(id: doc.id, admin: admin))),
            ));
          });
        })),
      ])),
    );
  }
}

class ProductRequestDetailPage extends StatefulWidget {
  const ProductRequestDetailPage({super.key, required this.id, this.admin = false});
  final String id;
  final bool admin;
  @override
  State<ProductRequestDetailPage> createState() => _ProductRequestDetailPageState();
}

class _ProductRequestDetailPageState extends State<ProductRequestDetailPage> {
  final reply = TextEditingController();
  final price = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() { reply.dispose(); price.dispose(); super.dispose(); }

  Future<void> respond() async {
    if (busy) return;
    final normalized = price.text.trim().replaceAll(',', '').replaceAll('٬', '');
    final amount = normalized.isEmpty ? null : int.tryParse(normalized);
    if (reply.text.trim().isEmpty || (normalized.isNotEmpty && (amount == null || amount <= 0 || amount > 100000000))) {
      setState(() => error = 'اكتب الرد، والسعر بالدينار إذا كان متوفراً.'); return;
    }
    setState(() { busy = true; error = null; });
    try {
      await productRequests.doc(widget.id).update({
        'reply': reply.text.trim(), 'price': amount, 'status': 'answered',
        'repliedBy': FirebaseAuth.instance.currentUser!.uid,
        'repliedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
      final notified = await RequestPushService.notify(widget.id, 'answered');
      if (mounted) {
        if (!notified) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انحفظ الرد. إشعار الهاتف تعذّر مؤقتاً وراح نحاول مجدداً.')));
        reply.clear(); price.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الرد للزبون')));
      }
    } catch (_) { if (mounted) setState(() => error = 'تعذر إرسال الرد. حاول مجدداً.'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل الطلب')),
    body: Directionality(textDirection: TextDirection.rtl, child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: productRequests.doc(widget.id).snapshots(), builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('تعذر تحميل الطلب. تأكد من الحساب والاتصال.'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final d = snap.data!.data();
        if (d == null) return const Center(child: Text('الطلب غير موجود'));
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text(requestLabel(d['type'] as String), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12), Text('${d['size']}', style: const TextStyle(fontSize: 22)),
          if ('${d['note'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${d['note']}')),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['status'] == 'answered' ? 'رد الإدارة' : 'تم استلام الطلب • بانتظار رد الإدارة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (d['status'] == 'answered') ...[
              const SizedBox(height: 12), Text('${d['reply']}', style: const TextStyle(fontSize: 18)),
              if (d['price'] != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text('السعر: ${d['price']} د.ع', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            ],
          ]))),
          if (!widget.admin) ...[
            const SizedBox(height: 16), const RequestNotificationButton(),
            const Text('تلكى طلبك ورد الإدارة في «طلباتي» من نفس الحساب أو المتصفح.'),
          ],
          if (widget.admin) ...[
            const SizedBox(height: 24),
            TextField(controller: reply, enabled: !busy, minLines: 2, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(labelText: 'الرد للزبون', hintText: 'النوعية، المتوفر، السعر للزوج أو للبطارية، أو عدم التوفر', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: price, enabled: !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر بالدينار (اختياري)', border: OutlineInputBorder())),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(onPressed: busy ? null : respond, child: Text(busy ? 'جاري الإرسال...' : 'إرسال الرد')),
          ],
        ]);
      })),
  );
}

class AdminProductRequestsTile extends StatelessWidget {
  const AdminProductRequestsTile({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: productRequests.where('status', isEqualTo: 'pending').snapshots(),
    builder: (context, snap) => Card(color: const Color(0xFFFFD400), child: ListTile(
      leading: const Icon(Icons.mark_email_unread), title: const Text('طلبات الزبائن • إطارات وبطاريات'),
      subtitle: Text(snap.hasError ? 'تعذر تحميل عدد الطلبات' : !snap.hasData ? 'جاري التحميل...' : '${snap.data!.docs.length} طلب جديد بانتظار ردك'),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductRequestsPage(admin: true))),
    )),
  );
}
