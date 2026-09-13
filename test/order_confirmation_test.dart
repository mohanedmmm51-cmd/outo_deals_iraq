import 'package:flutter_test/flutter_test.dart';
import 'package:outo_deals_iraq/order_system.dart';

void main() {
  final now = DateTime.utc(2026, 9, 13, 12);
  AppOrder order({
    String status = 'accepted',
    bool completed = false,
    DateTime? expiresAt,
  }) => AppOrder(
    code: '12345678',
    title: 'بطارية',
    detail: '62',
    price: 88000,
    commission: 3000,
    createdAt: now.subtract(const Duration(hours: 1)),
    shopId: 'shop-a',
    status: status,
    completed: completed,
    expiresAt: expiresAt ?? now.add(const Duration(hours: 1)),
  );

  test('accepted and on-the-way orders can be confirmed by their shop', () {
    for (final status in ['accepted', 'on_the_way']) {
      expect(order(status: status).confirmationBlockReason('shop-a', now: now),
          isNull);
    }
  });

  test('pending, cancelled, expired and completed orders cannot be confirmed', () {
    for (final status in ['new', 'cancelled', 'expired', 'completed']) {
      expect(order(status: status).confirmationBlockReason('shop-a', now: now),
          isNotNull);
    }
    expect(order(completed: true).confirmationBlockReason('shop-a', now: now),
        isNotNull);
  });

  test('confirmation requires the assigned shop', () {
    for (final shop in ['', 'shop-b']) {
      expect(order().confirmationBlockReason(shop, now: now), isNotNull);
    }
  });

  test('expiry is enforced at the exact deadline, even for accepted orders', () {
    expect(order(expiresAt: now).confirmationBlockReason('shop-a', now: now),
        isNotNull);
    expect(
        order(expiresAt: now.subtract(const Duration(seconds: 1)))
            .confirmationBlockReason('shop-a', now: now),
        isNotNull);
  });

  test('Arabic and Persian digits and old QR payloads remain supported', () {
    expect(normalizeOrderCode(' ١٢٣٤٥٦٧٨ '), '12345678');
    expect(normalizeOrderCode('۱۲۳۴۵۶۷۸'), '12345678');
    expect(normalizeOrderCode('adi-1234567890|legacy-proof'), 'ADI-1234567890');
  });
}
