part of '../app_core.dart';

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
      final result = await api.cars(make!, model!, year!);

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
      final result = await api.sizes(car: car);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SizesPage(car: car, sizes: result),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(30, (index) => 2026 - index);

    return Scaffold(
      appBar: AppBar(title: const Text('اختار سيارتك')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(Icons.directions_car, size: 80, color: yellow),
            const SizedBox(height: 8),
            const Text(
              'اختار سيارتك حتى نطلع القياس المناسب',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            if (busy && makes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (busy && makes.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ...cars.map((car) {
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.directions_car),
                  ),
                  title: Text(
                    car.trim.isEmpty ? '${car.make} ${car.model}' : car.trim,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${car.make} ${car.model} • ${car.year}'),
                  trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                  onTap: busy ? null : () => openSizes(car),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class SizesPage extends StatelessWidget {
  final Car car;
  final List<String> sizes;

  const SizesPage({super.key, required this.car, required this.sizes});

  String normalize(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^0-9]'), '');
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
      appBar: AppBar(title: const Text('قياسات السيارة')),
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
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
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
            ...sizes.map((size) {
              final matches = matchingTires(size);

              final subtitle = matches.isEmpty
                  ? 'القياس موجود في VehDB، لكن لا يوجد سعر مطابق في قائمتنا حاليًا'
                  : matches.length == 1
                  ? 'اضغط لعرض السعر: ${money(matches.first.price)} د.ع'
                  : 'اضغط لعرض ${matches.length} خيارات وأسعار';

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.tire_repair, size: 34),
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
                      : const Icon(Icons.arrow_back_ios_new, size: 16),
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
            }),
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
      appBar: AppBar(title: const Text('أسعار الإطارات')),
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
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
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
                        leading: const Icon(Icons.tire_repair, size: 34),
                        title: Text(
                          tire.size,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text('السعر النهائي للزبون'),
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
                                detail: '${car.make} ${car.model} ${car.year}',
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
      appBar: AppBar(title: const Text('الإطارات')),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('السعر النهائي: ${money(tire.price)} د.ع'),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TireDetailsPage(tire: tire),
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

  const TireDetailsPage({super.key, required this.tire});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الإطار')),
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
                    const Icon(Icons.tire_repair, size: 80),
                    const SizedBox(height: 12),
                    Text(
                      tire.size,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('السعر النهائي للزبون'),
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
                subtitle: Text('تفاصيل التركيب والبلنص تظهر حسب عرض المحل.'),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      appBar: AppBar(title: const Text('البطاريات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: batteries.length,
          itemBuilder: (context, index) {
            final battery = batteries[index];

            return Card(
              child: ListTile(
                leading: const Icon(Icons.battery_charging_full),
                title: Text(
                  '${battery.brand} ${battery.amp}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('اختيار البطارية القديمة'),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BatteryPage(b: battery)),
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

  const BatteryPage({super.key, required this.b});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  bool old = true;

  @override
  Widget build(BuildContext context) {
    final price = old ? widget.b.withOld : widget.b.withoutOld;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل البطارية')),
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
                    const Icon(Icons.battery_charging_full, size: 80),
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
                      title: const Text('أسلّم البطارية القديمة'),
                      onChanged: (_) {
                        setState(() {
                          old = true;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      value: false,
                      groupValue: old,
                      title: const Text('بدون البطارية القديمة'),
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
                              title: '${widget.b.brand} ${widget.b.amp}',
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
