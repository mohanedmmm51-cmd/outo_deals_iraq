import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'request_notifications.dart';

final productRequests = FirebaseFirestore.instance.collection('product_requests');

String requestStatusLabel(String? status) => switch (status) {
  'answered' => 'تم رد الإدارة',
  'accepted' => 'وافق الزبون',
  'completed' => 'مكتمل',
  'cancelled' => 'ملغي',
  _ => 'جديد • بانتظار رد الإدارة',
};

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
            final doc = docs[i]; final d = doc.data(); final status = d['status'] as String?; final answered = status != 'pending';
            return Card(child: ListTile(
              leading: Icon(d['type'] == 'battery' ? Icons.battery_charging_full : Icons.tire_repair),
              title: Text('${requestLabel(d['type'] as String)} • ${d['size']}'),
              subtitle: Text('${requestStatusLabel(status)}${d['reply'] == null ? '' : ' • ${d['reply']}'}', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Icon(status == 'cancelled' ? Icons.cancel_outlined : status == 'completed' ? Icons.check_circle : answered ? Icons.mark_email_read : Icons.mark_email_unread, color: status == 'cancelled' ? Colors.red : answered ? Colors.green : Colors.orange),
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
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ref = productRequests.doc(widget.id);
        final existing = await tx.get(ref);
        if (!['pending', 'answered'].contains(existing.data()?['status'])) {
          throw StateError('تغيّرت حالة الطلب. لا يمكن تعديل الرد بعد الموافقة أو الإغلاق.');
        }
        tx.update(ref, {
        'reply': reply.text.trim(), 'price': amount, 'status': 'answered',
        'repliedBy': FirebaseAuth.instance.currentUser!.uid,
        'repliedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
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

  Future<void> changeStatus(String target, Map<String, dynamic> displayed) async {
    if (busy) return;
    final title = target == 'accepted' ? 'الموافقة على العرض' : target == 'completed' ? 'تأكيد إكمال الطلب' : 'إلغاء الطلب';
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(target == 'accepted' ? 'توافق على السعر ${displayed['price']} د.ع والتفاصيل المذكورة بالرد؟' : target == 'completed' ? 'تأكد أن الطلب تم تسليمه للزبون قبل الإكمال.' : 'تريد تلغي هذا الطلب؟ يبقى ظاهر بالسجل كملغي.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رجوع')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ref = productRequests.doc(widget.id), current = await tx.get(productRequests.doc(widget.id));
        final d = current.data();
        if (d == null) throw StateError('الطلب غير موجود');
        if (d['status'] == target) return;
        if (target == 'accepted' && (d['status'] != 'answered' || d['price'] != displayed['price'] || d['reply'] != displayed['reply'] || d['repliedAt'] != displayed['repliedAt'])) {
          throw StateError('تغيّر العرض. راجع الرد والسعر الجديد وحاول مرة ثانية.');
        }
        final time = FieldValue.serverTimestamp();
        final update = <String, dynamic>{'status': target, 'updatedAt': time};
        if (target == 'accepted') update['acceptedAt'] = time;
        if (target == 'completed') { update['completedAt'] = time; update['completedBy'] = FirebaseAuth.instance.currentUser!.uid; }
        if (target == 'cancelled') { update['cancelledAt'] = time; update['cancelledBy'] = FirebaseAuth.instance.currentUser!.uid; }
        tx.update(ref, update);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحديث الطلب: ${requestStatusLabel(target)}')));
    } catch (e) { if (mounted) setState(() => error = e is StateError ? e.message.toString() : 'تعذر تحديث الطلب. قد تكون حالته تغيّرت؛ راجعها وحاول مجدداً.'); }
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
            Text(requestStatusLabel(d['status'] as String?), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (d['reply'] != null) ...[
              const SizedBox(height: 12), Text('${d['reply']}', style: const TextStyle(fontSize: 18)),
              if (d['price'] != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text('السعر: ${d['price']} د.ع', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            ],
          ]))),
          if (!widget.admin) ...[
            const SizedBox(height: 16), const RequestNotificationButton(),
            const Text('تلكى طلبك ورد الإدارة في «طلباتي» من نفس الحساب أو المتصفح.'),
          ],
          const SizedBox(height: 16),
          RequestProgress(data: d),
          if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          if (!widget.admin && d['customerUid'] == FirebaseAuth.instance.currentUser?.uid && d['status'] == 'answered' && d['price'] is int && (d['price'] as int) > 0)
            FilledButton.icon(onPressed: busy ? null : () => changeStatus('accepted', d), icon: const Icon(Icons.check), label: const Text('أوافق على العرض والسعر')),
          if (widget.admin && d['status'] == 'accepted')
            FilledButton.icon(onPressed: busy ? null : () => changeStatus('completed', d), icon: const Icon(Icons.task_alt), label: const Text('تأكيد إكمال الطلب')),
          if (['pending', 'answered', 'accepted'].contains(d['status']))
            TextButton.icon(onPressed: busy ? null : () => changeStatus('cancelled', d), icon: const Icon(Icons.cancel_outlined), label: const Text('إلغاء الطلب')),
          if (widget.admin && ['pending', 'answered'].contains(d['status'])) ...[
            const SizedBox(height: 24),
            TextField(controller: reply, enabled: !busy, minLines: 2, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(labelText: 'الرد للزبون', hintText: 'النوعية، المتوفر، السعر للزوج أو للبطارية، أو عدم التوفر', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: price, enabled: !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر بالدينار (اختياري)', border: OutlineInputBorder())),
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

class RequestProgress extends StatelessWidget {
  const RequestProgress({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final stages = <(String, String)>[('createdAt', 'تم إرسال الطلب'), ('repliedAt', 'رد الإدارة'), ('acceptedAt', 'موافقة الزبون'), ('completedAt', 'إكمال الطلب')];
    if (data['status'] == 'cancelled') stages.add(('cancelledAt', 'إلغاء الطلب'));
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: stages.map((stage) {
      final value = data[stage.$1];
      final done = value is Timestamp;
      final date = done ? value.toDate().toUtc().add(const Duration(hours: 3)) : null;
      final stamp = date == null ? '' : '${date.year}/${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
        Icon(done ? (stage.$1 == 'cancelledAt' ? Icons.cancel : Icons.check_circle) : Icons.radio_button_unchecked, color: done ? (stage.$1 == 'cancelledAt' ? Colors.red : Colors.green) : Colors.grey),
        const SizedBox(width: 12), Expanded(child: Text(stage.$2)),
        if (done) Text(stamp, style: Theme.of(context).textTheme.bodySmall),
      ]));
    }).toList())));
  }
}
