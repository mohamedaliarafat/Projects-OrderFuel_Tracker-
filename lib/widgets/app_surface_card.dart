import 'package:flutter/material.dart';

/// A reusable "glass" surface used across modernized pages.
///
/// Provides a subtle translucent background, soft border, and shadow.
/// Optionally becomes tappable with an ink ripple.
class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.onTap,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? Colors.white.withValues(alpha: 0.86),
      borderRadius: borderRadius,
      border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.70)),
      boxShadow:
          boxShadow ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
    );

    final content = Padding(padding: padding, child: child);

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: onTap == null
              ? content
              : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}
