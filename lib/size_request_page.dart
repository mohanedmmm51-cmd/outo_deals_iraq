import 'dart:math' as math;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'shop_store.dart';

const _sizeRequestYellow = Color(0xFFFFD400);

String _sizeMoney(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

class EnhancedSizeRequestPage extends StatefulWidget {
  const EnhancedSizeRequestPage({super.key});

  @override
  State<EnhancedSizeRequestPage> createState() =>
      _EnhancedSizeRequestPageState();
}

class _EnhancedSizeRequestPageState extends State<EnhancedSizeRequestPage> {
  final type = TextEditingController(text: 'إطار');
  final size = TextEditingController();

  bool busy = false;
  String? requestCode;
  String? error;

  @override
  void dispose() {
    type.dispose();
    size.dispose();
    super.dispose();
  }

  String _createRequestCode() {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    final tail = now.substring(now.length - 6);
    final random = (math.Random.secure().nextInt(9000) + 1000).toString();
    return '$tail$random';
  }

  Future<void> _submit() async {
    final wantedType = type.text.trim();
    final wantedSize = size.text.trim();

    if (wantedSize.isEmpty) {
      setState(() => error = 'اكتب القياس المطلوب أولاً');
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      var user = FirebaseAuth.instance.currentUser;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (user == null) throw StateError('تعذر تثبيت هوية الزبون');

      final code = _createRequestCode();
      await FirebaseFirestore.instance
          .collection('size_requests')
          .doc(code)
          .set({
            'requestCode': code,
            'customerUid': user.uid,
            'type': wantedType.isEmpty ? 'إطار' : wantedType,
            'size': wantedSize,
            'status': 'open',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      setState(() {
        requestCode = code;
        busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = 'تعذر إرسال الطلب للمحلات. تأكد من الإنترنت وحاول مجدداً.';
      });
    }
  }

  void _newRequest() {
    setState(() {
      requestCode = null;
      error = null;
      size.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(requestCode == null ? 'طلب قياس' : 'تذكرة طلب القياس'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: requestCode == null ? _requestForm() : _ticket(),
      ),
    );
  }

  Widget _requestForm() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Icon(Icons.straighten, size: 76, color: _sizeRequestYellow),
        const SizedBox(height: 10),
        const Text(
          'ما لكيت القياس؟',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'أرسل القياس المطلوب للمحلات، وبعد الإرسال يطلع لك كود الطلب وQR والباركود مباشرة.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        TextField(
          controller: type,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'النوع',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: size,
          maxLength: 100,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'القياس المطلوب',
            hintText: 'مثال: 205/55 R16',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _sizeRequestYellow,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: busy ? null : _submit,
          icon: const Icon(Icons.qr_code_2),
          label: Text(
            busy ? 'جاري إنشاء الطلب...' : 'إرسال وإنشاء التذكرة',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _ticket() {
    final code = requestCode!;
    final requestType = type.text.trim().isEmpty ? 'إطار' : type.text.trim();
    final requestSize = size.text.trim();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 72),
        const SizedBox(height: 8),
        const Text(
          'تم إرسال طلبك للمحلات',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        Card(
          color: _sizeRequestYellow,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Text(
                  'كود الطلب',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  code,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$requestType • $requestSize',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Text(
                  'QR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: code,
                  width: 190,
                  height: 190,
                  errorBuilder: (context, error) => const Text('تعذر إنشاء QR'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              children: [
                const Text(
                  'الباركود',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: code,
                  width: 300,
                  height: 92,
                  drawText: true,
                  errorBuilder: (context, error) =>
                      const Text('تعذر إنشاء الباركود'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ردود المحلات',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('size_requests')
              .doc(code)
              .collection('responses')
              .orderBy('quotedAt')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'تعذر تحميل ردود المحلات حالياً.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final responses = snap.data!.docs
                .map((document) => document.data())
                .toList();

            responses.sort(
              (a, b) => ((a['price'] as num?)?.toInt() ?? 0).compareTo(
                (b['price'] as num?)?.toInt() ?? 0,
              ),
            );

            if (responses.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'بعد ماكو ردود. من يرد محل راح يظهر عرضه هنا مباشرة.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: responses.map((response) {
                final price = (response['price'] as num?)?.toInt() ?? 0;
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: _sizeRequestYellow,
                      child: Icon(Icons.storefront, color: Colors.black),
                    ),
                    title: Text(
                      '${response['shopName'] ?? 'محل'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${response['note'] ?? 'متوفر'}'),
                    trailing: Text(
                      '${_sizeMoney(price)} د.ع',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 14),
        const Text(
          'احتفظ بالكود والباركود لحين اختيار العرض المناسب.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _newRequest,
          icon: const Icon(Icons.add),
          label: const Text('طلب قياس جديد'),
        ),
      ],
    );
  }
}

class _QuoteResult {
  final int price;
  final String note;

  const _QuoteResult({required this.price, required this.note});
}

class _QuoteDialog extends StatefulWidget {
  const _QuoteDialog();

  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  final priceController = TextEditingController();
  final noteController = TextEditingController(text: 'متوفر');
  String? error;

  @override
  void dispose() {
    priceController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _send() {
    final price = int.tryParse(priceController.text.trim());
    if (price == null || price <= 0) {
      setState(() => error = 'اكتب سعر صحيح');
      return;
    }

    Navigator.of(context).pop(
      _QuoteResult(
        price: price,
        note: noteController.text.trim().isEmpty
            ? 'متوفر'
            : noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إرسال عرض للزبون'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'السعر النهائي د.ع',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLength: 500,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _send, child: const Text('إرسال')),
      ],
    );
  }
}

class ShopSizeRequestsEnhancedPage extends StatelessWidget {
  const ShopSizeRequestsEnhancedPage({super.key});

  Future<void> _quote(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final shop = await ShopStore.load();
    if (!context.mounted) return;

    if (shop == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('سجل حساب المحل أولاً')));
      return;
    }

    final currentShop = await ShopStore.cacheFromRemote(shop.id);
    if (!context.mounted) return;
    if (currentShop == null || !currentShop.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حساب المحل غير معتمد حالياً')),
      );
      return;
    }

    final result = await showDialog<_QuoteResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _QuoteDialog(),
    );

    if (!context.mounted || result == null) return;

    try {
      final snap = await ref.get();
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('طلب القياس غير موجود');
      }
      if (data['status'] != 'open') {
        throw StateError('هذا الطلب مغلق وما يقبل عروض جديدة');
      }

      await ref.collection('responses').doc(currentShop.id).set({
        'shopId': currentShop.id,
        'shopName': currentShop.name,
        'price': result.price,
        'note': result.note,
        'quotedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إرسال العرض للزبون')));
    } catch (e) {
      if (!context.mounted) return;
      final message = e is StateError
          ? e.toString().replaceFirst('Bad state: ', '')
          : 'تأكد من الإنترنت وحاول مجدداً';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذر إرسال العرض: $message')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات القياسات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('size_requests')
              .where('status', isEqualTo: 'open')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر تحميل طلبات القياسات: ${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs.toList();
            docs.sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];
              final aMillis = aTime is Timestamp
                  ? aTime.millisecondsSinceEpoch
                  : 0;
              final bMillis = bTime is Timestamp
                  ? bTime.millisecondsSinceEpoch
                  : 0;
              return bMillis.compareTo(aMillis);
            });

            if (docs.isEmpty) {
              return const Center(
                child: Text('ماكو طلبات قياسات مفتوحة حالياً'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                return Card(
                  key: ValueKey(doc.id),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: _sizeRequestYellow,
                      child: Icon(Icons.straighten, color: Colors.black),
                    ),
                    title: Text(
                      '${data['type'] ?? 'إطار'} ${data['size'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('كود: ${data['requestCode'] ?? doc.id}'),
                    trailing: FilledButton(
                      onPressed: () => _quote(context, doc.reference),
                      child: const Text('أرسل سعر'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
