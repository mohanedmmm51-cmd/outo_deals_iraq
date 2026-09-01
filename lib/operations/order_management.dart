part of '../operations_features.dart';

class ShopOrdersPage extends StatelessWidget {
  const ShopOrdersPage({super.key});

  Future<void> _accept(DocumentReference<Map<String, dynamic>> ref) async {
    await ref.set({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditLogService.record(action: 'order_accepted', targetType: 'order', targetId: ref.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopProfile?>(
      future: ShopStore.load(),
      builder: (context, shopSnap) {
        final shop = shopSnap.data;
        if (shop == null) return const Scaffold(body: Center(child: Text('سجل دخول المحل أولاً')));
        return Scaffold(
          appBar: AppBar(title: const Text('طلبات المحل')),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('orders').where('shopId', isEqualTo: shop.id).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs.toList()
                  ..sort((a, b) => opDate(b.data()['createdAt']).compareTo(opDate(a.data()['createdAt'])));
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final x = d.data();
                    var status = '${x['status'] ?? ''}';
                    if (status.isEmpty) status = x['completed'] == true ? 'completed' : 'new';
                    return Card(
                      child: ListTile(
                        title: Text('${x['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${d.id}\n${orderStatusLabel(status)} • ${opMoney((x['price'] as num?)?.toInt() ?? 0)} د.ع'),
                        isThreeLine: true,
                        trailing: status == 'new'
                            ? FilledButton(onPressed: () => _accept(d.reference), child: const Text('قبول'))
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class OrdersManagementPage extends StatefulWidget {
  const OrdersManagementPage({super.key});
  @override
  State<OrdersManagementPage> createState() => _OrdersManagementPageState();
}

class _OrdersManagementPageState extends State<OrdersManagementPage> {
  final search = TextEditingController();
  String status = 'all';
  DateTime? from;
  DateTime? to;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final q = search.text.trim().toLowerCase();
    return docs.where((d) {
      final x = d.data();
      var s = '${x['status'] ?? ''}';
      if (s.isEmpty) s = x['completed'] == true ? 'completed' : 'new';
      final date = opDate(x['createdAt']);
      if (status != 'all' && s != status) return false;
      if (from != null && date.isBefore(DateTime(from!.year, from!.month, from!.day))) return false;
      if (to != null && date.isAfter(DateTime(to!.year, to!.month, to!.day, 23, 59, 59))) return false;
      if (q.isEmpty) return true;
      return '${d.id} ${x['title']} ${x['shopName']} ${x['detail']}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: from ?? DateTime.now(),
    );
    if (d != null) setState(() => from = d);
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: to ?? DateTime.now(),
    );
    if (d != null) setState(() => to = d);
  }

  Future<void> _exportCsv(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final lines = <String>['code,title,shop,status,price,commission,createdAt'];
    String esc(dynamic value) => '"${'$value'.replaceAll('"', '""')}"';
    for (final d in docs) {
      final x = d.data();
      var s = '${x['status'] ?? ''}';
      if (s.isEmpty) s = x['completed'] == true ? 'completed' : 'new';
      lines.add([
        esc(d.id),
        esc(x['title']),
        esc(x['shopName']),
        esc(s),
        x['price'] ?? 0,
        x['commission'] ?? 0,
        esc(opDate(x['createdAt']).toIso8601String()),
      ].join(','));
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/auto_deals_orders.csv');
    await file.writeAsString(lines.join('\n'));
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'تقرير طلبات Auto Deals Iraq'),
    );
  }

  Future<void> _exportPdf(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final pdf = pw.Document();
    final total = docs.fold<int>(0, (value, d) => value + ((d.data()['price'] as num?)?.toInt() ?? 0));
    final commission = docs.fold<int>(0, (value, d) => value + ((d.data()['commission'] as num?)?.toInt() ?? 0));
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text('Auto Deals Iraq Orders Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Orders: ${docs.length}  Sales: $total IQD  Commission: $commission IQD'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['Code', 'Shop', 'Status', 'Price', 'Commission'],
            data: docs.map((d) {
              final x = d.data();
              var s = '${x['status'] ?? ''}';
              if (s.isEmpty) s = x['completed'] == true ? 'completed' : 'new';
              return [d.id, '${x['shopName'] ?? ''}', s, '${x['price'] ?? 0}', '${x['commission'] ?? 0}'];
            }).toList(),
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/auto_deals_orders.pdf');
    await file.writeAsBytes(await pdf.save());
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'تقرير طلبات Auto Deals Iraq'),
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث والتقارير')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = _filter(snap.data!.docs);
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث بالكود أو المحل أو المنتج',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('كل الحالات')),
                    DropdownMenuItem(value: 'new', child: Text('جديد')),
                    DropdownMenuItem(value: 'accepted', child: Text('مقبول')),
                    DropdownMenuItem(value: 'on_the_way', child: Text('بالطريق')),
                    DropdownMenuItem(value: 'completed', child: Text('منفذ')),
                    DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                  ],
                  onChanged: (v) => setState(() => status = v ?? 'all'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: _pickFrom, child: Text(from == null ? 'من تاريخ' : '${from!.year}/${from!.month}/${from!.day}'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: _pickTo, child: Text(to == null ? 'إلى تاريخ' : '${to!.year}/${to!.month}/${to!.day}'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: FilledButton.icon(onPressed: docs.isEmpty ? null : () => _exportCsv(docs), icon: const Icon(Icons.table_view), label: const Text('CSV'))),
                    const SizedBox(width: 8),
                    Expanded(child: FilledButton.icon(onPressed: docs.isEmpty ? null : () => _exportPdf(docs), icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF'))),
                  ],
                ),
                const SizedBox(height: 10),
                Text('النتائج: ${docs.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...docs.map((d) {
                  final x = d.data();
                  var s = '${x['status'] ?? ''}';
                  if (s.isEmpty) s = x['completed'] == true ? 'completed' : 'new';
                  return Card(
                    child: ListTile(
                      title: Text('${x['title'] ?? ''}'),
                      subtitle: Text('${d.id}\n${x['shopName'] ?? ''} • ${orderStatusLabel(s)} • ${opMoney((x['price'] as num?)?.toInt() ?? 0)} د.ع'),
                      isThreeLine: true,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return Scaffold(
      appBar: AppBar(title: const Text('إحصائيات هذا الشهر')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final completed = snap.data!.docs.where((d) {
              final x = d.data();
              final date = opDate(x['completedAt'] ?? x['createdAt']);
              final done = x['completed'] == true || x['status'] == 'completed';
              return done && !date.isBefore(monthStart) && date.isBefore(nextMonth);
            }).toList();
            final sales = completed.fold<int>(0, (value, d) => value + ((d.data()['price'] as num?)?.toInt() ?? 0));
            final commissions = completed.fold<int>(0, (value, d) => value + ((d.data()['commission'] as num?)?.toInt() ?? 0));
            final avg = completed.isEmpty ? 0 : sales ~/ completed.length;
            final products = <String, int>{};
            final shops = <String, int>{};
            for (final d in completed) {
              final x = d.data();
              final title = '${x['title'] ?? ''}';
              final shop = '${x['shopName'] ?? ''}';
              products[title] = (products[title] ?? 0) + 1;
              if (shop.isNotEmpty) shops[shop] = (shops[shop] ?? 0) + 1;
            }
            final topProducts = products.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            final topShops = shops.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _stat('مبيعات', '${opMoney(sales)} د.ع', Icons.payments)),
                    const SizedBox(width: 8),
                    Expanded(child: _stat('عمولات', '${opMoney(commissions)} د.ع', Icons.account_balance_wallet)),
                  ],
                ),
                const SizedBox(height: 8),
                _stat('متوسط الطلب', '${opMoney(avg)} د.ع', Icons.analytics),
                const SizedBox(height: 16),
                const Text('أكثر المنتجات طلباً', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ...topProducts.take(10).map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value} طلب'))),
                const SizedBox(height: 12),
                const Text('أكثر المحلات مبيعاً', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ...topShops.take(10).map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value} طلب'))),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon) => Card(
        color: operationsYellow,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, size: 32),
              Text(title),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}
