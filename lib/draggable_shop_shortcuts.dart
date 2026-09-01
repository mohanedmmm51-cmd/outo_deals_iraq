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
  State<DraggableShopShortcuts> createState() =>
      _DraggableShopShortcutsState();
}

class _DraggableShopShortcutsState extends State<DraggableShopShortcuts> {
  ShopProfile? shop;

  static const double _shortcutSize = 50;
  static const double _shortcutRight = 16;
  static const double _nearbyBottom = 140;
  static const double _scannerBottom = 202;

  @override
  void initState() {
    super.initState();
    ShopStore.ownerSessionVersion.addListener(_loadShop);
    _loadShop();
  }

  @override
  void dispose() {
    ShopStore.ownerSessionVersion.removeListener(_loadShop);
    super.dispose();
  }

  Future<void> _loadShop() async {
    final value = await ShopStore.loadForAuthenticatedOwner();
    if (!mounted) return;
    setState(() => shop = value);
  }

  void _push(Widget page) {
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          right: _shortcutRight,
          bottom: _nearbyBottom,
          child: _RoundShortcut(
            size: _shortcutSize,
            icon: Icons.near_me,
            tooltip: 'المحلات القريبة',
            onTap: () => _push(const OnlineNearbyShopsPage()),
          ),
        ),
        if (shop != null)
          Positioned(
            right: _shortcutRight,
            bottom: _scannerBottom,
            child: _ScannerShortcut(
              onTap: () => _push(ShopQrConfirmPage(shop: shop!)),
            ),
          ),
      ],
    );
  }
}

class _ScannerShortcut extends StatelessWidget {
  final VoidCallback onTap;

  const _ScannerShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: const CircleBorder(),
      child: Tooltip(
        message: 'مسح طلب',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: _DraggableShopShortcutsState._shortcutSize,
            height: _DraggableShopShortcutsState._shortcutSize,
            child: Icon(Icons.qr_code_scanner),
          ),
        ),
      ),
    );
  }
}

class _RoundShortcut extends StatelessWidget {
  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundShortcut({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shape: const CircleBorder(),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}
