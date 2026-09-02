import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'shop_dashboard.dart';
import 'shop_store.dart';

const featureYellow = Color(0xFFFFD400);

String _money(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

DateTime _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class NotificationService {
  static Future<void> init() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      final user = FirebaseAuth.instance.currentUser;
      if (token != null && user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }
}

class ShopAuthPage extends StatefulWidget {
  const ShopAuthPage({super.key});

  @override
  State<ShopAuthPage> createState() => _ShopAuthPageState();
}

class _ShopAuthPageState extends State<ShopAuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final shopName = TextEditingController();
  final phone = TextEditingController();
  bool register = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    shopName.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (register) {
        UserCredential cred;
        try {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text,
          );
        }

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid);
        final existingUser = await userRef.get();
        final existingShopId = '${existingUser.data()?['shopId'] ?? ''}'.trim();
        final shopId = existingShopId.isEmpty
            ? ShopStore.createShopId()
            : existingShopId;

        await userRef.set({
          'role': 'shop',
          'shopId': shopId,
          'email': email.text.trim(),
          if (!existingUser.exists) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await ShopStore.save(
          name: shopName.text.trim(),
          phone: phone.text.trim(),
          shopId: shopId,
        );
      } else {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        final data = userDoc.data();
        if (data == null || data['role'] != 'shop') {
          await FirebaseAuth.instance.signOut();
          throw Exception('هذا الحساب مو حساب محل');
        }
        final shopId = '${data['shopId'] ?? ''}';
        if (shopId.isNotEmpty) {
          await ShopStore.cacheFromRemote(shopId);
        }
      }
      ShopStore.notifyOwnerSessionChanged();
      await NotificationService.init();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShopDashboardPage()),
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(register ? 'إنشاء حساب محل' : 'دخول صاحب المحل')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (register) ...[
              TextField(controller: shopName, decoration: const InputDecoration(labelText: 'اسم المحل', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder())),
              const SizedBox(height: 12),
            ],
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: busy ? null : _submit,
              icon: const Icon(Icons.login),
              label: Text(register ? 'إنشاء الحساب' : 'تسجيل الدخول'),
            ),
            TextButton(
              onPressed: busy ? null : () => setState(() => register = !register),
              child: Text(register ? 'عندي حساب بالفعل' : 'إنشاء حساب محل جديد'),
            ),
            if (error != null) Text(error!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> _login() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (doc.data()?['role'] != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw Exception('هذا الحساب مو حساب إدارة');
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول الإدارة')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            FilledButton(onPressed: busy ? null : _login, child: const Text('دخول')),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!)),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة إدارة Auto Deals Iraq'),
        actions: [
          IconButton(onPressed: () async { await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, ordersSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('shops').snapshots(),
              builder: (context, shopsSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('settlements').snapshots(),
                  builder: (context, settleSnap) {
                    final orders = ordersSnap.data?.docs ?? [];
                    final shops = shopsSnap.data?.docs ?? [];
                    final settlements = settleSnap.data?.docs ?? [];
                    final completed = orders.where((d) => d.data()['completed'] == true).toList();
                    final pendingSettlements = settlements.where((d) => d.data()['status'] == 'pending').toList();
                    final due = pendingSettlements.fold<int>(0, (s, d) => s + ((d.data()['totalCommission'] as num?)?.toInt() ?? 0));
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(children: [Expanded(child: _adminStat('الطلبات', '${orders.length}', Icons.receipt_long)), const SizedBox(width: 8), Expanded(child: _adminStat('المنفذة', '${completed.length}', Icons.check_circle))]),
                        const SizedBox(height: 8),
                        Row(children: [Expanded(child: _adminStat('المحلات', '${shops.length}', Icons.store)), const SizedBox(width: 8), Expanded(child: _adminStat('عمولات معلقة', '${_money(due)} د.ع', Icons.account_balance_wallet))]),
                        const SizedBox(height: 18),
                        const Text('طلبات انضمام المحلات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ...shops.where((d) => d.data()['approved'] != true).map((d) => Card(child: ListTile(
                          title: Text('${d.data()['name'] ?? ''}'),
                          subtitle: Text('${d.data()['phone'] ?? ''}'),
                          trailing: FilledButton(onPressed: () => d.reference.set({'approved': true, 'status': 'approved'}, SetOptions(merge: true)), child: const Text('موافقة')),
                        ))),
                        const SizedBox(height: 18),
                        const Text('التسويات الأسبوعية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ...settlements.map((d) {
                          final data = d.data();
                          final pending = data['status'] == 'pending';
                          return Card(child: ListTile(
                            title: Text('${data['shopName'] ?? data['shopId'] ?? ''}'),
                            subtitle: Text('العمولة: ${_money((data['totalCommission'] as num?)?.toInt() ?? 0)} د.ع • ${pending ? 'بانتظار الدفع' : 'تم الدفع'}'),
                            trailing: pending ? FilledButton(onPressed: () async {
                              final batch = FirebaseFirestore.instance.batch();
                              batch.update(d.reference, {'status': 'paid', 'paidAt': FieldValue.serverTimestamp()});
                              final codes = (data['orderCodes'] as List?)?.cast<String>() ?? <String>[];
                              for (final code in codes) {
                                batch.update(FirebaseFirestore.instance.collection('orders').doc(code), {'settlementStatus': 'paid'});
                              }
                              await batch.commit();
                            }, child: const Text('تم الدفع')) : const Icon(Icons.done_all, color: Colors.green),
                          ));
                        }),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _adminStat(String title, String value, IconData icon) => Card(
        color: featureYellow,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [Icon(icon, size: 34), const SizedBox(height: 6), Text(title), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
        ),
      );
}

class OnlineOffersPage extends StatelessWidget {
  const OnlineOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العروض والخصومات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('offers').where('approved', isEqualTo: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs.toList()..sort((a, b) => _asDate(b.data()['createdAt']).compareTo(_asDate(a.data()['createdAt'])));
            if (docs.isEmpty) return const Center(child: Text('ماكو عروض حالياً'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data();
                return Card(child: ListTile(
                  leading: const CircleAvatar(backgroundColor: featureYellow, child: Icon(Icons.local_offer, color: Colors.black)),
                  title: Text('${d['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${d['description'] ?? ''}\n${d['shopName'] ?? ''}'),
                  isThreeLine: true,
                ));
              },
            );
          },
        ),
      ),
    );
  }
}

