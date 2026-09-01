part of '../app_core.dart';

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
      setState(
        () => _locationError = e.toString().replaceFirst('Exception: ', ''),
      );
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
              const Icon(
                Icons.add_business,
                size: 72,
                color: Color(0xff111111),
              ),
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
                        _position == null
                            ? Icons.my_location
                            : Icons.check_circle,
                      ),
                label: Text(
                  _position == null
                      ? 'تحديد موقع المحل GPS'
                      : 'تم تحديد موقع المحل',
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

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر فتح الخرائط')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...shops];

    if (position != null) {
      sorted.sort((a, b) => distanceKm(a).compareTo(distanceKm(b)));
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
                child: Center(child: CircularProgressIndicator()),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
