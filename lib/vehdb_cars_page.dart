import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'legacy_main.dart' as legacy;

const _yellow = Color(0xFFFFD400);
const _vehDbBuildToken = String.fromEnvironment('VEHDB_TOKEN', defaultValue: '');

class VehDbTokenStore {
  static const _key = 'vehdb_api_token';

  static Future<String> resolve() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_key) ?? '').trim();
    if (saved.isNotEmpty) return saved;

    final buildToken = _vehDbBuildToken.trim();
    if (buildToken.isNotEmpty) {
      await prefs.setString(_key, buildToken);
      return buildToken;
    }

    throw Exception(
      'VehDB يحتاج تشغيل واحد فقط مع VEHDB_TOKEN حتى ينحفظ داخل الجهاز. بعدها ما راح يطلبه مرة ثانية.',
    );
  }
}

class _VehDbApi {
  static const base = 'https://api.vehdb.com/v1';

  Future<dynamic> get(String path) async {
    final token = await VehDbTokenStore.resolve();
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse('$base$path'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'VehDB HTTP ${response.statusCode}${body.isNotEmpty ? ': $body' : ''}',
        );
      }

      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }

  List<String> _strings(dynamic json) {
    final data = json is Map ? json['data'] : null;
    if (data is! List) return [];

    final out = <String>{};
    for (final item in data) {
      if (item is String) {
        final value = item.trim();
        if (value.isNotEmpty) out.add(value);
      } else if (item is Map) {
        final value = item['make'] ?? item['model'] ?? item['name'] ?? item['value'];
        if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty && text != 'null') out.add(text);
        }
      }
    }

    final list = out.toList()..sort();
    return list;
  }

  Future<List<String>> makes() => get('/tire-sizes/makes').then(_strings);

  Future<List<String>> models(String make) => get(
        '/tire-sizes/models?make=${Uri.encodeQueryComponent(make)}',
      ).then(_strings);

  Future<List<legacy.Car>> cars(String make, String model, int year) async {
    final json = await get(
      '/cars?make=${Uri.encodeQueryComponent(make)}'
      '&model=${Uri.encodeQueryComponent(model)}'
      '&year=$year',
    );

    final data = json is Map ? json['data'] : null;
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((item) => legacy.Car.from(item))
        .toList();
  }

  String _cleanSize(dynamic raw) {
    if (raw == null) return '';
    var s = raw.toString().trim().toUpperCase();
    if (s.isEmpty || s == 'NULL') return '';
    s = s.replaceAll(RegExp(r'\s+'), '');

    final match = RegExp(r'(\d{3})/(\d{2})R(\d{2})').firstMatch(s);
    if (match != null) {
      return '${match.group(1)}/${match.group(2)} R${match.group(3)}';
    }

    final slashMatch = RegExp(r'(\d{3})/(\d{2})/(\d{2})').firstMatch(s);
    if (slashMatch != null) {
      return '${slashMatch.group(1)}/${slashMatch.group(2)} R${slashMatch.group(3)}';
    }

    return raw.toString().trim();
  }

  void _addSize(Set<String> out, dynamic value) {
    if (value == null) return;
    if (value is List) {
      for (final item in value) {
        _addSize(out, item);
      }
      return;
    }
    if (value is Map) {
      for (final item in value.values) {
        _addSize(out, item);
      }
      return;
    }

    final text = value.toString().trim();
    if (text.contains(',') || text.contains(';')) {
      for (final part in text.split(RegExp(r'[,;]'))) {
        final cleaned = _cleanSize(part);
        if (cleaned.isNotEmpty) out.add(cleaned);
      }
      return;
    }

    final cleaned = _cleanSize(text);
    if (cleaned.isNotEmpty) out.add(cleaned);
  }

  void _collectSizes(dynamic node, Set<String> out) {
    if (node is Map) {
      for (final key in const [
        'tire_size_oem',
        'alternate_tire_sizes',
        'tire_size',
        'front_tire_size',
        'rear_tire_size',
      ]) {
        if (node.containsKey(key)) _addSize(out, node[key]);
      }
      for (final value in node.values) {
        if (value is Map || value is List) _collectSizes(value, out);
      }
    } else if (node is List) {
      for (final item in node) {
        _collectSizes(item, out);
      }
    }
  }

  Future<List<String>> sizes(legacy.Car car) async {
    final out = <String>{};

    if (car.id.trim().isNotEmpty) {
      try {
        final byCar = await get('/cars/${Uri.encodeComponent(car.id)}/tire-sizes');
        _collectSizes(byCar, out);
      } catch (_) {}
    }

    if (out.isEmpty) {
      final direct = await get(
        '/tire-sizes'
        '?make=${Uri.encodeQueryComponent(car.make)}'
        '&model=${Uri.encodeQueryComponent(car.model)}'
        '&year=${car.year}'
        '&per_page=100',
      );
      _collectSizes(direct, out);
    }

    final result = out.toList()..sort();
    return result;
  }
}

class VehDbCarsPage extends StatefulWidget {
  const VehDbCarsPage({super.key});

  @override
  State<VehDbCarsPage> createState() => _VehDbCarsPageState();
}

class _VehDbCarsPageState extends State<VehDbCarsPage> {
  final _api = _VehDbApi();

  String? make;
  String? model;
  int? year;
  List<String> makes = [];
  List<String> models = [];
  List<legacy.Car> cars = [];
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  Future<void> _loadMakes() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await _api.makes();
      if (!mounted) return;
      setState(() => makes = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _loadModels(String value) async {
    setState(() {
      make = value;
      model = null;
      year = null;
      models = [];
      cars = [];
      busy = true;
      error = null;
    });
    try {
      final result = await _api.models(value);
      if (!mounted) return;
      setState(() => models = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _searchCars() async {
    if (make == null || model == null || year == null) return;
    setState(() {
      busy = true;
      error = null;
      cars = [];
    });
    try {
      final result = await _api.cars(make!, model!, year!);
      if (!mounted) return;
      setState(() => cars = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openSizes(legacy.Car car) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await _api.sizes(car);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => legacy.SizesPage(car: car, sizes: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    final years = List.generate(40, (index) => DateTime.now().year - index);

    return Scaffold(
      appBar: AppBar(title: const Text('اختار سيارتك')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(Icons.directions_car, size: 80, color: _yellow),
            const SizedBox(height: 8),
            const Text(
              'اختار سيارتك حتى نطلع القياس المناسب',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            if (error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(error!),
                ),
              ),
            if (makes.isNotEmpty)
              DropdownButtonFormField<String>(
                value: make,
                isExpanded: true,
                decoration: _decoration('الشركة'),
                items: makes
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: busy ? null : (value) => value == null ? null : _loadModels(value),
              ),
            if (models.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: model,
                isExpanded: true,
                decoration: _decoration('الموديل'),
                items: models
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() {
                          model = value;
                          year = null;
                          cars = [];
                        }),
              ),
            ],
            if (model != null) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: year,
                isExpanded: true,
                decoration: _decoration('السنة'),
                items: years
                    .map((item) => DropdownMenuItem(value: item, child: Text('$item')))
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() {
                          year = value;
                          cars = [];
                        }),
              ),
            ],
            const SizedBox(height: 16),
            if (make != null && model != null && year != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: busy ? null : _searchCars,
                child: const Text('بحث عن السيارة والفئة', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ...cars.map(
              (car) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                  title: Text(
                    car.trim.isEmpty ? '${car.make} ${car.model}' : car.trim,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${car.make} ${car.model} • ${car.year}'),
                  trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                  onTap: busy ? null : () => _openSizes(car),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
