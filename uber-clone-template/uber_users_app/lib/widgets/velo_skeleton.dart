import 'package:flutter/material.dart';

/// Animated shimmer placeholder for loading states (no extra packages).
///
/// Uses a [LinearGradient] sweep driven by an [AnimationController] to give the
/// appearance of light moving across the surface — matching what users expect
/// from modern skeleton loaders.
class VeloSkeletonBlock extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadiusGeometry borderRadius;

  const VeloSkeletonBlock({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<VeloSkeletonBlock> createState() => _VeloSkeletonBlockState();
}

class _VeloSkeletonBlockState extends State<VeloSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHighest.withOpacity(0.25);
    final highlight = cs.surfaceContainerHighest.withOpacity(0.55);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (_ctrl.value - 0.3).clamp(0.0, 1.0),
                _ctrl.value,
                (_ctrl.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
