import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _shopIdKey = 'auto_deals_shop_id_v1';
const _shopNameKey = 'auto_deals_shop_name_v1';
const _shopPhoneKey = 'auto_deals_shop_phone_v1';
const _shopLatKey = 'auto_deals_shop_lat_v1';
const _shopLngKey = 'auto_deals_shop_lng_v1';

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
        'approved': approved,
        'status': approved ? 'approved' : 'pending',
        'ownerUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory ShopProfile.fromFirestore(String id, Map<String, dynamic> data) => ShopProfile(
        id: id,
        name: '${data['name'] ?? ''}',
        phone: '${data['phone'] ?? ''}',
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
        approved: data['approved'] == true,
      );
}

class ShopStore {
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
    );
  }

  static Future<ShopProfile> save({
    required String name,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_shopIdKey)?.trim() ?? '';
    if (id.isEmpty) {
      final stamp = DateTime.now().millisecondsSinceEpoch.toString();
      id = 'SHOP-${stamp.substring(stamp.length - 8)}';
    }

    double? lat;
    double? lng;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        final p = await Geolocator.getCurrentPosition();
        lat = p.latitude;
        lng = p.longitude;
      }
    } catch (_) {}

    final existing = await FirebaseFirestore.instance.collection('shops').doc(id).get();
    final approved = existing.data()?['approved'] == true;
    final profile = ShopProfile(
      id: id,
      name: name.trim(),
      phone: phone.trim(),
      latitude: lat,
      longitude: lng,
      approved: approved,
    );

    await _cache(profile);
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(profile.id)
        .set(profile.toFirestore(), SetOptions(merge: true));

    return profile;
  }

  static Future<ShopProfile?> cacheFromRemote(String shopId) async {
    final doc = await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
    if (!doc.exists || doc.data() == null) return null;
    final profile = ShopProfile.fromFirestore(doc.id, doc.data()!);
    await _cache(profile);
    return profile;
  }

  static Future<void> _cache(ShopProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shopIdKey, profile.id);
    await prefs.setString(_shopNameKey, profile.name);
    await prefs.setString(_shopPhoneKey, profile.phone);
    if (profile.latitude != null) await prefs.setDouble(_shopLatKey, profile.latitude!);
    if (profile.longitude != null) await prefs.setDouble(_shopLngKey, profile.longitude!);
  }
}
