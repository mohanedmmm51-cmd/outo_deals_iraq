part of '../app_core.dart';

const yellow = Color(0xFFFFD400);
const vehDbToken = String.fromEnvironment('VEHDB_TOKEN', defaultValue: '');

String money(int n) => n.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

class Tire {
  final String size;
  final int wholesale;

  const Tire(this.size, this.wholesale);

  int get profit => wholesale < 150000
      ? 10000
      : wholesale < 200000
      ? 12000
      : 15000;

  int get commission => wholesale < 100000
      ? 3000
      : wholesale < 150000
      ? 4000
      : 5000;

  int get price => wholesale + profit + commission;
}

const tires = [
  Tire('500/12', 67320),
  Tire('550/12', 104040),
  Tire('550/13', 87210),
  Tire('165/65/13', 73440),
  Tire('175/70/13', 73440),
  Tire('175/70/14', 68850),
  Tire('185/65/14', 76500),
  Tire('185/70/14', 87210),
  Tire('195/70/14', 88740),
  Tire('195/14', 126990),
  Tire('185/14', 104040),
  Tire('205/75/14 خط', 119340),
  Tire('195/65/15', 84150),
  Tire('195/65/15 كومفورس', 91800),
  Tire('195/65/15 هلو', 96390),
  Tire('205/65/15', 104040),
  Tire('205/70/15', 99450),
  Tire('205/70/15 خط', 114750),
  Tire('215/75/15', 114750),
  Tire('195/55/15', 81090),
  Tire('195/60/15', 81090),
  Tire('185/65/15', 81090),
  Tire('185/55/15', 81090),
  Tire('195/15', 128520),
  Tire('195/55/16', 91800),
  Tire('205/55/16 كومفورس', 102510),
  Tire('205/55/16 هلو', 111690),
  Tire('205/55/16', 99450),
  Tire('215/60/16', 110160),
];

class Battery {
  final String brand;
  final String amp;
  final int wholesale;

  const Battery(this.brand, this.amp, this.wholesale);

  int get withOld => wholesale + 3000;
  int get withoutOld => wholesale + 10000 + 3000;
}

const batteries = [
  Battery('انجيكو كوري', '43 مربع', 61200),
  Battery('انجيكو كوري', '62', 76500),
  Battery('انجيكو كوري', '70 عالي', 84150),
  Battery('انجيكو كوري', '74', 87210),
  Battery('انجيكو كوري', '80 ناصي', 107100),
  Battery('انجيكو كوري', '88', 107100),
  Battery('انجيكو كوري', '90', 99450),
  Battery('انجيكو كوري', '100 مستطيل', 114750),
  Battery('انجيكو كوري', '150', 175950),
  Battery('ماليزي', '62', 61200),
  Battery('ماليزي', '70 عالي', 68850),
  Battery('ماليزي', '74', 76500),
  Battery('ماليزي', '80', 81090),
  Battery('ماليزي', '88', 81090),
  Battery('ماليزي', '90', 81090),
  Battery('ماليزي', '100 مستطيل', 84150),
  Battery('ماليزي', '100 مربع', 111690),
  Battery('ماليزي', '150', 134640),
  Battery('زكستور عراقي', '62', 44370),
  Battery('زكستور عراقي', '70', 58140),
  Battery('زكستور عراقي', '74', 58140),
];

class Api {
  static const base = 'https://api.vehdb.com/v1';

  Future<dynamic> get(String path) async {
    if (vehDbToken.trim().isEmpty) {
      throw Exception('VehDB غير مهيأ. شغّل التطبيق مع VEHDB_TOKEN.');
    }

    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse('$base$path'));
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${vehDbToken.trim()}',
      );
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

  List<String> strings(dynamic json) {
    final data = json is Map ? json['data'] : null;
    if (data is! List) return [];

    final out = <String>{};

    for (final item in data) {
      if (item is String) {
        final value = item.trim();
        if (value.isNotEmpty) out.add(value);
      } else if (item is Map) {
        final value =
            item['make'] ?? item['model'] ?? item['name'] ?? item['value'];

        if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty && text != 'null') {
            out.add(text);
          }
        }
      }
    }

    final list = out.toList();
    list.sort();
    return list;
  }

  Future<List<String>> makes() {
    return get('/tire-sizes/makes').then(strings);
  }

  Future<List<String>> models(String make) {
    return get('/tire-sizes/models?make=${Uri.encodeQueryComponent(make)}')
        .then(strings);
  }

  Future<List<Car>> cars(String make, String model, int year) async {
    final json = await get(
      '/cars?make=${Uri.encodeQueryComponent(make)}'
      '&model=${Uri.encodeQueryComponent(model)}'
      '&year=$year',
    );

    final data = json is Map ? json['data'] : null;
    if (data is! List) return [];

    final result = <Car>[];

    for (final item in data) {
      if (item is Map) {
        result.add(Car.from(item));
      }
    }

    return result;
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
      if (node.containsKey('tire_size_oem')) {
        _addSize(out, node['tire_size_oem']);
      }

      if (node.containsKey('alternate_tire_sizes')) {
        _addSize(out, node['alternate_tire_sizes']);
      }

      if (node.containsKey('tire_size')) {
        _addSize(out, node['tire_size']);
      }

      if (node.containsKey('front_tire_size')) {
        _addSize(out, node['front_tire_size']);
      }

      if (node.containsKey('rear_tire_size')) {
        _addSize(out, node['rear_tire_size']);
      }

      for (final value in node.values) {
        if (value is Map || value is List) {
          _collectSizes(value, out);
        }
      }
    } else if (node is List) {
      for (final item in node) {
        _collectSizes(item, out);
      }
    }
  }

  /// الإصلاح الرئيسي:
  /// 1) نحاول endpoint الخاص بالسيارة UUID.
  /// 2) إذا لم يرجع قياس، نحاول tire-sizes مباشرة حسب
  ///    make + model + year.
  /// 3) نقرأ OEM والبدائل حتى لو شكل JSON مختلف قليلاً.
  Future<List<String>> sizes({required Car car}) async {
    final out = <String>{};

    if (car.id.trim().isNotEmpty) {
      try {
        final byCar = await get(
          '/cars/${Uri.encodeComponent(car.id)}/tire-sizes',
        );
        _collectSizes(byCar, out);
      } catch (_) {
        // نكمل للمسار البديل أدناه.
      }
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

    final result = out.toList();
    result.sort();
    return result;
  }
}

class Car {
  final String id;
  final String make;
  final String model;
  final int year;
  final String trim;

  const Car(this.id, this.make, this.model, this.year, this.trim);

  factory Car.from(Map item) {
    return Car(
      '${item['uuid'] ?? item['id'] ?? ''}',
      '${item['make'] ?? ''}',
      '${item['model'] ?? ''}',
      (item['year'] as num?)?.toInt() ??
          int.tryParse('${item['year'] ?? ''}') ??
          0,
      '${item['trim'] ?? item['submodel'] ?? item['variant'] ?? ''}',
    );
  }
}

String newOrderCode() {
  final now = DateTime.now().millisecondsSinceEpoch.toString();
  return 'ADI-${now.substring(now.length - 8)}';
}
