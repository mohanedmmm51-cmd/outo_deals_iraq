part of '../order_system_impl.dart';

class OrderTicketPage extends StatefulWidget {
  final String title;
  final String detail;
  final int price;
  final int commission;
  final String productId;

  const OrderTicketPage({
    super.key,
    required this.title,
    required this.detail,
    required this.price,
    required this.commission,
    this.productId = '',
  });

  @override
  State<OrderTicketPage> createState() => _OrderTicketPageState();
}

class _OrderTicketPageState extends State<OrderTicketPage> {
  AppOrder? order;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? shops;
  String? selectedShopId;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('shops')
          .where('approved', isEqualTo: true)
          .get();
      final eligible = await InventoryService.eligibleShops(
        snap.docs,
        widget.productId,
      );
      if (mounted) {
        setState(() {
          shops = eligible;
          selectedShopId = eligible.length == 1 ? eligible.first.id : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          shops = [];
          error = e.toString();
        });
      }
    }
  }

  Future<void> _create() async {
    if (selectedShopId == null || shops == null) return;
    final shop = shops!.firstWhere((d) => d.id == selectedShopId);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final created = await OrderStore.create(
        title: widget.title,
        detail: widget.detail,
        price: widget.price,
        commission: widget.commission,
        shopId: shop.id,
        shopName: '${shop.data()['name'] ?? ''}',
        productId: widget.productId,
      );
      if (mounted) setState(() => order = created);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
        await _loadShops();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(order == null ? 'اختيار المحل' : 'كود الطلب')),
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: order == null ? _chooser() : _ticket(),
    ),
  );

  Widget _chooser() {
    if (shops == null) return const Center(child: CircularProgressIndicator());
    if (shops!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 58),
              const SizedBox(height: 12),
              Text(
                error ?? 'ماكو محل عنده هذا المنتج متوفر حالياً',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadShops,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث التوفر'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          color: orderYellow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('السعر النهائي المثبت: ${_money(widget.price)} د.ع'),
                const SizedBox(height: 5),
                const Text(
                  'بعد إنشاء الكود ما يقدر المحل يغيّر سعر هذا الطلب.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'اختار المحل',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        ...shops!.map((d) {
          final data = d.data();
          final inventoryEnabled = data['inventoryEnabled'] == true;
          return RadioListTile<String>(
            value: d.id,
            groupValue: selectedShopId,
            title: Text('${data['name'] ?? ''}'),
            subtitle: Text(
              inventoryEnabled
                  ? 'المخزون مؤكد داخل التطبيق'
                  : '${data['phone'] ?? ''} • التوفر يتأكد عند إنشاء الطلب',
            ),
            onChanged: (v) => setState(() => selectedShopId = v),
          );
        }),
        FilledButton.icon(
          onPressed: busy || selectedShopId == null ? null : _create,
          icon: const Icon(Icons.qr_code_2),
          label: Text(
            busy ? 'جاري تثبيت الطلب...' : 'إنشاء الكود وتثبيت السعر',
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(error!, textAlign: TextAlign.center),
          ),
      ],
    );
  }

  Widget _ticket() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Card(
        color: orderYellow,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order!.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(order!.detail),
              Text(
                'المحل: ${order!.shopName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'السعر المثبت: ${_money(order!.price)} د.ع',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'صلاحية الكود: 24 ساعة • السعر لا يتغير خلال الصلاحية',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'كود الزيارة/الشراء',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      SelectableText(
        order!.code,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 18),
      Center(
        child: BarcodeWidget(
          barcode: Barcode.qrCode(),
          data: order!.code,
          width: 200,
          height: 200,
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: BarcodeWidget(
          barcode: Barcode.code128(),
          data: order!.code,
          width: 290,
          height: 90,
          drawText: true,
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderActionsPage(orderCode: order!.code),
          ),
        ),
        icon: const Icon(Icons.manage_search),
        label: const Text('إدارة ومشاركة الطلب'),
      ),
    ],
  );
}

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<AppOrder>? orders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await OrderStore.load();
    if (mounted) setState(() => orders = data);
  }

  Future<void> _restoreFromCloud() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استرجاع طلب من السحابة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'كود الطلب',
            hintText: 'ADI-XXXXXXXXXX',
            prefixIcon: Icon(Icons.cloud_download_outlined),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('استرجاع'),
          ),
        ],
      ),
    );
    controller.dispose();

    final normalized = code?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('جاري البحث عن الطلب في السحابة...')),
    );
    final restored = await OrderStore.findByCode(normalized);
    if (!mounted) return;
    messenger.hideCurrentSnackBar();

    if (restored == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ما لكينا طلب بهذا الكود. تأكد من الكود والإنترنت.'),
        ),
      );
      return;
    }

    await _load();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('تم استرجاع طلب ${restored.code} من السحابة')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('طلباتي'),
      actions: [
        IconButton(
          onPressed: _restoreFromCloud,
          tooltip: 'استرجاع طلب من السحابة',
          icon: const Icon(Icons.cloud_download_outlined),
        ),
      ],
    ),
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: orders == null
          ? const Center(child: CircularProgressIndicator())
          : orders!.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_done_outlined,
                      size: 64,
                      color: Colors.black45,
                    ),
                    const SizedBox(height: 12),
                    const Text('ما عندك طلبات على هذا الجهاز'),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _restoreFromCloud,
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('استرجاع طلب بالكود'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: orders!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final o = orders![index];
                  var status = o.status;
                  if (o.expiresAt != null &&
                      DateTime.now().isAfter(o.expiresAt!) &&
                      !o.completed &&
                      status != 'cancelled') {
                    status = 'expired';
                  }
                  return Card(
                    child: ListTile(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderActionsPage(orderCode: o.code),
                          ),
                        );
                        _load();
                      },
                      leading: CircleAvatar(
                        backgroundColor: status == 'completed'
                            ? Colors.green
                            : orderYellow,
                        child: Icon(
                          status == 'completed'
                              ? Icons.check
                              : Icons.receipt_long,
                          color: Colors.black,
                        ),
                      ),
                      title: Text(
                        o.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${o.code}\n${o.shopName} • ${_money(o.price)} د.ع • ${orderStatusLabel(status)}\nالسعر مثبت',
                      ),
                      isThreeLine: true,
                      trailing: o.completed && o.shopId.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.star_rate),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RatingPage(
                                    orderCode: o.code,
                                    shopId: o.shopId,
                                    shopName: o.shopName,
                                  ),
                                ),
                              ),
                            )
                          : const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  );
                },
              ),
            ),
    ),
  );
}
