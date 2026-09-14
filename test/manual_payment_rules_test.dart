import 'package:flutter_test/flutter_test.dart';
import 'package:outo_deals_iraq/manual_payment_rules.dart';

void main() {
  Map<String, dynamic> request() => {'shopId': 's1', 'amount': 6000, 'orderCodes': ['1', '2']};
  Map<String, Map<String, dynamic>> orders() => {
    for (final code in ['1', '2']) code: {'shopId': 's1', 'completed': true,
      'status': 'completed', 'settlementStatus': 'pending', 'commission': 3000},
  };
  test('exact payment accepts only matching completed unpaid orders', () {
    expect(validateManualPayment(request(), orders()), 6000);
  });
  test('already paid order cannot be credited twice', () {
    final data = orders(); data['1']!['settlementStatus'] = 'paid';
    expect(() => validateManualPayment(request(), data), throwsStateError);
  });
  test('forged amount, duplicate codes and another shop are rejected', () {
    expect(() => validateManualPayment({...request(), 'amount': 1}, orders()), throwsStateError);
    expect(() => validateManualPayment({...request(), 'orderCodes': ['1', '1']}, orders()), throwsStateError);
    final data = orders(); data['1']!['shopId'] = 's2';
    expect(() => validateManualPayment(request(), data), throwsStateError);
  });
  test('missing and uncompleted orders are rejected', () {
    final data = orders()..remove('1');
    expect(() => validateManualPayment(request(), data), throwsStateError);
    final unfinished = orders(); unfinished['2']!['completed'] = false;
    expect(() => validateManualPayment(request(), unfinished), throwsStateError);
  });
}
