import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'shop_store.dart';

const productionYellow = Color(0xFFFFD400);

class AppEnvironment {
  static const name = String.fromEnvironment('APP_ENV', defaultValue: 'production');
  static bool get isStaging => name.toLowerCase() == 'staging';
  static String get prefix => isStaging ? 'staging_' : '';
  static String collection(String base) => '$prefix$base';
}

class ProductionServices {
  static Future<void> init() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };

    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode);
    }

    final remote = FirebaseRemoteConfig.instance;
    await remote.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
    ));
    await remote.setDefaults({
      'smart_shop_distance_weight': 0.45,
      'smart_shop_rating_weight': 0.25,
      'smart_shop_availability_weight': 0.20,
      'smart_shop_speed_weight': 0.10,
      'appointments_enabled': true,
      'maintenance_banner_enabled': false,
    });
    try {
      await remote.fetchAndActivate();
    } catch (_) {}
  }
}

class ShopHoursPage extends StatefulWidget {
  const ShopHoursPage({super.key});

  @override
  State<ShopHoursPage> createState() => _ShopHoursPageState();
}

class _ShopHoursPageState extends State<ShopHoursPage> {
  final Map<int, bool> enabled = {for (var i = 1; i <= 7; i++) i: true};
  final Map<int, TimeOfDay> open = {for (var i = 1; i <= 7; i++) i: const TimeOfDay(hour: 8, minute: 0)};
  final Map<int, TimeOfDay> close = {for (var i = 1; i <= 7; i++) i: const TimeOfDay(hour: 20, minute: 0)};
  bool loading = true;
  ShopProfile? shop;

  static const dayNames = {
    1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس', 5: 'الجمعة', 6: 'السبت', 7: 'الأحد',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  TimeOfDay _parse(String value, TimeOfDay fallback) {
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? fallback.hour, minute: int.tryParse(parts[1]) ?? fallback.minute);
  }

  String _format(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final p = await ShopStore.load();
    shop = p;
    if (p != null) {
      final doc = await FirebaseFirestore.instance.collection(AppEnvironment.collection('shops')).doc(p.id).get();
      final hours = (doc.data()?['workingHours'] as Map?)?.cast<String, dynamic>();
      if (hours != null) {
        for (var i = 1; i <= 7; i++) {
          final d = (hours['$i'] as Map?)?.cast<String, dynamic>();
          if (d != null) {
            enabled[i] = d['enabled'] != false;
            open[i] = _parse('${d['open'] ?? '08:00'}', open[i]!);
            close[i] = _parse('${d['close'] ?? '20:00'}', close[i]!);
          }
        }
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _pick(int day, bool isOpen) async {
    final current = isOpen ? open[day]! : close[day]!;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) setState(() => isOpen ? open[day] = picked : close[day] = picked);
  }

  Future<void> _save() async {
    if (shop == null) return;
    final data = <String, dynamic>{};
    for (var i = 1; i <= 7; i++) {
      data['$i'] = {'enabled': enabled[i], 'open': _format(open[i]!), 'close': _format(close[i]!)};
    }
    await FirebaseFirestore.instance.collection(AppEnvironment.collection('shops')).doc(shop!.id).set({
      'workingHours': data,
      'workingHoursUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ ساعات العمل')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ساعات عمل المحل')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : shop == null
                ? const Center(child: Text('سجل دخول المحل أولاً'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...List.generate(7, (index) {
                        final day = index + 1;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(children: [
                              SwitchListTile(
                                value: enabled[day]!,
                                onChanged: (v) => setState(() => enabled[day] = v),
                                title: Text(dayNames[day]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(enabled[day]! ? 'مفتوح' : 'عطلة'),
                              ),
                              if (enabled[day]!)
                                Row(children: [
                                  Expanded(child: OutlinedButton(onPressed: () => _pick(day, true), child: Text('يفتح ${_format(open[day]!)}'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: OutlinedButton(onPressed: () => _pick(day, false), child: Text('يغلق ${_format(close[day]!)}'))),
                                ]),
                            ]),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('حفظ ساعات العمل')),
                    ],
                  ),
      ),
    );
  }
}

class SmartShopRankingPage extends StatefulWidget {
  const SmartShopRankingPage({super.key});

  @override
  State<SmartShopRankingPage> createState() => _SmartShopRankingPageState();
}

class _SmartShopRankingPageState extends State<SmartShopRankingPage> {
  bool loading = true;
  String? error;
  List<_RankedShop> shops = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('صلاحية الموقع مطلوبة');
      final pos = await Geolocator.getCurrentPosition();
      final snap = await FirebaseFirestore.instance.collection(AppEnvironment.collection('shops')).where('approved', isEqualTo: true).get();
      final remote = FirebaseRemoteConfig.instance;
      final dw = remote.getDouble('smart_shop_distance_weight');
      final rw = remote.getDouble('smart_shop_rating_weight');
      final aw = remote.getDouble('smart_shop_availability_weight');
      final sw = remote.getDouble('smart_shop_speed_weight');
      final result = <_RankedShop>[];
      for (final d in snap.docs) {
        final x = d.data();
        final lat = (x['latitude'] as num?)?.toDouble();
        final lng = (x['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final km = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng) / 1000.0;
        final rating = ((x['ratingAverage'] as num?)?.toDouble() ?? 0).clamp(0, 5);
        final availability = ((x['availabilityScore'] as num?)?.toDouble() ?? 0.5).clamp(0, 1);
        final speed = ((x['speedScore'] as num?)?.toDouble() ?? 0.5).clamp(0, 1);
        final distanceScore = 1 / (1 + km);
        final score = distanceScore * dw + (rating / 5) * rw + availability * aw + speed * sw;
        result.add(_RankedShop(id: d.id, name: '${x['name'] ?? ''}', km: km, rating: rating.toDouble(), score: score));
      }
      result.sort((a, b) => b.score.compareTo(a.score));
      if (mounted) setState(() { shops = result; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('أفضل المحلات إلك')),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text(error!))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: shops.length,
                        itemBuilder: (_, i) {
                          final s = shops[i];
                          return Card(
                            color: i == 0 ? productionYellow : null,
                            child: ListTile(
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${s.km.toStringAsFixed(1)} كم • تقييم ${s.rating.toStringAsFixed(1)}/5'),
                              trailing: Text('${(s.score * 100).toStringAsFixed(0)}%'),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      );
}

class _RankedShop {
  final String id;
  final String name;
  final double km;
  final double rating;
  final double score;
  const _RankedShop({required this.id, required this.name, required this.km, required this.rating, required this.score});
}

class ProductionStatusPage extends StatelessWidget {
  const ProductionStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rc = FirebaseRemoteConfig.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('حالة النظام')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(color: productionYellow, child: ListTile(leading: const Icon(Icons.cloud_done), title: Text('البيئة: ${AppEnvironment.name}'), subtitle: Text(AppEnvironment.isStaging ? 'بيانات الاختبار منفصلة عن الإنتاج' : 'بيئة الإنتاج'))),
            Card(child: ListTile(leading: const Icon(Icons.tune), title: const Text('Remote Config'), subtitle: Text('آخر جلب: ${rc.lastFetchTime}'))),
            const Card(child: ListTile(leading: Icon(Icons.bug_report), title: Text('Crashlytics'), subtitle: Text('تسجيل الأعطال مفعّل في نسخ الإنتاج'))),
            const Card(child: ListTile(leading: Icon(Icons.speed), title: Text('Performance Monitoring'), subtitle: Text('مراقبة الأداء مفعّلة في نسخ الإنتاج'))),
          ],
        ),
      ),
    );
  }
}
