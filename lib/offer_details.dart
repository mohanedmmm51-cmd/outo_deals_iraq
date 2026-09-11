import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'offer_products.dart';
import 'order_system.dart';

class OfferDetailsPage extends StatelessWidget {
  final String offerId;
  const OfferDetailsPage({super.key, required this.offerId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل العرض')),
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .doc(offerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
              child: Text('تعذر تحميل العرض. ارجع وحاول مرة ثانية'),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final offer = snapshot.data!.data();
          if (offer == null || offer['approved'] != true)
            return const Center(child: Text('هذا العرض لم يعد متاحاً'));
          final product = findOfferProduct(offer);
          final price = offer['price'];
          final shopId = offer['shopId'] as String? ?? '';
          final canOrder =
              product != null &&
              price is int &&
              price > product.commission &&
              shopId.isNotEmpty;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.local_offer, size: 64, color: Color(0xFFFFD400)),
              const SizedBox(height: 16),
              Text(
                '${offer['title'] ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('${offer['description'] ?? ''}'),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.store),
                title: Text('${offer['shopName'] ?? ''}'),
              ),
              if (product != null) ...[
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(product.detail),
              ],
              if (price is int && price > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'السعر النهائي: $price د.ع',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              if (!canOrder)
                const Text(
                  'هذا العرض للعرض فقط؛ لم يحدد المحل المنتج والسعر اللازمين للطلب.',
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: canOrder
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTicketPage(
                            title: product.title,
                            detail: product.detail,
                            price: price,
                            commission: product.commission,
                            productId: product.id,
                            requiredShopId: shopId,
                            offerId: offerId,
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('طلب العرض'),
              ),
              const SizedBox(height: 12),
              const Text('الدفع نقداً بالمحل بعد تأكيد الطلب.'),
            ],
          );
        },
      ),
    ),
  );
}
