import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _shopIdKey = 'auto_deals_shop_id_v1';
const _shopNameKey = 'auto_deals_shop_name_v1';
const _shopPhoneKey = 'auto_deals_shop_phone_v1';
const _shopLatKey = 'auto_deals_shop_lat_v1';
const _shopLngKey = 'auto_deals_shop_lng_v1';
const _shopApprovedKey = 'auto_deals_shop_approved_v1';

class ShopProfile {
  final String id;
  final String name;
  final String phone;
  final double? latitude;
  final double? longitude;
  final bool approved;

  const ShopProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.latitude,
    this.longitude,
    this.approved = false,
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'location': latitude == null || longitude == null
            ? null
            : GeoPoint(latitude!, longitude!),
        'approved': approved,
        'status': approved ? 'approved' : 'pending',
        'ownerUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory ShopProfile.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) =>
      ShopProfile(
        id: id,
        name: '${data['name'] ?? ''}',
        phone: '${data['phone'] ?? ''}',
        latitude: (data['latitude'] as num?)?.toDouble() ??
            (data['location'] is GeoPoint
                ? (data['location'] as GeoPoint).latitude
                : null),
        longitude: (data['longitude'] as num?)?.toDouble() ??
            (data['location'] is GeoPoint
                ? (data['location'] as GeoPoint).longitude
                : null),
        approved: data['approved'] == true,
      );
}

class ShopStore {
  static final ValueNotifier<int> ownerSessionVersion = ValueNotifier<int>(0);

  static void notifyOwnerSessionChanged() {
    ownerSessionVersion.value++;
  }

  static String createShopId() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    return 'SHOP-${stamp.substring(stamp.length - 10)}';
  }

  static Future<ShopProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_shopIdKey)?.trim() ?? '';
    final name = prefs.getString(_shopNameKey)?.trim() ?? '';
    final phone = prefs.getString(_shopPhoneKey)?.trim() ?? '';
    if (id.isEmpty || name.isEmpty) return null;
    return ShopProfile(
      id: id,
      name: name,
      phone: phone,
      latitude: prefs.getDouble(_shopLatKey),
      longitude: prefs.getDouble(_shopLngKey),
      approved: prefs.getBool(_shopApprovedKey) ?? false,
    );
  }

  static Future<ShopProfile?> loadForAuthenticatedOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      if (userData == null || userData['role'] != 'shop') return null;

      final shopId = '${userData['shopId'] ?? ''}'.trim();
      if (shopId.isEmpty) return null;

      return cacheFromRemote(shopId);
    } catch (_) {
      return null;
    }
  }

  static Future<Position> _requiredPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('فعّل خدمة الموقع GPS ثم حاول مرة ثانية');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('لازم تسمح للتطبيق باستخدام الموقع حتى ينحفظ المحل');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('صلاحية الموقع مرفوضة نهائياً. فعّلها من إعدادات التطبيق');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  static Future<ShopProfile> save({
    required String name,
    required String phone,
    String? shopId,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (cleanName.isEmpty) throw StateError('اكتب اسم المحل');
    if (cleanPhone.isEmpty) throw StateError('اكتب رقم الهاتف');

    final position = await _requiredPosition();
    final prefs = await SharedPreferences.getInstance();
    var id = shopId?.trim() ?? prefs.getString(_shopIdKey)?.trim() ?? '';
    if (id.isEmpty) {
      id = createShopId();
    }

    final docRef = FirebaseFirestore.instance.collection('shops').doc(id);
    final existing = await docRef.get();
    final approved = existing.data()?['approved'] == true;
    final profile = ShopProfile(
      id: id,
      name: cleanName,
      phone: cleanPhone,
      latitude: position.latitude,
      longitude: position.longitude,
      approved: approved,
    );

    await docRef.set({
      ...profile.toFirestore(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'locationAccuracy': position.accuracy,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _cache(profile);

    return profile;
  }

  static Future<ShopProfile?> cacheFromRemote(String shopId) async {
    final doc =
        await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
    if (!doc.exists || doc.data() == null) return null;
    final profile = ShopProfile.fromFirestore(doc.id, doc.data()!);
    await _cache(profile);
    return profile;
  }

  static Future<void> refreshCurrentShop() async {
    final current = await load();
    if (current == null) return;
    await cacheFromRemote(current.id);
  }

  static Future<void> _cache(ShopProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shopIdKey, profile.id);
    await prefs.setString(_shopNameKey, profile.name);
    await prefs.setString(_shopPhoneKey, profile.phone);
    await prefs.setBool(_shopApprovedKey, profile.approved);
    if (profile.latitude != null) {
      await prefs.setDouble(_shopLatKey, profile.latitude!);
    }
    if (profile.longitude != null) {
      await prefs.setDouble(_shopLngKey, profile.longitude!);
    }
  }
}
