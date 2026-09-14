// Pure validation used before an administrator acknowledges an external payment.
int validateManualPayment(Map<String, dynamic> request,
    Map<String, Map<String, dynamic>> orders) {
  final raw = request['orderCodes'] as List? ?? [];
  final codes = raw.map((e) => '$e').toSet();
  if (codes.isEmpty || codes.length != raw.length || codes.length > 200) {
    throw StateError('قائمة الطلبات غير صالحة');
  }
  var total = 0;
  for (final code in codes) {
    final order = orders[code];
    if (order == null || order['shopId'] != request['shopId'] ||
        order['completed'] != true || order['status'] != 'completed' ||
        order['settlementStatus'] == 'paid') {
      throw StateError('أحد الطلبات تغير أو سدد مسبقاً. ارفض الطلب مع توضيح السبب');
    }
    final fee = order['commission'];
    if (fee is! int || fee <= 0) throw StateError('عمولة غير صالحة');
    total += fee;
  }
  if (total != request['amount']) {
    throw StateError('مبلغ التحويل لا يطابق عمولات الطلبات');
  }
  return total;
}
