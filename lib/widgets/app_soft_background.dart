import 'package:flutter/material.dart';

/// Subtle gradient background with soft color blobs.
///
/// Intended for use as the first child in a `Stack`.
class AppSoftBackground extends StatelessWidget {
  const AppSoftBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: const [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF6F8FE),
                    Color(0xFFF2F5FC),
                    Color(0xFFEEF2FA),
                  ],
                ),
              ),
            ),
            _SoftBlob(
              alignment: Alignment(-1.05, -0.65),
              size: 560,
              color: Color(0x336BCBFF),
            ),
            _SoftBlob(
              alignment: Alignment(1.05, -0.30),
              size: 500,
              color: Color(0x2626D0CE),
            ),
            _SoftBlob(
              alignment: Alignment(0.0, 1.15),
              size: 600,
              color: Color(0x1A1D4ED8),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _SoftBlob({
    required this.alignment,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}
