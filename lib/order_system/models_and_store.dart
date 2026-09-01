part of '../order_system_impl.dart';

const _ordersKey = 'auto_deals_orders_v1';
const _ordersCollection = 'orders';
const orderYellow = Color(0xFFFFD400);

String _money(int n) => n.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

String createOrderCode() {
  final now = DateTime.now().microsecondsSinceEpoch.toString();
  return 'ADI-${now.substring(now.length - 10)}';
}

class AppOrder {
  final String code;
  final String title;
  final String detail;
  final int price;
  final int commission;
  final DateTime createdAt;
  final bool completed;
  final DateTime? completedAt;
  final String shopId;
  final String shopName;
  final String status;
  final DateTime? expiresAt;
  final String productId;

  const AppOrder({
    required this.code,
    required this.title,
    required this.detail,
    required this.price,
    required this.commission,
    required this.createdAt,
    this.completed = false,
    this.completedAt,
    this.shopId = '',
    this.shopName = '',
    this.status = 'new',
    this.expiresAt,
    this.productId = '',
  });

  AppOrder copyWith({
    bool? completed,
    DateTime? completedAt,
    String? shopId,
    String? shopName,
    String? status,
    DateTime? expiresAt,
    String? productId,
  }) => AppOrder(
    code: code,
    title: title,
    detail: detail,
    price: price,
    commission: commission,
    createdAt: createdAt,
    completed: completed ?? this.completed,
    completedAt: completedAt ?? this.completedAt,
    shopId: shopId ?? this.shopId,
    shopName: shopName ?? this.shopName,
    status: status ?? this.status,
    expiresAt: expiresAt ?? this.expiresAt,
    productId: productId ?? this.productId,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'title': title,
    'detail': detail,
    'price': price,
    'commission': commission,
    'createdAt': createdAt.toIso8601String(),
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'shopId': shopId,
    'shopName': shopName,
    'status': status,
    'expiresAt': expiresAt?.toIso8601String(),
    'productId': productId,
  };

  Map<String, dynamic> toFirestore() => {
    'code': code,
    'title': title,
    'detail': detail,
    'price': price,
    'commission': commission,
    'createdAt': Timestamp.fromDate(createdAt),
    'completed': completed,
    'completedAt': completedAt == null
        ? null
        : Timestamp.fromDate(completedAt!),
    'shopId': shopId,
    'shopName': shopName,
    'status': status,
    'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    'productId': productId,
    'priceLocked': true,
    'priceLockedAt': FieldValue.serverTimestamp(),
    'settlementId': '',
    'settlementStatus': '',
  };

