import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'shop_store.dart';
import 'offer_products.dart';

import 'package:flutter/services.dart';

class OfferSubmitPage extends StatefulWidget {
  const OfferSubmitPage({super.key});

  @override
  State<OfferSubmitPage> createState() => _OfferSubmitPageState();
}

class _OfferSubmitPageState extends State<OfferSubmitPage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final products = offerProducts();
  OfferProduct? product;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    price.dispose();
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cleanTitle = title.text.trim();
    final cleanDescription = description.text.trim();
    if (cleanTitle.isEmpty || cleanDescription.isEmpty) {
      setState(() => error = 'اكتب عنوان العرض وتفاصيله');
      return;
    }
    if (cleanTitle.length > 120 || cleanDescription.length > 2000) {
      setState(() => error = 'عنوان العرض أو تفاصيله أطول من الحد المسموح');
      return;
    }

    final amount = int.tryParse(price.text.trim());
    if (product == null ||
        amount == null ||
        amount <= product!.commission ||
        amount > 100000000) {
      setState(() => error = 'اختار المنتج واكتب سعر نهائي صحيح بالدينار');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final shop = await ShopStore.loadForAuthenticatedOwner();
      if (shop == null || !shop.approved) {
        throw StateError('سجل دخول محل معتمد حتى تضيف عرض');
      }
      await FirebaseFirestore.instance.collection('offers').add({
        'title': cleanTitle,
        'description': cleanDescription,
        'shopId': shop.id,
        'shopName': shop.name,
        'productId': product!.id,
        'productDetail': product!.detail,
        'price': amount,
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال العرض للإدارة حتى تراجعه وتنشره'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception is StateError
              ? exception.toString().replaceFirst('Bad state: ', '')
              : 'تعذر إرسال العرض. حاول مرة ثانية.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة عرض')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            DropdownButtonFormField<OfferProduct>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'المنتج وشروطه',
                border: OutlineInputBorder(),
              ),
              items: products
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.title} • ${p.detail}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: busy
                  ? null
                  : (value) => setState(() => product = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'السعر النهائي للعرض بالدينار',
                helperText: 'للإطارات: سعر الزوج شامل الشد والبلنص',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'عنوان العرض',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLength: 2000,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'تفاصيل العرض',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            FilledButton.icon(
              onPressed: busy ? null : _submit,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(busy ? 'جاري الإرسال...' : 'إرسال للموافقة'),
            ),
          ],
        ),
      ),
    );
  }
}
