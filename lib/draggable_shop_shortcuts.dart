import 'package:flutter/material.dart';

import 'marketplace_features.dart';

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
  static const double _shortcutSize = 50;
  static const double _shortcutRight = 16;
  static const double _nearbyBottom = 140;

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
      ],
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
      child: Semantics(
        label: tooltip,
        button: true,
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
