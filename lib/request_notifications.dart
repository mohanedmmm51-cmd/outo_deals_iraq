import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'request_push_stub.dart' if (dart.library.js_interop) 'request_push_web.dart';

class RequestPushService {
  static StreamSubscription<String>? _refresh;
  static String? _token;
  static String? _uid;

  static DocumentReference<Map<String, dynamic>> _ref(String uid, String token) =>
      FirebaseFirestore.instance.collection('push_devices').doc(uid)
        .collection('tokens').doc(base64Url.encode(utf8.encode(token)));

  static Future<void> _save(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('سجل الدخول أولاً');
    if (_token != null && _uid == uid && _token != token) {
      await _ref(uid, _token!).delete();
    }
    await _ref(uid, token).set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
    _uid = uid; _token = token;
  }

  static Future<void> _relay(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('سجل الدخول أولاً');
    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse('https://auto-deals-push.mohanedmmm51.chatgpt.site/api/push'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 25));
    if (data['action'] == 'notify' && response.statusCode == 409) return; // Expired retry.
    if (response.statusCode != 200) throw StateError('push_${response.statusCode}');
  }

  static Future<void> test() async {
    final data = await currentWebPush();
    if (data == null) throw StateError('فعّل الإشعارات أولاً');
    await _relay({'action': 'test', 'endpoint': (data['subscription'] as Map)['endpoint']});
  }

  // A failed push never rolls back a saved request/reply. Persist only IDs and
  // retry on the next signed-in session; the relay suppresses duplicate sends.
  static Future<bool> notify(String id, String event) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;
      final prefs = await SharedPreferences.getInstance();
      final key = 'request_push_outbox_$uid';
      final entry = '$event:$id';
      final entries = prefs.getStringList(key) ?? [];
      if (!entries.contains(entry)) await prefs.setStringList(key, [...entries, entry]);
      await _relay({'action': 'notify', 'requestId': id, 'event': event});
      final pending = prefs.getStringList(key) ?? [];
      await prefs.setStringList(key, pending.where((e) => e != entry).toList());
      return true;
    } catch (_) { return false; }
  }

  static Future<void> retryPending() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList('request_push_outbox_$uid') ?? [];
    for (final entry in entries.take(10)) {
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      final parts = entry.split(':');
      if (parts.length == 2 && !await notify(parts[1], parts[0])) return;
    }
  }

  // Restore an existing subscription without showing a permission prompt again.
  static Future<bool> restore() async {
    if (FirebaseAuth.instance.currentUser == null) return false;
    if (kIsWeb) {
      final data = await currentWebPush();
      if (data == null) return false;
      await _relay({'action': 'subscribe', 'subscription': data['subscription']});
      return true;
    }
    if (!await FirebaseMessaging.instance.isSupported()) return false;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<void> enable() async {
    if (kIsWeb) {
      final data = await enableWebPush();
      await _relay({'action': 'subscribe', 'subscription': data['subscription']});
      return;
    }
    if (!await FirebaseMessaging.instance.isSupported()) throw StateError('unsupported');
    final result = await FirebaseMessaging.instance.requestPermission();
    if (result.authorizationStatus != AuthorizationStatus.authorized && result.authorizationStatus != AuthorizationStatus.provisional) {
      throw StateError('permission denied');
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) throw StateError('missing token');
    await _save(token);
    await _refresh?.cancel();
    _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _save(token).catchError((Object e) { debugPrint('Push token refresh failed: $e'); });
    });
  }

  static Future<void> detach() async {
    await _refresh?.cancel(); _refresh = null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (kIsWeb) {
      final data = await currentWebPush();
      try {
        if (uid != null && data != null) {
          await _relay({'action': 'unsubscribe', 'endpoint': (data['subscription'] as Map)['endpoint']});
        }
      } finally { await disableWebPush(); }
      return;
    }
    // Also remove a token restored by the SDK after a page reload.
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = _token ?? await FirebaseMessaging.instance.getToken();
        if (uid != null && token != null) await _ref(uid, token).delete();
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) { /* Unsupported browsers have no push registration. */ }
    _uid = null; _token = null;
  }
}

