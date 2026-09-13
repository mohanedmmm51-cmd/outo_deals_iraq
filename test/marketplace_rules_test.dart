import 'package:flutter_test/flutter_test.dart';
import 'package:outo_deals_iraq/marketplace_rules.dart';

void main() {
  group('Iraq settlement week', () {
    test('Sunday 21:00 UTC starts Monday in Baghdad', () {
      final boundary = DateTime.utc(2026, 9, 13, 21);
      expect(iraqWeekStart(boundary), boundary);
      expect(iraqWeekKey(iraqWeekStart(boundary)), '2026-09-14');
      expect(iraqWeekKey(iraqWeekStart(boundary.subtract(const Duration(seconds: 1)))), '2026-09-07');
    });
    test('equivalent instants use the same week across year boundary', () {
      final utc = DateTime.parse('2025-12-31T22:00:00Z');
      final iraq = DateTime.parse('2026-01-01T01:00:00+03:00');
      expect(iraqWeekStart(utc), iraqWeekStart(iraq));
      expect(iraqWeekKey(iraqWeekStart(utc)), '2025-12-29');
    });
  });
  test('coordinates reject missing, infinite and out-of-range values', () {
    expect(validCoordinates(33.3152, 44.3661), isTrue);
    expect(validCoordinates(0, 0), isTrue);
    expect(validCoordinates(null, 44), isFalse);
    expect(validCoordinates(91, 44), isFalse);
    expect(validCoordinates(33, -181), isFalse);
    expect(validCoordinates(double.nan, 44), isFalse);
    expect(validCoordinates(33, double.infinity), isFalse);
  });
  group('order transitions', () {
    final now = DateTime.utc(2026, 9, 13);
    String? change(String current, String next, {bool done = false, bool accepted = true, DateTime? expiry}) =>
      orderTransitionError(current: current, next: next, completed: done,
        termsAccepted: accepted, expiresAt: expiry ?? now.add(const Duration(hours: 1)), now: now);
    test('cancellation only applies to active orders', () {
      for (final state in ['new', 'accepted', 'on_the_way']) {
        expect(change(state, 'cancelled'), isNull);
      }
      for (final state in ['completed', 'cancelled', 'expired', 'unknown']) {
        expect(change(state, 'cancelled'), isNotNull);
      }
      expect(change('accepted', 'cancelled', done: true), isNotNull);
    });
    test('on-the-way requires accepted terms and an unexpired order', () {
      expect(change('accepted', 'on_the_way'), isNull);
      expect(change('new', 'on_the_way'), isNotNull);
      expect(change('accepted', 'on_the_way', accepted: false), isNotNull);
      expect(change('accepted', 'on_the_way', expiry: now), isNotNull);
    });
  });
  group('settlement reconciliation', () {
    late Map<String, dynamic> statement;
    late Map<String, Map<String, dynamic>> orders;
    setUp(() {
      statement = {'shopId': 'a', 'orderCodes': ['12345678'], 'totalSales': 88000,
        'totalCommission': 3000, 'orderCount': 1};
      orders = {'12345678': {'shopId': 'a', 'completed': true, 'status': 'completed',
        'settlementId': 's', 'settlementStatus': 'pending', 'price': 88000, 'commission': 3000}};
    });
    test('valid sale has one 3000 IQD commission', () {
      expect(() => validateSettlementOrders('s', statement, orders), returnsNormally);
    });
    test('stale total or count is rejected', () {
      for (final field in ['totalSales', 'totalCommission', 'orderCount']) {
        final stale = {...statement, field: 0};
        expect(() => validateSettlementOrders('s', stale, orders), throwsStateError);
      }
    });
    test('missing, other-shop and reassigned orders are rejected', () {
      expect(() => validateSettlementOrders('s', statement, {}), throwsStateError);
      for (final field in ['shopId', 'settlementId']) {
        final changed = {'12345678': {...orders['12345678']!, field: 'other'}};
        expect(() => validateSettlementOrders('s', statement, changed), throwsStateError);
      }
    });
    test('paid, cancelled and not-completed orders cannot be paid again', () {
      for (final change in [
        {'settlementStatus': 'paid'}, {'status': 'cancelled'}, {'completed': false},
        {'commission': -1}, {'commission': 90000},
      ]) {
        final changed = {'12345678': {...orders['12345678']!, ...change}};
        expect(() => validateSettlementOrders('s', statement, changed), throwsStateError);
      }
    });
    test('duplicate and oversized statements are rejected', () {
      statement['orderCodes'] = ['12345678', '12345678'];
      expect(() => validateSettlementOrders('s', statement, orders), throwsStateError);
      statement['orderCodes'] = List.generate(451, (i) => '$i');
      expect(() => validateSettlementOrders('s', statement, orders), throwsStateError);
    });
  });
}