class OfferSubmitPage extends StatefulWidget {
  const OfferSubmitPage({super.key});

  @override
  State<OfferSubmitPage> createState() => _OfferSubmitPageState();
}

class _OfferSubmitPageState extends State<OfferSubmitPage> {
  final title = TextEditingController();
  final description = TextEditingController();

  Future<void> _submit() async {
    final shop = await ShopStore.load();
    if (shop == null) return;
    await FirebaseFirestore.instance.collection('offers').add({
      'title': title.text.trim(),
      'description': description.text.trim(),
      'shopId': shop.id,
      'shopName': shop.name,
      'approved': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إضافة عرض')),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان العرض', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'تفاصيل العرض', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            FilledButton(onPressed: _submit, child: const Text('إرسال للموافقة')),
          ]),
        ),
      );
}

class OnlineNearbyShopsPage extends StatefulWidget {
  const OnlineNearbyShopsPage({super.key});

  @override
  State<OnlineNearbyShopsPage> createState() => _OnlineNearbyShopsPageState();
}

class _OnlineNearbyShopsPageState extends State<OnlineNearbyShopsPage> {
  Position? position;
  String? error;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('صلاحية الموقع غير مفعلة');
      final p = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => position = p);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحلات القريبة')),
      body: position == null
          ? Center(child: error == null ? const CircularProgressIndicator() : Text(error!))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('shops').where('approved', isEqualTo: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final shops = snap.data!.docs.map((d) {
                  final data = d.data();
                  final lat = (data['latitude'] as num?)?.toDouble();
                  final lng = (data['longitude'] as num?)?.toDouble();
                  final distance = lat == null || lng == null ? double.infinity : Geolocator.distanceBetween(position!.latitude, position!.longitude, lat, lng) / 1000;
                  return (doc: d, distance: distance);
                }).toList()..sort((a, b) => a.distance.compareTo(b.distance));
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: shops.length,
                    itemBuilder: (_, i) {
                      final item = shops[i];
                      final data = item.doc.data();
                      final lat = (data['latitude'] as num?)?.toDouble();
                      final lng = (data['longitude'] as num?)?.toDouble();
                      return Card(child: ListTile(
                        leading: const Icon(Icons.storefront),
                        title: Text('${data['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.distance.isFinite ? '${item.distance.toStringAsFixed(1)} كم' : 'الموقع غير محدد'),
                        trailing: lat == null || lng == null ? null : IconButton(icon: const Icon(Icons.directions), onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'), mode: LaunchMode.externalApplication)),
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }
}

class OnlineSizeRequestPage extends StatefulWidget {
  const OnlineSizeRequestPage({super.key});

  @override
  State<OnlineSizeRequestPage> createState() => _OnlineSizeRequestPageState();
}

class _OnlineSizeRequestPageState extends State<OnlineSizeRequestPage> {
  final type = TextEditingController(text: 'إطار');
  final size = TextEditingController();
  final phone = TextEditingController();

  Future<void> _submit() async {
    await FirebaseFirestore.instance.collection('size_requests').add({
      'type': type.text.trim(),
      'size': size.text.trim(),
      'phone': phone.text.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'responses': <Map<String, dynamic>>[],
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب للمحلات')));
    size.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('طلب قياس')),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            TextField(controller: type, decoration: const InputDecoration(labelText: 'النوع', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: size, decoration: const InputDecoration(labelText: 'القياس المطلوب', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            FilledButton(onPressed: _submit, child: const Text('إرسال للمحلات')),
          ]),
        ),
      );
}

class ShopSizeRequestsPage extends StatelessWidget {
  const ShopSizeRequestsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('طلبات القياسات')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('size_requests').where('status', isEqualTo: 'open').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              return ListView(padding: const EdgeInsets.all(16), children: snap.data!.docs.map((d) => Card(child: ListTile(
                title: Text('${d.data()['type'] ?? ''} ${d.data()['size'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${d.data()['phone'] ?? ''}'),
                trailing: FilledButton(onPressed: () async {
                  final shop = await ShopStore.load();
                  if (shop == null) return;
                  await d.reference.set({
                    'status': 'answered',
                    'answeredByShopId': shop.id,
                    'answeredByShopName': shop.name,
                    'answeredAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                }, child: const Text('متوفر')),
              ))).toList());
            },
          ),
        ),
      );
}

class RatingPage extends StatefulWidget {
  final String orderCode;
  final String shopId;
  final String shopName;

  const RatingPage({super.key, required this.orderCode, required this.shopId, required this.shopName});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int stars = 5;
  final comment = TextEditingController();

  Future<void> _save() async {
    await FirebaseFirestore.instance.collection('ratings').doc(widget.orderCode).set({
      'orderCode': widget.orderCode,
      'shopId': widget.shopId,
      'shopName': widget.shopName,
      'stars': stars,
      'comment': comment.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final snap = await FirebaseFirestore.instance.collection('ratings').where('shopId', isEqualTo: widget.shopId).get();
    if (snap.docs.isNotEmpty) {
      final avg = snap.docs.map((d) => (d.data()['stars'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / snap.docs.length;
      await FirebaseFirestore.instance.collection('shops').doc(widget.shopId).set({'rating': avg, 'ratingCount': snap.docs.length}, SetOptions(merge: true));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('تقييم ${widget.shopName}')),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Wrap(children: List.generate(5, (i) => IconButton(onPressed: () => setState(() => stars = i + 1), icon: Icon(i < stars ? Icons.star : Icons.star_border, size: 36, color: Colors.amber)))),
            TextField(controller: comment, maxLines: 4, decoration: const InputDecoration(labelText: 'تعليقك', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            FilledButton(onPressed: _save, child: const Text('إرسال التقييم')),
          ]),
        ),
      );
}

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<ShopProfile?>(
          future: ShopStore.loadForAuthenticatedOwner(),
          builder: (context, shopSnap) {
            if (shopSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final shop = shopSnap.data;
            if (shop == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'الإشعارات الخاصة بالطلبات تظهر بعد تسجيل دخول صاحب المحل.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('targetShopId', isEqualTo: shop.id)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('تعذر تحميل الإشعارات: ${snap.error}'),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs.toList()
                  ..sort(
                    (a, b) => _asDate(b.data()['createdAt'])
                        .compareTo(_asDate(a.data()['createdAt'])),
                  );
                if (docs.isEmpty) return const Center(child: Text('ماكو إشعارات'));
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: docs
                      .map(
                        (d) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications),
                            title: Text(
                              '${d.data()['title'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${d.data()['body'] ?? ''}'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
