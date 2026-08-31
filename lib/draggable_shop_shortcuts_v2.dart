import 'package:flutter/material.dart';

import 'marketplace_features.dart';
import 'shop_qr_confirm_page.dart';
import 'shop_store.dart';

class DraggableShopShortcutsV2 extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const DraggableShopShortcutsV2({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<DraggableShopShortcutsV2> createState() =>
      _DraggableShopShortcutsV2State();
}

class _DraggableShopShortcutsV2State extends State<DraggableShopShortcutsV2> {
  ShopProfile? shop;
  Offset? scannerPosition;

  static const double _scannerWidth = 148;
  static const double _scannerHeight = 54;
  static const double _nearbySize = 54;
  static const double _edge = 12;

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
          child: IgnorePointer(
            ignoring: true,
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
                  children: [
                    Positioned(
                      right: _edge,
                      bottom: safe.bottom + 18,
                      child: IgnorePointer(
                        ignoring: false,
                        child: _RoundShortcut(
                          size: _nearbySize,
                          tooltip: 'المحلات القريبة',
                          icon: Icons.near_me,
                          onTap: () => _push(const OnlineNearbyShopsPage()),
                        ),
                      ),
                    ),
                    if (shop != null)
                      Positioned(
                        left: scanner.dx,
                        top: scanner.dy,
                        child: IgnorePointer(
                          ignoring: false,
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
                              onTap: () =>
                                  _push(ShopQrConfirmPage(shop: shop!)),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: _DraggableShopShortcutsV2State._scannerWidth,
          height: _DraggableShopShortcutsV2State._scannerHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 3),
                color: Color(0x33000000),
              ),
            ],
          ),
          child: const Row(
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
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundShortcut({
    required this.size,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 6,
        shape: const CircleBorder(),
        color: Theme.of(context).colorScheme.primaryContainer,
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
