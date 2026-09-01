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
  Offset? scannerPosition;

  static const double _scannerWidth = 148;
  static const double _scannerHeight = 54;
  static const double _nearbySize = 50;
  static const double _edge = 12;
  static const double _bottomNavigationClearance = 84;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final value = await ShopStore.load();
    if (!mounted) return;
    setState(() => shop = value);
  }

  void _push(Widget page) {
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  double _clamp(double value, double min, double max) {
    if (!value.isFinite || !min.isFinite || !max.isFinite) return min;
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (!constraints.hasBoundedWidth ||
                  !constraints.hasBoundedHeight ||
                  constraints.maxWidth <= 0 ||
                  constraints.maxHeight <= 0) {
                return const SizedBox.shrink();
              }

              final safe = MediaQuery.paddingOf(context);
              final maxScannerX =
                  constraints.maxWidth - _scannerWidth - _edge;
              final minScannerY = safe.top + _edge;
              final maxScannerY = constraints.maxHeight -
                  safe.bottom -
                  _scannerHeight -
                  _edge;

              final defaultScanner = Offset(
                _edge,
                _clamp(
                  constraints.maxHeight -
                      safe.bottom -
                      _scannerHeight -
                      90,
                  minScannerY,
                  maxScannerY,
                ),
              );

              final raw = scannerPosition ?? defaultScanner;
              final scanner = Offset(
                _clamp(raw.dx, _edge, maxScannerX),
                _clamp(raw.dy, minScannerY, maxScannerY),
              );

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: _edge + 4,
                    bottom: safe.bottom + _bottomNavigationClearance,
                    child: _RoundShortcut(
                      size: _nearbySize,
                      icon: Icons.near_me,
                      tooltip: 'المحلات القريبة',
                      onTap: () => _push(const OnlineNearbyShopsPage()),
                    ),
                  ),
                  if (shop != null)
                    Positioned(
                      left: scanner.dx,
                      top: scanner.dy,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          final current = scannerPosition ?? defaultScanner;
                          setState(() {
                            scannerPosition = Offset(
                              _clamp(
                                current.dx + details.delta.dx,
                                _edge,
                                maxScannerX,
                              ),
                              _clamp(
                                current.dy + details.delta.dy,
                                minScannerY,
                                maxScannerY,
                              ),
                            );
                          });
                        },
                        child: _ScannerShortcut(
                          onTap: () => _push(ShopQrConfirmPage(shop: shop!)),
                        ),
                      ),
                    ),
                ],
              );
            },
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(
          width: _DraggableShopShortcutsState._scannerWidth,
          height: _DraggableShopShortcutsState._scannerHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner),
              SizedBox(width: 8),
              Text(
                'مسح طلب',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
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
