import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatWallpaperId { classic, mint, ocean, sand, midnight, graphite }

class ChatWallpaperSpec {
  final ChatWallpaperId id;
  final String label;
  final Gradient gradient;
  final Color patternColor;
  final double patternOpacity;
  final bool isDark;

  const ChatWallpaperSpec({
    required this.id,
    required this.label,
    required this.gradient,
    required this.patternColor,
    required this.patternOpacity,
    required this.isDark,
  });
}

class ChatWallpapers {
  static const List<ChatWallpaperSpec> all = [
    ChatWallpaperSpec(
      id: ChatWallpaperId.classic,
      label: 'كلاسيك',
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFF8FAFF), Color(0xFFF1F5F9)],
      ),
      patternColor: Color(0xFF0F172A),
      patternOpacity: 0.035,
      isDark: false,
    ),
    ChatWallpaperSpec(
      id: ChatWallpaperId.mint,
      label: 'نعناع',
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFF6FFFD), Color(0xFFE9FFFA)],
      ),
      patternColor: Color(0xFF0F766E),
      patternOpacity: 0.040,
      isDark: false,
    ),
    ChatWallpaperSpec(
      id: ChatWallpaperId.ocean,
      label: 'محيط',
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFF2F7FF), Color(0xFFE9F2FF)],
      ),
      patternColor: Color(0xFF1D4ED8),
      patternOpacity: 0.040,
      isDark: false,
    ),
    ChatWallpaperSpec(
      id: ChatWallpaperId.sand,
      label: 'رمل',
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFFFF7ED), Color(0xFFFFFBEB)],
      ),
      patternColor: Color(0xFFB45309),
      patternOpacity: 0.040,
      isDark: false,
    ),
    ChatWallpaperSpec(
      id: ChatWallpaperId.midnight,
      label: 'ليل',
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF0B1220), Color(0xFF0F172A)],
      ),
      patternColor: Color(0xFFFFFFFF),
      patternOpacity: 0.060,
      isDark: true,
    ),
    ChatWallpaperSpec(
      id: ChatWallpaperId.graphite,
      label: 'جرافيت',
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF0F172A), Color(0xFF111827)],
      ),
      patternColor: Color(0xFFFFFFFF),
      patternOpacity: 0.050,
      isDark: true,
    ),
  ];

  static ChatWallpaperSpec byId(ChatWallpaperId id) {
    for (final spec in all) {
      if (spec.id == id) return spec;
    }
    return all.first;
  }

  static ChatWallpaperId parseId(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final id in ChatWallpaperId.values) {
      if (id.name.toLowerCase() == normalized) return id;
    }
    return ChatWallpaperId.classic;
  }
}

class ChatWallpaperStore {
  static const String _storageKey = 'chat_wallpaper_id_v1';

  static Future<ChatWallpaperId> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ChatWallpapers.parseId(prefs.getString(_storageKey));
    } catch (_) {
      return ChatWallpaperId.classic;
    }
  }

  static Future<void> save(ChatWallpaperId id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, id.name);
    } catch (_) {}
  }
}

class ChatWallpaperBackground extends StatelessWidget {
  final ChatWallpaperSpec wallpaper;
  final Widget child;

  const ChatWallpaperBackground({
    super.key,
    required this.wallpaper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: wallpaper.gradient),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WallpaperPatternPainter(
                color: wallpaper.patternColor,
                opacity: wallpaper.patternOpacity,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class ChatWallpaperPreview extends StatelessWidget {
  final ChatWallpaperSpec wallpaper;
  final bool selected;

  const ChatWallpaperPreview({
    super.key,
    required this.wallpaper,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = selected
        ? Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.55),
            width: 2,
          )
        : Border.all(color: Colors.black.withValues(alpha: 0.08));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.14 : 0.07),
            blurRadius: selected ? 18 : 12,
            offset: Offset(0, selected ? 10 : 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: wallpaper.gradient),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WallpaperPatternPainter(
                    color: wallpaper.patternColor,
                    opacity: wallpaper.patternOpacity,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 10,
              end: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (wallpaper.isDark ? Colors.black : Colors.white)
                      .withValues(alpha: wallpaper.isDark ? 0.30 : 0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        wallpaper.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: wallpaper.isDark
                              ? Colors.white.withValues(alpha: 0.95)
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const _WallpaperPatternPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..color = color.withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: opacity * 0.70);

    const step = 56.0;
    final cols = (size.width / step).ceil() + 1;
    final rows = (size.height / step).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final seed = (col * 92837111) ^ (row * 689287499);
        final dx = math.sin(seed.toDouble()) * 10;
        final dy = math.cos(seed.toDouble()) * 10;
        final center = Offset(col * step + dx, row * step + dy);

        final radius = 9.0 + (seed & 7) * 0.9;
        canvas.drawCircle(center, radius, stroke);

        final arcRect = Rect.fromCircle(
          center: center.translate(0, -1),
          radius: radius * 0.65,
        );
        final start = ((seed % 360) * (math.pi / 180));
        canvas.drawArc(arcRect, start, math.pi / 1.7, false, stroke);

        canvas.drawCircle(center.translate(radius * 0.92, 0), 1.8, fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WallpaperPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}
