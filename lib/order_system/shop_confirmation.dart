part of '../order_system_impl.dart';

class ShopConfirmOrderPage extends StatefulWidget {
  const ShopConfirmOrderPage({super.key});

  @override
  State<ShopConfirmOrderPage> createState() => _ShopConfirmOrderPageState();
}

class _ShopConfirmOrderPageState extends State<ShopConfirmOrderPage> {
  final controller = TextEditingController();
  AppOrder? found;
  ShopProfile? shop;
  String? message;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final value = await ShopStore.load();
    if (mounted) setState(() => shop = value);
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      message = null;
      found = null;
    });
    final result = await OrderStore.findByCode(controller.text);
    if (!mounted) return;
    setState(() {
      busy = false;
      found = result;
      if (result == null) message = 'الكود غير موجود';
    });
  }

  Future<void> _confirm() async {
    if (found == null) return;
    final currentShop = await ShopStore.load();
    if (currentShop == null) {
      if (mounted) setState(() => message = 'سجل دخول المحل أولاً');
      return;
    }
    if (found!.shopId.isNotEmpty && found!.shopId != currentShop.id) {
      setState(() => message = 'هذا الطلب مخصص لمحل آخر');
      return;
    }
    setState(() => busy = true);
    try {
      final result = await OrderStore.confirm(
        found!.code,
        shopId: currentShop.id,
        shopName: currentShop.name,
      );
      if (!mounted) return;
      setState(() {
        found = result;
        shop = currentShop;
        message = result == null
            ? 'تعذر تأكيد الطلب'
            : 'تم تنفيذ الطلب، تنزيل المخزون، وتسجيل العمولة';
      });
    } catch (e) {
      if (mounted) {
        setState(() => message = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('تأكيد طلب الزبون'),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopDashboardPage()),
          ),
          icon: const Icon(Icons.account_balance_wallet),
        ),
      ],
    ),
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            color: shop == null
                ? Colors.orange.shade100
                : Colors.green.shade100,
            child: ListTile(
              leading: Icon(shop == null ? Icons.warning_amber : Icons.store),
              title: Text(shop == null ? 'ماكو حساب محل' : shop!.name),
              subtitle: Text(
                shop == null
                    ? 'سجل دخول المحل أولاً'
                    : 'رقم المحل: ${shop!.id}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'كود الطلب',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: busy ? null : _search,
            icon: const Icon(Icons.search),
            label: const Text('فحص الكود'),
          ),
          if (busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          if (found != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      found!.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(found!.detail),
                    Text('المحل المطلوب: ${found!.shopName}'),
                    Text(
                      'السعر المثبت: ${_money(found!.price)} د.ع',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('العمولة: ${_money(found!.commission)} د.ع'),
                    Text('الحالة: ${orderStatusLabel(found!.status)}'),
                    const SizedBox(height: 10),
                    if (found!.completed)
                      const Chip(
                        avatar: Icon(Icons.check_circle),
                        label: Text('تم تنفيذ الطلب'),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: busy ? null : _confirm,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('تأكيد التنفيذ وتنزيل المخزون'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