  factory AppOrder.fromJson(Map<String, dynamic> json) => AppOrder(
    code: '${json['code'] ?? ''}',
    title: '${json['title'] ?? ''}',
    detail: '${json['detail'] ?? ''}',
    price: (json['price'] as num?)?.toInt() ?? 0,
    commission: (json['commission'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    completed: json['completed'] == true,
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.tryParse('${json['completedAt']}'),
    shopId: '${json['shopId'] ?? ''}',
    shopName: '${json['shopName'] ?? ''}',
    status:
        '${json['status'] ?? (json['completed'] == true ? 'completed' : 'new')}',
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.tryParse('${json['expiresAt']}'),
    productId: '${json['productId'] ?? ''}',
  );

  factory AppOrder.fromFirestore(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value');
    }

    final completed = json['completed'] == true;
    return AppOrder(
      code: '${json['code'] ?? ''}',
      title: '${json['title'] ?? ''}',
      detail: '${json['detail'] ?? ''}',
      price: (json['price'] as num?)?.toInt() ?? 0,
      commission: (json['commission'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['createdAt']),
      completed: completed,
      completedAt: parseNullableDate(json['completedAt']),
      shopId: '${json['shopId'] ?? ''}',
      shopName: '${json['shopName'] ?? ''}',
      status: '${json['status'] ?? (completed ? 'completed' : 'new')}',
      expiresAt: parseNullableDate(json['expiresAt']),
      productId: '${json['productId'] ?? ''}',
    );
  }
}

class OrderStore {
  static CollectionReference<Map<String, dynamic>> get _remote =>
      FirebaseFirestore.instance.collection(_ordersCollection);

  static Future<List<AppOrder>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      final orders = data
          .whereType<Map>()
          .map((e) => AppOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveLocal(List<AppOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersKey,
      jsonEncode(orders.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<AppOrder>> load() async {
    final local = await _loadLocal();
    if (local.isEmpty) return local;
    final refreshed = <AppOrder>[];
    for (final owned in local.take(100)) {
      try {
        final doc = await _remote.doc(owned.code).get();
        if (doc.exists && doc.data() != null) {
          refreshed.add(AppOrder.fromFirestore(doc.data()!));
        } else {
          refreshed.add(owned);
        }
      } catch (_) {
        refreshed.add(owned);
      }
    }
    refreshed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveLocal(refreshed);
    return refreshed;
  }

  static Future<AppOrder> create({
    required String title,
    required String detail,
    required int price,
    required int commission,
    required String shopId,
    required String shopName,
    String productId = '',
  }) async {
    final now = DateTime.now();
    final order = AppOrder(
      code: createOrderCode(),
      title: title,
      detail: detail,
      price: price,
      commission: commission,
      createdAt: now,
      shopId: shopId,
      shopName: shopName,
      status: 'new',
      expiresAt: now.add(const Duration(hours: 24)),
      productId: productId,
    );

    final db = FirebaseFirestore.instance;
    final orderRef = _remote.doc(order.code);
    final shopRef = db.collection('shops').doc(shopId);

    await db.runTransaction((tx) async {
      final shopSnap = await tx.get(shopRef);
      final shopData = shopSnap.data();
      if (!shopSnap.exists ||
          shopData == null ||
          shopData['approved'] != true) {
        throw StateError('هذا المحل غير متاح للطلبات حالياً');
      }
      if (shopData['status'] == 'suspended') {
        throw StateError('هذا المحل موقوف حالياً');
      }

      if (productId.trim().isNotEmpty && shopData['inventoryEnabled'] == true) {
        final inventoryRef = InventoryService.itemRef(shopId, productId);
        final inventorySnap = await tx.get(inventoryRef);
        final inventory = inventorySnap.data();
        final quantity = (inventory?['quantity'] as num?)?.toInt() ?? 0;
        if (!inventorySnap.exists ||
            inventory?['available'] != true ||
            quantity <= 0) {
          throw StateError('هذا المنتج نفد من المحل. اختار محل ثاني');
        }
      }

      tx.set(orderRef, {
        ...order.toFirestore(),
        'inventoryCheckedAt': FieldValue.serverTimestamp(),
      });
    });

    final local = await _loadLocal();
    local.removeWhere((e) => e.code == order.code);
    local.insert(0, order);
    await _saveLocal(local);

    try {
      await db.collection('notifications').add({
        'targetShopId': shopId,
        'title': 'طلب جديد',
        'body': '$title • ${_money(price)} د.ع',
        'orderCode': order.code,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    await AuditLogService.record(
      action: 'order_created',
      targetType: 'order',
      targetId: order.code,
      details: '$shopName • سعر مثبت ${_money(price)} د.ع',
    );
    return order;
  }

  static Future<AppOrder?> findByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    try {
      final doc = await _remote.doc(normalized).get();
      if (doc.exists && doc.data() != null) {
        final order = AppOrder.fromFirestore(doc.data()!);
        await _upsertLocal(order);
        return order;
      }
    } catch (_) {}
    final orders = await _loadLocal();
    for (final order in orders) {
      if (order.code.toUpperCase() == normalized) return order;
    }
    return null;
  }

  static Future<AppOrder?> confirm(
    String code, {
    required String shopId,
    required String shopName,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final db = FirebaseFirestore.instance;
    final docRef = _remote.doc(normalized);

    final result = await db.runTransaction<AppOrder?>((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists || snap.data() == null) return null;
      final current = AppOrder.fromFirestore(snap.data()!);
      if (current.shopId.isNotEmpty && current.shopId != shopId) {
        throw StateError('هذا الطلب مخصص لمحل آخر');
      }
      if (current.status == 'cancelled') throw StateError('هذا الطلب ملغي');
      if (current.status == 'expired') {
        throw StateError('انتهت صلاحية كود الطلب');
      }
      if (current.expiresAt != null &&
          DateTime.now().isAfter(current.expiresAt!) &&
          !current.completed) {
        tx.update(docRef, {
          'status': 'expired',
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        });
        throw StateError('انتهت صلاحية كود الطلب');
      }
      if (current.completed) {
        throw StateError('هذا الطلب منفذ مسبقاً ولا يمكن تسجيله مرة ثانية');
      }

      final shopRef = db.collection('shops').doc(shopId);
      final shopSnap = await tx.get(shopRef);
      final shopData = shopSnap.data();
      if (!shopSnap.exists ||
          shopData == null ||
          shopData['approved'] != true) {
        throw StateError('حساب المحل غير معتمد');
      }
      if (shopData['status'] == 'suspended') {
        throw StateError('حساب المحل موقوف');
      }

      if (current.productId.trim().isNotEmpty &&
          shopData['inventoryEnabled'] == true) {
        final inventoryRef = InventoryService.itemRef(
          shopId,
          current.productId,
        );
        final inventorySnap = await tx.get(inventoryRef);
        final inventory = inventorySnap.data();
        final quantity = (inventory?['quantity'] as num?)?.toInt() ?? 0;
        if (!inventorySnap.exists ||
            inventory?['available'] != true ||
            quantity <= 0) {
          throw StateError(
            'المنتج صار نافد. لا يمكن تنفيذ الطلب أو تسجيل العمولة',
          );
        }
        final newQuantity = quantity - 1;
        tx.update(inventoryRef, {
          'quantity': newQuantity,
          'available': newQuantity > 0,
          'lastSoldAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final completedAt = DateTime.now();
      tx.update(docRef, {
        'completed': true,
        'completedAt': Timestamp.fromDate(completedAt),
        'status': 'completed',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'settlementId': '',
        'settlementStatus': '',
        'inventoryConsumedAt': FieldValue.serverTimestamp(),
      });
      return current.copyWith(
        completed: true,
        completedAt: completedAt,
        status: 'completed',
      );
    });

    if (result != null) {
      await _upsertLocal(result);
      await AuditLogService.record(
        action: 'order_completed',
        targetType: 'order',
        targetId: result.code,
        details: '$shopName • ${_money(result.price)} د.ع',
      );
    }
    return result;
  }

  static Future<void> _upsertLocal(AppOrder order) async {
    final orders = await _loadLocal();
    final index = orders.indexWhere((e) => e.code == order.code);
    if (index >= 0) {
      orders[index] = order;
    } else {
      orders.insert(0, order);
    }
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveLocal(orders);
  }
}
