import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import 'app_core.dart' as legacy;
import 'vehicle_catalog.dart';

const _yellow = Color(0xFFFFD400);

class _VehDbApi {
  static const String base =
      'https://auto-deals-vehdb.mohanedmmm51.workers.dev';

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$base$path'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('خدمة السيارات HTTP ${response.statusCode}');
    }
    final body = utf8.decode(response.bodyBytes);
    if (body.trim().isEmpty) return {};
    return jsonDecode(body);
  }

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

  bool _looksLikeSize(String text) {
    final clean = text.toUpperCase().replaceAll(' ', '');
    return RegExp(r'\d{3}/\d{2}R?\d{2}').hasMatch(clean);
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
    if (text.isEmpty) return;

    final matches = RegExp(r'\d{3}\s*/\s*\d{2}\s*[Rr/]?\s*\d{2}').allMatches(text);
    if (matches.isNotEmpty) {
      for (final match in matches) {
        final cleaned = _cleanSize(match.group(0));
        if (cleaned.isNotEmpty) out.add(cleaned);
      }
      return;
    }

    final cleaned = _cleanSize(text);
    if (_looksLikeSize(cleaned)) out.add(cleaned);
  }

  void _collectSizes(dynamic node, Set<String> out) {
    if (node is Map) {
      for (final key in const [
        'tire_size_oem',
        'alternate_tire_sizes',
        'tire_size',
        'tire_sizes',
        'front_tire_size',
        'rear_tire_size',
        'front_tires',
        'rear_tires',
        'tires',
        'size',
        'sizes',
      ]) {
        if (node.containsKey(key)) _addSize(out, node[key]);
      }
      for (final entry in node.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = entry.value;
        if (key.contains('tire') || key.contains('tyre')) {
          _addSize(out, value);
        }
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
    final attemptedIds = <String>{};

    if (car.id.trim().isNotEmpty) {
      attemptedIds.add(car.id.trim());
      try {
        final byCar = await get('/car-sizes/${Uri.encodeComponent(car.id)}');
        _collectSizes(byCar, out);
      } catch (_) {}
    }

    if (out.isEmpty) {
      // Some VehDB car records do not have a matching tire-size record even
      // though another trim for the same make/model/year does. The old
      // /sizes fallback currently returns HTTP 422, so resolve the sibling
      // car records and try their UUIDs instead.
      final siblings = await cars(car.make, car.model, car.year);
      for (final sibling in siblings) {
        final id = sibling.id.trim();
        if (id.isEmpty || !attemptedIds.add(id)) continue;

        try {
          final bySibling = await get('/car-sizes/${Uri.encodeComponent(id)}');
          _collectSizes(bySibling, out);
        } catch (_) {}

        if (out.isNotEmpty) break;
      }
    }

    return out.toList()..sort();
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
  final List<String> makes = vehicleCatalog.keys.toList()..sort();
  List<String> models = [];
  List<legacy.Car> cars = [];
  bool busy = false;
  String? error;

  String _friendlyError(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    if (text.contains('401')) {
      return 'خدمة السيارات غير مفعلة على السيرفر.';
    }
    if (text.contains('404')) {
      return 'خدمة السيارات غير متاحة حاليًا.';
    }
    return 'تعذّر جلب بيانات السيارات. تحقق من الاتصال وحاول مرة ثانية.';
  }

  void _loadModels(String value) {
    setState(() {
      make = value;
      model = null;
      year = null;
      models = List<String>.of(vehicleCatalog[value] ?? const [])..sort();
      cars = [];
      error = null;
    });
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
      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ما لكينا سيارة مطابقة لهذا الاختيار.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => error = _friendlyError(e));
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
      if (result.isEmpty) {
        setState(() => error = 'ما حصلنا قياس إطار لهذه السيارة.');
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => legacy.SizesPage(car: car, sizes: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => error = _friendlyError(e));
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
    final years = List.generate(50, (index) => DateTime.now().year - index);

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
                  child: Column(
                    children: [
                      Text(error!),
                    ],
                  ),
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
                key: ValueKey(make),
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
                key: ValueKey('$make/$model'),
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
                child: const Text(
                  'بحث عن السيارة والفئة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
