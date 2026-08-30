import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'marketplace_features.dart';
import 'order_system.dart';
import 'shop_store.dart';
import 'size_request_page.dart';

class ShopScannerShortcut extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ShopScannerShortcut({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<ShopScannerShortcut> createState() => _ShopScannerShortcutState();
}

class _ShopScannerShortcutState extends State<ShopScannerShortcut> {
  ShopProfile? shop;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ShopStore.load();
    if (mounted) setState(() => shop = value);
  }

  void _push(Widget page) {
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 16,
          bottom: 22,
          child: SafeArea(
            child: FloatingActionButton(
              heroTag: 'nearby-shops-shortcut',
              onPressed: () => _push(const OnlineNearbyShopsPage()),
              child: const Icon(Icons.near_me),
            ),
          ),
        ),
        if (shop != null)
          Positioned(
            left: 16,
            bottom: 22,
            child: SafeArea(
              child: FloatingActionButton.extended(
                heroTag: 'shop-order-scanner',
                onPressed: () => _push(ShopQrConfirmPage(shop: shop!)),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('مسح طلب'),
              ),
            ),
          ),
      ],
    );
  }
}

class ShopQrConfirmPage extends StatefulWidget {
  final ShopProfile shop;
  const ShopQrConfirmPage({super.key, required this.shop});

  @override
  State<ShopQrConfirmPage> createState() => _ShopQrConfirmPageState();
}

class _ShopQrConfirmPageState extends State<ShopQrConfirmPage> {
  final MobileScannerController scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool handling = false;
  AppOrder? order;
  String? message;

  Future<void> _detected(BarcodeCapture capture) async {
    if (handling || order != null) return;
    String? code;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim().toUpperCase();
      if (raw != null && raw.startsWith('ADI-')) {
        code = raw;
        break;
      }
    }
    if (code == null) return;

    setState(() {
      handling = true;
      message = null;
    });
    await scanner.stop();

    try {
      final found = await OrderStore.findByCode(code);
      if (!mounted) return;
      if (found == null) {
        setState(() => message = 'الكود غير موجود');
        await scanner.start();
        return;
      }
      if (found.shopId.isNotEmpty && found.shopId != widget.shop.id) {
        setState(() => message = 'هذا الطلب مخصص لمحل آخر');
        await scanner.start();
        return;
      }
      if (found.completed) {
        setState(() => message = 'هذا الطلب منفذ مسبقاً');
        await scanner.start();
        return;
      }
      if (found.status == 'cancelled' || found.status == 'expired') {
        setState(() => message = 'هذا الطلب ملغي أو منتهي الصلاحية');
        await scanner.start();
        return;
      }
      setState(() => order = found);
    } catch (e) {
      if (mounted) {
        setState(() => message = e.toString());
        await scanner.start();
      }
    } finally {
      if (mounted) setState(() => handling = false);
    }
  }

  Future<void> _confirm() async {
    final current = order;
    if (current == null || handling) return;
    setState(() {
      handling = true;
      message = null;
    });
    try {
      final confirmed = await OrderStore.confirm(
        current.code,
        shopId: widget.shop.id,
        shopName: widget.shop.name,
      );
      if (!mounted) return;
      setState(() {
        order = confirmed;
        message = confirmed == null
            ? 'تعذر تأكيد الطلب'
            : 'تم تنفيذ الطلب وتسجيل العمولة بنجاح';
      });
    } catch (e) {
      if (mounted) setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => handling = false);
    }
  }

  Future<void> _scanAnother() async {
    setState(() {
      order = null;
      message = null;
    });
    await scanner.start();
  }

  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('مسح طلب - ${widget.shop.name}'),
          actions: [
            IconButton(
              tooltip: 'طلبات القياسات',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopSizeRequestsEnhancedPage()),
              ),
              icon: const Icon(Icons.straighten),
            ),
            IconButton(
              tooltip: 'الفلاش',
              onPressed: () => scanner.toggleTorch(),
              icon: const Icon(Icons.flash_on),
            ),
          ],
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: order == null ? _scannerView() : _orderView(),
        ),
      );

  Widget _scannerView() => Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: scanner, onDetect: _detected),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: orderYellow, width: 4),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'وجّه الكاميرا على QR أو باركود الطلب',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (handling) ...[
                      const SizedBox(height: 10),
                      const CircularProgressIndicator(),
                    ],
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _orderView() {
    final o = order!;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          color: orderYellow,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(o.detail),
                const SizedBox(height: 6),
                Text('الكود: ${o.code}'),
                Text('السعر: ${o.price} د.ع'),
                Text('العمولة: ${o.commission} د.ع'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (o.completed)
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('تم تنفيذ الطلب'),
            ),
          )
        else
          FilledButton.icon(
            onPressed: handling ? null : _confirm,
            icon: const Icon(Icons.check_circle),
            label: Text(handling ? 'جاري التأكيد...' : 'تأكيد تنفيذ الطلب'),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: handling ? null : _scanAnother,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('مسح طلب آخر'),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}
