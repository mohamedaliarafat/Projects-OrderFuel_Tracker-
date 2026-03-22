import 'package:flutter/material.dart';

class ServiceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onTap != null;
    final hover = enabled && _hovered;

    final accent = _accentColor(widget.gradient) ?? theme.colorScheme.primary;

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.1,
      color: enabled ? const Color(0xFF0F172A) : theme.disabledColor,
    );

    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.25,
      color: enabled
          ? const Color(0xFF475569).withValues(alpha: 0.92)
          : theme.disabledColor.withValues(alpha: 0.75),
    );

    final surface = theme.colorScheme.surface;
    final background = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [surface, Color.lerp(surface, accent, hover ? 0.08 : 0.05)!],
    );

    final borderColor = hover
        ? accent.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: enabled ? 0.06 : 0.03);

    final shadowColor = Colors.black.withValues(alpha: hover ? 0.14 : 0.06);

    return AnimatedScale(
      scale: hover ? 1.01 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: hover ? 26 : 14,
              offset: Offset(0, hover ? 12 : 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: InkWell(
              onTap: enabled ? widget.onTap : null,
              onHover: enabled ? (v) => setState(() => _hovered = v) : null,
              splashColor: accent.withValues(alpha: 0.10),
              highlightColor: accent.withValues(alpha: 0.05),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: widget.gradient),
                    ),
                  ),
                  Positioned(
                    top: -54,
                    right: -64,
                    child: IgnorePointer(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: 0.18),
                              accent.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconBadge(
                          icon: widget.icon,
                          gradient: widget.gradient,
                          enabled: enabled,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.title,
                                style: titleStyle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.subtitle,
                                style: subtitleStyle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          color: enabled
                              ? const Color(0xFF64748B).withValues(alpha: 0.85)
                              : theme.disabledColor.withValues(alpha: 0.75),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color? _accentColor(Gradient gradient) {
    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.first;
    }
    if (gradient is RadialGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.first;
    }
    if (gradient is SweepGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.first;
    }
    return null;
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final bool enabled;

  const _IconBadge({
    required this.icon,
    required this.gradient,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
