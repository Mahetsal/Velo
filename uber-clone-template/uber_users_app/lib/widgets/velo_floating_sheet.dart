import 'package:flutter/material.dart';

/// Floating card above the map — premium shadow, large radius, optional handle.
class VeloFloatingSheet extends StatelessWidget {
  const VeloFloatingSheet({
    super.key,
    required this.child,
    this.dark = false,
    this.showHandle = true,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 12),
  });

  final Widget child;
  final bool dark;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: padding.add(EdgeInsets.only(bottom: bottomInset > 0 ? 4 : 0)),
      child: Material(
        color: Colors.transparent,
        elevation: 24,
        shadowColor: const Color(0x59000000),
        borderRadius: BorderRadius.circular(28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: dark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF0F172A),
                        Color(0xFF020617),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    )
                  : null,
              color: dark ? null : Colors.white,
              border: Border.all(
                color: dark
                    ? const Color(0x33FFFFFF)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHandle) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withOpacity(0.22)
                          : Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
