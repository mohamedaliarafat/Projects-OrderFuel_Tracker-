import 'package:flutter/material.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationBell extends StatefulWidget {
  final VoidCallback onPressed;
  final Color? iconColor;
  final double iconSize;

  const NotificationBell({
    super.key,
    required this.onPressed,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -0.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -0.2, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.2, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  void _animateBell() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notificationProvider.unreadCount;

    // Listen for new notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (unreadCount > 0) {
        _animateBell();
      }
    });

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value,
              child: IconButton(
                onPressed: () {
                  widget.onPressed();
                  _animateBell();
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  color: widget.iconColor ?? Theme.of(context).iconTheme.color,
                  size: widget.iconSize,
                ),
                tooltip: 'الإشعارات',
              ),
            );
          },
        ),

        // Badge
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.errorRed,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
