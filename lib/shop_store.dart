import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _shopIdKey = 'auto_deals_shop_id_v1';
const _shopNameKey = 'auto_deals_shop_name_v1';
const _shopPhoneKey = 'auto_deals_shop_phone_v1';

class ShopProfile {
  final String id;
  final String name;
  final String phone;

  const ShopProfile({
    required this.id,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class ShopStore {
  static Future<ShopProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_shopIdKey)?.trim() ?? '';
    final name = prefs.getString(_shopNameKey)?.trim() ?? '';
    final phone = prefs.getString(_shopPhoneKey)?.trim() ?? '';
    if (id.isEmpty || name.isEmpty) return null;
    return ShopProfile(id: id, name: name, phone: phone);
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

    final profile = ShopProfile(
      id: id,
      name: name.trim(),
      phone: phone.trim(),
    );

    await prefs.setString(_shopIdKey, profile.id);
    await prefs.setString(_shopNameKey, profile.name);
    await prefs.setString(_shopPhoneKey, profile.phone);

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(profile.id)
        .set(profile.toFirestore(), SetOptions(merge: true));

    return profile;
  }
}
