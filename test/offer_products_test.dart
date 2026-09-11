import 'package:flutter_test/flutter_test.dart';

import '../lib/offer_products.dart';

void main() {
  test('legacy text-only offers cannot create priced orders', () {
    expect(findOfferProduct({'title': 'عرض تجريبي'}), isNull);
  });

  test('battery return conditions select distinct variants', () {
    final battery = offerProducts().firstWhere(
      (p) => p.id.startsWith('battery-'),
    );
    final withOld = findOfferProduct({
      'productId': battery.id,
      'productDetail': 'مع تسليم البطارية القديمة',
    });
    final withoutOld = findOfferProduct({
      'productId': battery.id,
      'productDetail': 'بدون تسليم البطارية القديمة',
    });
    expect(withOld, isNotNull);
    expect(withoutOld, isNotNull);
    expect(withOld!.detail, isNot(withoutOld!.detail));
    expect(withOld.commission, 3000);
    expect(withoutOld.commission, 3000);
  });

  test('unknown product or altered variant cannot be ordered', () {
    final tire = offerProducts().firstWhere((p) => p.id.startsWith('tire-'));
    expect(
      findOfferProduct({'productId': 'unknown', 'productDetail': tire.detail}),
      isNull,
    );
    expect(
      findOfferProduct({'productId': tire.id, 'productDetail': 'invalid'}),
      isNull,
    );
    expect(
      findOfferProduct({'productId': tire.id, 'productDetail': tire.detail})!
          .title,
      tire.title,
    );
  });
}
