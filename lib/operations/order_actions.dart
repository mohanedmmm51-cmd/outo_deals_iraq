part of '../operations_features.dart';

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