class RequestNotificationButton extends StatefulWidget {
  const RequestNotificationButton({super.key});
  @override
  State<RequestNotificationButton> createState() => _RequestNotificationButtonState();
}

class _RequestNotificationButtonState extends State<RequestNotificationButton> {
  bool busy = false;
  bool enabled = false;
  String? error;
  @override
  void initState() {
    super.initState();
    busy = true;
    RequestPushService.restore().then((value) {
      if (mounted) setState(() => enabled = value);
    }).catchError((Object _) {
      // A transient relay failure must not interrupt requests or trigger a new prompt.
    }).whenComplete(() { if (mounted) setState(() => busy = false); });
  }
  Future<void> enable() async {
    setState(() { busy = true; error = null; });
    try {
      await RequestPushService.enable();
      if (mounted) setState(() => enabled = true);
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر تفعيل إشعارات الجهاز حالياً. تابع الطلبات والردود داخل الموقع. تأكد من السماح بالإشعارات؛ وعلى الآيفون افتح الموقع من أيقونته على الشاشة الرئيسية.');
    } finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> testPush() async {
    setState(() { busy = true; error = null; });
    try {
      await RequestPushService.test();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال إشعار تجريبي؛ تحقق من هاتفك')));
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر إرسال الإشعار التجريبي. حاول تفعيل الإشعارات مرة ثانية.');
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    OutlinedButton.icon(onPressed: busy || enabled ? null : enable,
      icon: Icon(enabled ? Icons.notifications_active : Icons.notifications_outlined),
      label: Text(busy ? 'جاري التحقق...'  : enabled ? 'إشعارات هذا الجهاز مفعّلة' : 'تفعيل إشعارات الطلبات على هذا الجهاز')),
    if (enabled && kIsWeb) TextButton.icon(onPressed: busy ? null : testPush, icon: const Icon(Icons.send), label: const Text('تجربة إشعار')),
    if (error != null) Padding(padding: const EdgeInsets.all(8), child: Text(error!, style: const TextStyle(color: Colors.red))),
  ]);
}

/// In-app alerts work while the home/dashboard is open even without push permission.
class RequestAlerts extends StatefulWidget {
  const RequestAlerts({super.key, required this.child});
  final Widget child;
  @override
  State<RequestAlerts> createState() => _RequestAlertsState();
}

class _RequestAlertsState extends State<RequestAlerts> {
  StreamSubscription<User?>? auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? requests;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    auth = FirebaseAuth.instance.authStateChanges().listen(watch);
  }
  Future<void> watch(User? user) async {
    final current = ++generation;
    await requests?.cancel(); requests = null;
    if (user == null) return;
    unawaited(RequestPushService.retryPending().catchError((Object _) {}));
    try {
      final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted || current != generation) return;
      final d = profile.data();
      final admin = d?['role'] == 'admin' || d?['isAdmin'] == true;
      final collection = FirebaseFirestore.instance.collection('product_requests');
      final Query<Map<String, dynamic>> query = admin ? collection : collection.where('customerUid', isEqualTo: user.uid);
      bool first = true;
      requests = query.snapshots().listen((snap) {
        if (first) { first = false; return; }
        for (final change in snap.docChanges) {
          final data = change.doc.data()!;
          if ((admin && change.type == DocumentChangeType.added) ||
              (!admin && change.type == DocumentChangeType.modified && data['status'] == 'answered')) {
            if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
              content: Text(admin ? 'طلب جديد: ${data['size']}' : 'وصلك رد الإدارة على طلب ${data['size']}'),
            ));
          }
        }
      }, onError: (Object e) { debugPrint('Request alerts unavailable: $e'); });
    } catch (e) { debugPrint('Request alerts unavailable: $e'); }
  }
  @override
  void dispose() { generation++; auth?.cancel(); requests?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => widget.child;
}
