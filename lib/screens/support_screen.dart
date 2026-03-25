import 'package:flutter/material.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/widgets/mo_assistant_overlay.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: MoAssistantOverlay(
            embedded: true,
            currentRouteName: AppRoutes.support,
          ),
        ),
      ),
    );
  }
}
