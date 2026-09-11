import 'app_core.dart' as legacy;

class OfferProduct {
  final String id;
  final String title;
  final String detail;
  final int commission;
  const OfferProduct(this.id, this.title, this.detail, this.commission);
}

List<OfferProduct> offerProducts() => [
  for (final t in legacy.tires)
    OfferProduct(
      'tire-${t.size}',
      'إطار ${t.size}',
      'سعر الزوج • شد وبلنص حسب العرض',
      t.commission,
    ),
  for (final b in legacy.batteries)
    for (final detail in [
      'مع تسليم البطارية القديمة',
      'بدون تسليم البطارية القديمة',
    ])
      OfferProduct(
        'battery-${b.brand}-${b.amp}',
        '${b.brand} ${b.amp}',
        detail,
        3000,
      ),
];

OfferProduct? findOfferProduct(Map<String, dynamic> data) {
  for (final product in offerProducts()) {
    if (product.id == data['productId'] &&
        product.detail == data['productDetail']) {
      return product;
    }
  }
  return null;
}
