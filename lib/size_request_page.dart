import 'product_requests.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'shop_store.dart';

const _sizeRequestYellow = Color(0xFFFFD400);

String _sizeMoney(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

class EnhancedSizeRequestPage extends StatelessWidget {
  const EnhancedSizeRequestPage({super.key});
  @override
  Widget build(BuildContext context) => const ProductRequestPage();
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
