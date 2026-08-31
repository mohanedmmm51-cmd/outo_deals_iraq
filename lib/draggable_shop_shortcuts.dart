import 'package:flutter/material.dart';

import 'marketplace_features.dart';
import 'shop_qr_confirm_page.dart';
import 'shop_store.dart';

class DraggableShopShortcuts extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const DraggableShopShortcuts({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<DraggableShopShortcuts> createState() => _DraggableShopShortcutsState();
}

class _DraggableShopShortcutsState extends State<DraggableShopShortcuts> {
  ShopProfile? shop;
  Offset? scannerPosition;

  static const double _scannerWidth = 150;
  static const double _scannerHeight = 56;
  static const double _edge = 10;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final value = await ShopStore.load();
    if (mounted) setState(() => shop = value);
  }

  void _push(Widget page) {
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  double _clamp(double value, double min, double max) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safe = MediaQuery.paddingOf(context);
        final maxX = constraints.maxWidth - _scannerWidth - _edge;
        final maxY = constraints.maxHeight - safe.bottom - _scannerHeight - _edge;
        final minY = safe.top + _edge;

        final defaultPosition = Offset(
          16,
          _clamp(
            constraints.maxHeight - safe.bottom - _scannerHeight - 22,
            minY,
            maxY,
          ),
        );
        final current = scannerPosition ?? defaultPosition;
        final effective = Offset(
          _clamp(current.dx, _edge, maxX),
          _clamp(current.dy, minY, maxY),
        );

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
                left: effective.dx,
                top: effective.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    final base = scannerPosition ?? defaultPosition;
                    setState(() {
                      scannerPosition = Offset(
                        _clamp(base.dx + details.delta.dx, _edge, maxX),
                        _clamp(base.dy + details.delta.dy, minY, maxY),
                      );
                    });
                  },
                  child: FloatingActionButton.extended(
                    heroTag: 'shop-order-scanner-draggable',
                    tooltip: 'اضغط للمسح أو اسحب الزر لتغيير مكانه',
                    onPressed: () => _push(ShopQrConfirmPage(shop: shop!)),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('مسح طلب'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
