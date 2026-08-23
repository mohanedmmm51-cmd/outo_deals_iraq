import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const App());

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
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

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
    return get(
      '/tire-sizes/models?make=${Uri.encodeQueryComponent(make)}',
    ).then(strings);
  }

  Future<List<Car>> cars(
    String make,
    String model,
    int year,
  ) async {
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

    final slashMatch =
        RegExp(r'(\d{3})/(\d{2})/(\d{2})').firstMatch(s);
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
  Future<List<String>> sizes({
    required Car car,
  }) async {
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

  const Car(
    this.id,
    this.make,
    this.model,
    this.year,
    this.trim,
  );

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

class OrderCodePage extends StatelessWidget {
  final String title;
  final String detail;
  final int price;

  const OrderCodePage({
    super.key,
    required this.title,
    required this.detail,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final code = newOrderCode();

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              color: yellow,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(detail),
                    const SizedBox(height: 8),
                    Text(
                      'السعر النهائي: ${money(price)} د.ع',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'كود الطلب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: code,
                width: 190,
                height: 190,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: code,
                width: 290,
                height: 90,
                drawText: true,
              ),
            ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'خلي هذا الكود وياك. من توصل للمحل، صاحب المحل يستلم الكود أو يمسح الـQR قبل تنفيذ الطلب.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    const offers = [
      ('عرض الإطارات', 'خصومات على قياسات مختارة حسب المخزون.'),
      ('تركيب وبلنص', 'خدمات إضافية مجانية مع بعض العروض.'),
      ('عرض نهاية الأسبوع', 'أسعار خاصة لفترة محدودة.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('العروض والخصومات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'العروض الحالية',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...offers.map(
              (offer) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: yellow,
                    child: Icon(Icons.local_offer),
                  ),
                  title: Text(
                    offer.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(offer.$2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const supportPhone =
      String.fromEnvironment('SUPPORT_PHONE', defaultValue: '');

  Future<void> callSupport(BuildContext context) async {
    if (supportPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رقم الدعم بعده غير مضاف. نضيفه من تحدد رقم خدمة العملاء.',
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$supportPhone');

    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الاتصال')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التواصل مع الدعم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.support_agent,
              size: 90,
              color: yellow,
            ),
            const SizedBox(height: 14),
            const Text(
              'شلون نكدر نساعدك؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('اتصل بالدعم'),
                subtitle: Text(
                  supportPhone.isEmpty
                      ? 'رقم الدعم نضيفه لاحقًا'
                      : supportPhone,
                ),
                onTap: () => callSupport(context),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('الدفع الإلكتروني وواتساب'),
                subtitle: Text(
                  'هذني مؤجلين للمرحلة الجاية وما داخلين بهذه النسخة.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Shop {
  final String name;
  final double lat;
  final double lng;

  const Shop(this.name, this.lat, this.lng);
}

class AddShopPage extends StatefulWidget {
  const AddShopPage({super.key});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  static const _storageKey = 'pending_shop_request';

  final _formKey = GlobalKey<FormState>();
  final _shopName = TextEditingController();
  final _phone = TextEditingController();
  Position? _position;
  bool _locating = false;
  bool _saving = false;
  String? _locationError;

  @override
  void dispose() {
    _shopName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _locateShop() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('فعّل خدمة الموقع GPS أولاً.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض صلاحية الموقع.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'صلاحية الموقع مرفوضة نهائيًا. فعّلها من إعدادات التطبيق.',
        );
      }

      final result = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() => _position = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_position == null) {
      setState(() => _locationError = 'حدد موقع المحل قبل إرسال الطلب.');
      return;
    }

    setState(() => _saving = true);
    final request = {
      'shopName': _shopName.text.trim(),
      'phone': _phone.text.trim(),
      'latitude': _position!.latitude,
      'longitude': _position!.longitude,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    };

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, jsonEncode(request));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تم حفظ الطلب'),
          content: const Text(
            'انحفظ طلب انضمام المحل مؤقتًا داخل الجهاز، وحالته قيد المراجعة.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ الطلب. حاول مرة ثانية.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة محل')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.add_business, size: 72, color: Color(0xff111111)),
              const SizedBox(height: 10),
              const Text(
                'طلب انضمام صاحب محل',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'دخل معلومات محلك وحدد موقعه وأرسل الطلب.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _shopName,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'اسم المحل',
                  prefixIcon: Icon(Icons.storefront),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب اسم المحل'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '07XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final phone = value?.replaceAll(RegExp(r'\s+'), '') ?? '';
                  return RegExp(r'^07\d{9}$').hasMatch(phone)
                      ? null
                      : 'اكتب رقم عراقي صحيح من 11 رقم';
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _locating ? null : _locateShop,
                icon: _locating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _position == null ? Icons.my_location : Icons.check_circle,
                      ),
                label: Text(
                  _position == null ? 'تحديد موقع المحل GPS' : 'تم تحديد موقع المحل',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_position != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'الموقع: ${_position!.latitude.toStringAsFixed(6)}, '
                    '${_position!.longitude.toStringAsFixed(6)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              if (_locationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _locationError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _saveRequest,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('إرسال طلب الانضمام'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff111111),
                  foregroundColor: yellow,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NearbyShopsPage extends StatefulWidget {
  const NearbyShopsPage({super.key});

  @override
  State<NearbyShopsPage> createState() => _NearbyShopsPageState();
}

class _NearbyShopsPageState extends State<NearbyShopsPage> {
  // إحداثيات نموذجية فقط إلى أن نربط قاعدة بيانات المحلات الحقيقية.
  final shops = const [
    Shop('محل الكرادة', 33.3056, 44.4328),
    Shop('محل المنصور', 33.3152, 44.3363),
    Shop('محل زيونة', 33.3242, 44.4641),
  ];

  Position? position;
  bool busy = false;
  String? error;

  Future<void> locateMe() async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception('فعّل خدمة الموقع GPS أولاً.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض صلاحية الموقع.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'صلاحية الموقع مرفوضة نهائيًا. افتح إعدادات التطبيق وفعّل الموقع.',
        );
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        position = current;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  double distanceKm(Shop shop) {
    if (position == null) return double.infinity;

    return Geolocator.distanceBetween(
          position!.latitude,
          position!.longitude,
          shop.lat,
          shop.lng,
        ) /
        1000;
  }

  Future<void> openDirections(Shop shop) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${shop.lat},${shop.lng}',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الخرائط'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...shops];

    if (position != null) {
      sorted.sort(
        (a, b) => distanceKm(a).compareTo(distanceKm(b)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المحلات القريبة')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: busy ? null : locateMe,
              icon: const Icon(Icons.my_location),
              label: const Text('حدد موقعي'),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(error!),
                ),
              ),
            const SizedBox(height: 10),
            if (position != null)
              const Text(
                'مرتبة حسب الأقرب إليك',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            ...sorted.map(
              (shop) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: yellow,
                    child: Icon(Icons.store),
                  ),
                  title: Text(
                    shop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    position == null
                        ? 'حدد موقعك حتى نحسب المسافة'
                        : '${distanceKm(shop).toStringAsFixed(1)} كم',
                  ),
                  trailing: IconButton(
                    tooltip: 'الاتجاهات',
                    icon: const Icon(Icons.directions),
                    onPressed: () => openDirections(shop),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ملاحظة: المحلات الحالية تجريبية. من نضيف قاعدة بيانات المحلات نستبدلها بالمحلات الحقيقية.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إطارات وبطاريات العراق',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: yellow),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xff111111),
        selectedItemColor: yellow,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'المحلات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'السلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'طلباتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                decoration: const BoxDecoration(
                  color: Color(0xff101010),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 30,
                        ),
                        Spacer(),
                        Column(
                          children: [
                            Text(
                              'إطارات وبطاريات العراق',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'الجودة .. بأقرب محل',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                    SizedBox(height: 22),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                      child: SizedBox(
                        height: 54,
                        child: Row(
                          children: [
                            SizedBox(width: 16),
                            Icon(Icons.search, size: 30),
                            SizedBox(width: 10),
                            Text(
                              'شنو تحتاج؟ إطارات أو بطاريات...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    button(
                      context,
                      Icons.directions_car,
                      'اختار سيارتك',
                      'اعرف قياس الإطار المناسب لسيارتك',
                      yellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CarsPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: cat(
                            context,
                            Icons.tire_repair,
                            'الإطارات',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TiresPage(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: cat(
                            context,
                            Icons.battery_charging_full,
                            'البطاريات',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BatteriesPage(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.location_on,
                      'المحلات القريبة',
                      'المسافة + الأقرب + الاتجاهات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NearbyShopsPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.add_business,
                      'إضافة محل',
                      'طلب انضمام لأصحاب المحلات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddShopPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.local_offer,
                      'العروض والخصومات',
                      'شوف أحدث العروض المتوفرة',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OffersPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    button(
                      context,
                      Icons.support_agent,
                      'التواصل مع الدعم',
                      'مساعدة واستفسارات',
                      Colors.white,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SupportPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget button(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 45, color: Colors.black),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  static Widget cat(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xff171717),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: yellow,
              size: 52,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  final Api api = Api();

  String? make;
  String? model;
  int? year;

  List<String> makes = [];
  List<String> models = [];
  List<Car> cars = [];

  bool busy = false;
  String? err;

  @override
  void initState() {
    super.initState();
    loadMakes();
  }

  Future<void> loadMakes() async {
    setState(() {
      busy = true;
      err = null;
    });

    try {
      final result = await api.makes();

      if (!mounted) return;

      setState(() {
        makes = result;
        make = null;
        model = null;
        year = null;
        models = [];
        cars = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        err = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> loadModels(String value) async {
    setState(() {
      make = value;
      model = null;
      year = null;
      models = [];
      cars = [];
      busy = true;
      err = null;
    });

    try {
      final result = await api.models(value);

      if (!mounted) return;

      setState(() {
        models = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        err = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> searchCars() async {
    if (make == null || model == null || year == null) return;

    setState(() {
      busy = true;
      err = null;
      cars = [];
    });

    try {
      final result = await api.cars(
        make!,
        model!,
        year!,
      );

      if (!mounted) return;

      setState(() {
        cars = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        err = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Future<void> openSizes(Car car) async {
    setState(() {
      busy = true;
      err = null;
    });

    try {
      final result = await api.sizes(
        car: car,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SizesPage(
            car: car,
            sizes: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        err = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      30,
      (index) => 2026 - index,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختار سيارتك'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.directions_car,
              size: 80,
              color: yellow,
            ),
            const SizedBox(height: 8),
            const Text(
              'اختار سيارتك حتى نطلع القياس المناسب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            if (busy && makes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (err != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('خطأ: $err'),
                ),
              ),
            if (makes.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: make,
                isExpanded: true,
                decoration: fieldDecoration('الشركة'),
                items: makes
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) {
                          loadModels(value);
                        }
                      },
              ),
            ],
            if (models.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: model,
                isExpanded: true,
                decoration: fieldDecoration('الموديل'),
                items: models
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        setState(() {
                          model = value;
                          year = null;
                          cars = [];
                        });
                      },
              ),
            ],
            if (model != null) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: year,
                isExpanded: true,
                decoration: fieldDecoration('السنة'),
                items: years
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item,
                        child: Text('$item'),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        setState(() {
                          year = value;
                          cars = [];
                        });
                      },
              ),
            ],
            const SizedBox(height: 16),
            if (make != null && model != null && year != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: busy ? null : searchCars,
                child: const Text(
                  'بحث عن السيارة والفئة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (busy && makes.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ...cars.map(
              (car) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.directions_car),
                    ),
                    title: Text(
                      car.trim.isEmpty
                          ? '${car.make} ${car.model}'
                          : car.trim,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${car.make} ${car.model} • ${car.year}',
                    ),
                    trailing: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                    ),
                    onTap: busy ? null : () => openSizes(car),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SizesPage extends StatelessWidget {
  final Car car;
  final List<String> sizes;

  const SizesPage({
    super.key,
    required this.car,
    required this.sizes,
  });

  String normalize(String value) {
    return value
        .toUpperCase()
        .replaceAll(RegExp(r'[^0-9]'), '');
  }

  String localBaseSize(String value) {
    return value
        .replaceAll('كومفورس', '')
        .replaceAll('هلو', '')
        .replaceAll('خط', '')
        .trim();
  }

  List<Tire> matchingTires(String remoteSize) {
    final normalizedRemote = normalize(remoteSize);

    if (normalizedRemote.isEmpty) return [];

    return tires.where((tire) {
      final normalizedLocal = normalize(localBaseSize(tire.size));
      return normalizedLocal == normalizedRemote;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قياسات السيارة'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: yellow,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.make} ${car.model}',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      car.trim.isEmpty
                          ? '${car.year}'
                          : '${car.year} • ${car.trim}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'القياسات المناسبة',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (sizes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'VehDB لم يرجع قياسات لهذه الفئة. جرّب فئة أخرى من نفس السيارة.',
                  ),
                ),
              ),
            ...sizes.map(
              (size) {
                final matches = matchingTires(size);

                final subtitle = matches.isEmpty
                    ? 'القياس موجود في VehDB، لكن لا يوجد سعر مطابق في قائمتنا حاليًا'
                    : matches.length == 1
                        ? 'اضغط لعرض السعر: ${money(matches.first.price)} د.ع'
                        : 'اضغط لعرض ${matches.length} خيارات وأسعار';

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.tire_repair,
                      size: 34,
                    ),
                    title: Text(
                      size,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(subtitle),
                    trailing: matches.isEmpty
                        ? null
                        : const Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                          ),
                    onTap: matches.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TirePricesPage(
                                  car: car,
                                  vehDbSize: size,
                                  matching: matches,
                                ),
                              ),
                            );
                          },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TirePricesPage extends StatelessWidget {
  final Car car;
  final String vehDbSize;
  final List<Tire> matching;

  const TirePricesPage({
    super.key,
    required this.car,
    required this.vehDbSize,
    required this.matching,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسعار الإطارات'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: yellow,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.make} ${car.model} ${car.year}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'قياس السيارة: $vehDbSize',
                      style: const TextStyle(fontSize: 17),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'الخيارات المتوفرة',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...matching.map(
              (tire) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.tire_repair,
                          size: 34,
                        ),
                        title: Text(
                          tire.size,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'السعر النهائي للزبون',
                        ),
                        trailing: Text(
                          '${money(tire.price)} د.ع',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderCodePage(
                                title: tire.size,
                                detail:
                                    '${car.make} ${car.model} ${car.year}',
                                price: tire.price,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('اطلب الآن'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TiresPage extends StatelessWidget {
  const TiresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإطارات'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tires.length,
          itemBuilder: (context, index) {
            final tire = tires[index];

            return Card(
              child: ListTile(
                leading: const Icon(Icons.tire_repair),
                title: Text(
                  tire.size,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'السعر النهائي: ${money(tire.price)} د.ع',
                ),
                trailing: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TireDetailsPage(
                        tire: tire,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class TireDetailsPage extends StatelessWidget {
  final Tire tire;

  const TireDetailsPage({
    super.key,
    required this.tire,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الإطار'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              color: yellow,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.tire_repair,
                      size: 80,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tire.size,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'السعر النهائي للزبون',
                    ),
                    Text(
                      '${money(tire.price)} د.ع',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Card(
              child: ListTile(
                leading: Icon(Icons.verified_outlined),
                title: Text('السعر مضمون داخل التطبيق'),
                subtitle: Text(
                  'السعر المعروض هو السعر النهائي قبل الذهاب إلى المحل.',
                ),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.build_outlined),
                title: Text('الخدمات'),
                subtitle: Text(
                  'تفاصيل التركيب والبلنص تظهر حسب عرض المحل.',
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderCodePage(
                      title: tire.size,
                      detail: 'طلب إطار من قائمة الأسعار',
                      price: tire.price,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text(
                'اطلب الآن',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BatteriesPage extends StatelessWidget {
  const BatteriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البطاريات'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: batteries.length,
          itemBuilder: (context, index) {
            final battery = batteries[index];

            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.battery_charging_full,
                ),
                title: Text(
                  '${battery.brand} ${battery.amp}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'اختيار البطارية القديمة',
                ),
                trailing: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatteryPage(
                        b: battery,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class BatteryPage extends StatefulWidget {
  final Battery b;

  const BatteryPage({
    super.key,
    required this.b,
  });

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  bool old = true;

  @override
  Widget build(BuildContext context) {
    final price = old
        ? widget.b.withOld
        : widget.b.withoutOld;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البطارية'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.battery_charging_full,
                      size: 80,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.b.brand} ${widget.b.amp}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<bool>(
                      value: true,
                      groupValue: old,
                      title: const Text(
                        'أسلّم البطارية القديمة',
                      ),
                      onChanged: (_) {
                        setState(() {
                          old = true;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      value: false,
                      groupValue: old,
                      title: const Text(
                        'بدون البطارية القديمة',
                      ),
                      onChanged: (_) {
                        setState(() {
                          old = false;
                        });
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('السعر النهائي'),
                    Text(
                      '${money(price)} د.ع',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderCodePage(
                              title:
                                  '${widget.b.brand} ${widget.b.amp}',
                              detail: old
                                  ? 'مع تسليم البطارية القديمة'
                                  : 'بدون تسليم البطارية القديمة',
                              price: price,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('اطلب الآن'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
