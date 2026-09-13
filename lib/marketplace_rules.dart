// Shared, platform-independent marketplace validation.
DateTime iraqWeekStart(DateTime instant) {
  final iraq = instant.toUtc().add(const Duration(hours: 3));
  final monday = DateTime.utc(iraq.year, iraq.month, iraq.day)
      .subtract(Duration(days: iraq.weekday - DateTime.monday));
  return monday.subtract(const Duration(hours: 3));
}

String iraqWeekKey(DateTime start) {
  final date = start.toUtc().add(const Duration(hours: 3));
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

bool validCoordinates(double? latitude, double? longitude) =>
    latitude != null && longitude != null &&
    latitude.isFinite && longitude.isFinite &&
    latitude >= -90 && latitude <= 90 &&
    longitude >= -180 && longitude <= 180;

String? orderTransitionError({
  required String current,
  required String next,
  required bool completed,
  required bool termsAccepted,
  required DateTime? expiresAt,
  required DateTime now,
}) {
  if (completed || ['completed', 'cancelled', 'expired'].contains(current)) {
    return 'الطلب منفذ أو ملغي أو منتهي الصلاحية';
  }
  if (expiresAt != null && !now.isBefore(expiresAt)) {
    return 'انتهت صلاحية الطلب';
  }
  if (next == 'cancelled' && ['new', 'accepted', 'on_the_way'].contains(current)) {
    return null;
  }
  if (next == 'on_the_way' && current == 'accepted' && termsAccepted) return null;
  return 'تغيرت حالة الطلب. حدّث الصفحة وحاول مرة ثانية';
}

void validateSettlementOrders(
  String id,
  Map<String, dynamic> statement,
  Map<String, Map<String, dynamic>> orders,
) {
  final rawCodes = (statement['orderCodes'] as List?) ?? [];
  final codes = rawCodes.map((e) => '$e').toSet();
  if (codes.isEmpty || codes.length != rawCodes.length || codes.length > 450) {
    throw StateError('كشف التسوية فارغ أو يحتوي تكرار أو يتجاوز 450 طلب');
  }
  var sales = 0;
  var commission = 0;
  for (final code in codes) {
    final order = orders[code];
    if (order == null || order['completed'] != true || order['status'] != 'completed') {
      throw StateError('الكشف يحتوي طلب غير منفذ أو مفقود: $code');
    }
    if (order['settlementId'] != id || order['shopId'] != statement['shopId']) {
      throw StateError('أحد الطلبات غير مربوط بهذا الكشف أو المحل');
    }
    if (order['settlementStatus'] != 'pending') {
      throw StateError('أحد الطلبات مدفوع أو غير جاهز للتسوية');
    }
    final price = order['price'];
    final fee = order['commission'];
    if (price is! int || fee is! int || price < 0 || fee < 0 || fee > price) {
      throw StateError('سعر أو عمولة غير صالحة في الكشف');
    }
    sales += price;
    commission += fee;
  }
  if (sales != statement['totalSales'] || commission != statement['totalCommission'] ||
      codes.length != statement['orderCount']) {
    throw StateError('مجموع الكشف ما يطابق الطلبات المنفذة');
  }
}
