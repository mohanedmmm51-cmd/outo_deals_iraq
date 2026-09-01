part of '../expert_features.dart';

class MaintenanceRecordsPage extends StatefulWidget {
  const MaintenanceRecordsPage({super.key});

  @override
  State<MaintenanceRecordsPage> createState() => _MaintenanceRecordsPageState();
}

class _MaintenanceRecordsPageState extends State<MaintenanceRecordsPage> {
  static const keyName = 'vehicle_maintenance_records';
  final product = TextEditingController();
  final car = TextEditingController();
  final km = TextEditingController();
  final warranty = TextEditingController();
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    product.dispose();
    car.dispose();
    km.dispose();
    warranty.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(keyName) ?? [];
    if (!mounted) return;
    setState(() {
      records = raw
          .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> addRecord() async {
    if (product.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(keyName) ?? [];
    raw.add(
      jsonEncode({
        'product': product.text.trim(),
        'car': car.text.trim(),
        'km': km.text.trim(),
        'warranty': warranty.text.trim(),
        'date': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setStringList(keyName, raw);
    product.clear();
    car.clear();
    km.clear();
    warranty.clear();
    await load();
  }

  Future<void> openAddDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة سجل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: product,
                  decoration: const InputDecoration(
                    labelText: 'المنتج: إطار أو بطارية',
                  ),
                ),
                TextField(
                  controller: car,
                  decoration: const InputDecoration(labelText: 'السيارة'),
                ),
                TextField(
                  controller: km,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكيلومترات عند التركيب',
                  ),
                ),
                TextField(
                  controller: warranty,
                  decoration: const InputDecoration(
                    labelText: 'الضمان / ملاحظة',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await addRecord();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  String dateLabel(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return '';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل السيارة والضمان')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة سجل'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: records.isEmpty
            ? const Center(
                child: Text('ماكو سجلات بعد. احفظ أول تبديل إطار أو بطارية.'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final r = records[index];
                  final details = <String>[
                    if ('${r['car'] ?? ''}'.isNotEmpty) 'السيارة: ${r['car']}',
                    if ('${r['km'] ?? ''}'.isNotEmpty) 'العداد: ${r['km']} كم',
                    if ('${r['warranty'] ?? ''}'.isNotEmpty)
                      'الضمان: ${r['warranty']}',
                    'التاريخ: ${dateLabel('${r['date'] ?? ''}')}',
                  ];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: yellow,
                        child: Icon(Icons.history, color: Colors.black),
                      ),
                      title: Text(
                        '${r['product']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(details.join('\n')),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
